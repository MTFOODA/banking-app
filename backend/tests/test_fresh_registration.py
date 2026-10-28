import pytest
from sqlalchemy import select, func
from app.core.config import settings
from app.core.security import hash_password
from app.models.user import User, CustomerProfile
from app.models.banking import Account
from app.models.transactions import Transaction, TransactionEntry
from app.services import registration_demo


def test_fresh_batch_balanced_idempotent_and_preserves_enrolled_credentials(db_session):
    rows = registration_demo.provision_registration_batch(db_session, 'freshbatch', 2)
    assert len(rows) == 2 and all(not row['enrollment_completed'] for row in rows)
    from uuid import UUID
    user = db_session.get(User, UUID(rows[0]['id']))
    assert user.username is None and user.must_change_password
    for row in rows:
        accounts = db_session.scalars(select(Account).where(Account.customer_id == UUID(row['id']))).all()
        assert len(accounts) == 2 and all(a.available_balance == 500 for a in accounts)
        movements = db_session.scalars(select(Transaction).where(Transaction.customer_id == UUID(row['id']))).all()
        assert len(movements) == 2
        for movement in movements:
            entries = db_session.scalars(select(TransactionEntry).where(TransactionEntry.transaction_id == movement.id)).all()
            assert len(entries) == 2 and sum(e.amount if e.entry_type == 'debit' else -e.amount for e in entries) == 0
    user.enrollment_completed = True
    user.must_change_password = False
    user.password_hash = hash_password('Fictional#Completed26')
    db_session.flush()
    password_hash = user.password_hash
    assert registration_demo.provision_registration_batch(db_session, 'freshbatch', 2)[0]['enrollment_completed'] is True
    db_session.refresh(user)
    assert user.password_hash == password_hash and not user.must_change_password


def test_registration_batch_failure_rolls_back_all_new_customers(db_session, monkeypatch):
    original = registration_demo.seed_registration_demo
    def fail_second(db, **kwargs):
        if kwargs['customer_number'].endswith('-2'):
            raise RuntimeError('Injected batch failure')
        return original(db, **kwargs)
    monkeypatch.setattr(registration_demo, 'seed_registration_demo', fail_second)
    count = db_session.scalar(select(func.count()).select_from(User))
    with pytest.raises(RuntimeError, match='Injected batch failure'):
        with db_session.begin_nested():
            registration_demo.provision_registration_batch(db_session, 'rollbackbatch', 2)
    assert db_session.scalar(select(func.count()).select_from(User)) == count
    assert not db_session.scalar(select(CustomerProfile.id).where(CustomerProfile.customer_number.like('SELF-REG-rollbackbatch-%')))


def test_registration_batch_rejects_production(db_session, monkeypatch):
    monkeypatch.setattr(settings, 'environment', 'production')
    with pytest.raises(RuntimeError, match='development/test'):
        registration_demo.provision_registration_batch(db_session, 'blocked', 2)
