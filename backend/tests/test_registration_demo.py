import pytest
from sqlalchemy import select

from app.core.security import hash_identifier
from app.models.user import User
from app.services.registration_demo import CARD, seed_registration_demo


def test_registration_fixture_is_idempotent_and_preserves_credentials(db_session):
    assert seed_registration_demo(db_session) is True
    user = db_session.scalar(select(User).where(User.login_identifier_hash == hash_identifier(CARD)))
    original = user.password_hash
    user.enrollment_completed = True
    db_session.commit()
    assert seed_registration_demo(db_session) is False
    db_session.refresh(user)
    assert user.password_hash == original
    assert user.enrollment_completed is True


def test_registration_fixture_rolls_back_on_failure(db_session, monkeypatch):
    original_commit = db_session.commit
    def fail(): raise RuntimeError("Injected fixture failure")
    monkeypatch.setattr(db_session, "commit", fail)
    with pytest.raises(RuntimeError, match="Injected fixture failure"):
        seed_registration_demo(db_session)
    assert db_session.scalar(select(User).where(User.login_identifier_hash == hash_identifier(CARD))) is None
