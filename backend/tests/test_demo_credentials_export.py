"""Local export lists every identity without resetting or fabricating passwords."""
import importlib.util
from pathlib import Path

import pytest
from sqlalchemy import select
from app.core.config import settings
from app.models.user import User

spec = importlib.util.spec_from_file_location('demo_credentials_export',
    Path(__file__).resolve().parents[2] / 'admin/export_demo_credentials.py')
exporter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(exporter)


def test_export_is_minimal_complete_repeatable_and_preserves_users(db_session, tmp_path):
    destination = tmp_path / 'admin.txt'
    users = db_session.scalars(select(User)).all()
    before = {u.id: (u.password_hash, u.username, u.enrollment_completed, u.must_change_password) for u in users}
    assert exporter.export_credentials(db_session, destination) == len(users)
    text = destination.read_text(encoding='utf-8')
    assert text.count('Username:') == len(users)
    assert text.count('OTP:') == 1
    fields = {line.split(':', 1)[0] for line in text.splitlines() if line}
    assert fields == {'Username', 'Card', 'Password', 'Accounts', 'Certificates', 'Funds', 'OTP'}
    exporter.export_credentials(db_session, destination)
    assert destination.read_text(encoding='utf-8') == text
    db_session.expire_all()
    assert {u.id: (u.password_hash, u.username, u.enrollment_completed, u.must_change_password)
            for u in db_session.scalars(select(User))} == before


def test_export_refuses_production(db_session, tmp_path, monkeypatch):
    monkeypatch.setattr(settings, 'environment', 'production')
    with pytest.raises(RuntimeError):
        exporter.export_credentials(db_session, tmp_path / 'admin.txt')
    assert not list(tmp_path.iterdir())
