"""Isolated test database fixtures.

The suite **never** touches development or persistent handset fixtures.
DATABASE_URL is rewritten to CI_TEST_DATABASE_URL (must end in _ci_test), or a
separate name derived from TEST_DATABASE_URL, before engine initialization.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pytest

BACKEND_DIR = Path(__file__).resolve().parents[1]
REPO_ROOT = BACKEND_DIR.parent
for extra in (str(BACKEND_DIR), str(REPO_ROOT / "database")):
    if extra not in sys.path:
        sys.path.insert(0, extra)

from app.core.config import settings  # noqa: E402
from sqlalchemy.engine import make_url

# Keep the handset's persistent demo/credentials database intact. Destructive
# test-schema cleanup runs only in a separate CI database on the same server.
_phone_url = make_url(settings.test_database_url)
if not (_phone_url.database or '').endswith('_test'):
    raise RuntimeError('Automated tests require an isolated *_test database configuration')
settings.test_database_url = os.environ.get('CI_TEST_DATABASE_URL') or _phone_url.set(
    database=_phone_url.database.removesuffix('_test') + '_feature_ci_test'
).render_as_string(hide_password=False)
if not (make_url(settings.test_database_url).database or '').endswith('_ci_test'):
    raise RuntimeError('Automated cleanup requires a dedicated *_ci_test database')

settings.database_url = settings.test_database_url
os.environ["DATABASE_URL"] = settings.test_database_url

from sqlalchemy.orm import Session  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

import app.models  # noqa: E402,F401  (registers every table on Base.metadata)
from app.core.database import Base, engine, get_db  # noqa: E402
from app.services.rate_limit import reset_rate_limits  # noqa: E402

if not (engine.url.database or "").endswith("_test"):
    raise RuntimeError(
        f"Refusing to run tests against {engine.url.database!r}; expected a *_test database."
    )


@pytest.fixture(scope="session", autouse=True)
def test_schema():
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    yield
    Base.metadata.drop_all(engine)


@pytest.fixture(scope="session")
def seeded_dataset(test_schema):
    from seed_demo_banking_data import seed_demo_banking

    with Session(engine) as session:
        summary = seed_demo_banking(session)
    assert summary["customers_created"] == 6
    yield


@pytest.fixture()
def db_session(seeded_dataset):
    """A session inside a rolled-back outer transaction per test."""
    connection = engine.connect()
    transaction = connection.begin()
    session = Session(
        bind=connection,
        join_transaction_mode="create_savepoint",
        expire_on_commit=False,
    )
    try:
        yield session
    finally:
        session.close()
        transaction.rollback()
        connection.close()


@pytest.fixture()
def client(db_session):
    from app.main import app

    def _override_get_db():
        try:
            yield db_session
        except Exception:
            db_session.rollback()
            raise

    app.dependency_overrides[get_db] = _override_get_db
    reset_rate_limits()
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
