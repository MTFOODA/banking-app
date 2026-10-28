"""Local username backfill and funded investor fixtures stay repeatable and atomic."""
import pytest
from sqlalchemy import select, func
from app.models.user import User
from app.models.investment import InvestmentHolding
from app.models.transactions import TransactionEntry
from app.core.config import settings
from app.core.database import engine
from app.services import development_customers as service

PASSWORDS = {'0910': 'Fictional#Investor0910', '0911': 'Fictional#Investor0911'}


def test_backfill_preserves_credentials_and_unenrolled_customers(db_session):
    users = db_session.scalars(select(User).order_by(User.id)).all()
    unregistered = users[0]
    unregistered.enrollment_completed = False
    db_session.commit()
    before = {u.id: (u.password_hash, u.must_change_password, u.login_identifier_hash, u.role_codes) for u in users}
    changed = service.assign_enrolled_usernames(db_session)
    db_session.commit()
    assert changed == len(users) - 1
    assert unregistered.username is None
    for u in users[1:]:
        assert u.username and service.username_service.available(db_session, u.username) is False
        assert (u.password_hash, u.must_change_password, u.login_identifier_hash, u.role_codes) == before[u.id]
    assert service.assign_enrolled_usernames(db_session) == 0


def test_investor_fixtures_have_balanced_holdings_and_repeat_without_debit(db_session):
    first = service._seed_investors(db_session, PASSWORDS)
    balances = {r['suffix']: db_session.scalar(select(service.Account.available_balance).where(
        service.Account.account_number_hash == service.hash_identifier('acct:' + r['account']))) for r in first}
    assert balances == {'0910': 38000, '0911': 47000}
    assert db_session.scalar(select(func.count()).select_from(InvestmentHolding)) == 6
    assert service._seed_investors(db_session, PASSWORDS) == first
    for row in first:
        account = db_session.scalar(select(service.Account).where(
            service.Account.account_number_hash == service.hash_identifier('acct:' + row['account'])))
        assert account.available_balance == balances[row['suffix']]
        assert db_session.scalar(select(func.count()).select_from(InvestmentHolding).where(
            InvestmentHolding.customer_id == account.customer_id)) == 3
    totals = db_session.execute(select(TransactionEntry.transaction_id, TransactionEntry.entry_type,
        func.sum(TransactionEntry.amount)).where(TransactionEntry.ledger_bucket.is_not(None))
        .group_by(TransactionEntry.transaction_id, TransactionEntry.entry_type)).all()
    grouped = {}
    for tx, direction, amount in totals:
        grouped.setdefault(tx, {})[direction] = amount
    assert len(grouped) == 8 and all(e['debit'] == e['credit'] for e in grouped.values())


def test_fixture_wrapper_rolls_back_every_service_commit_on_failure(seeded_dataset, monkeypatch):
    def fail(*args, **kwargs):
        raise RuntimeError('injected subscription failure')
    monkeypatch.setattr(service.investment_service, 'execute', fail)
    with pytest.raises(RuntimeError):
        service.provision_investor_fixtures(engine, PASSWORDS)
    with service.Session(engine) as db:
        assert db.scalar(select(func.count()).select_from(User).where(
            User.login_identifier_hash.in_([service.hash_identifier('4000000000000910'), service.hash_identifier('4000000000000911')])) ) == 0


def test_fixtures_refuse_production(db_session, monkeypatch):
    monkeypatch.setattr(settings, 'environment', 'production')
    with pytest.raises(RuntimeError):
        service.assign_enrolled_usernames(db_session)
    with pytest.raises(RuntimeError):
        service.normalize_existing_usernames(db_session)


def test_normalize_usernames_preserves_credentials_and_is_idempotent(db_session):
    users = db_session.scalars(select(User).order_by(User.id)).all()
    users[0].username, users[0].username_key = 'alex', service.username_service.username_key('alex')
    users[1].username, users[1].username_key = 'a.lex', None
    users[2].username, users[2].username_key = 'new_user', service.username_service.username_key('new_user')
    users[3].enrollment_completed = False
    db_session.commit()
    before = {u.id: (u.password_hash, u.must_change_password, u.login_identifier_hash, u.role_codes) for u in users}
    changes = service.normalize_existing_usernames(db_session)
    db_session.commit()
    assert len(changes) == 2
    assert users[0].username == 'alex'
    assert users[1].username == 'alex1'
    assert users[2].username == 'newuser'
    assert users[3].username is None
    assert all((u.password_hash, u.must_change_password, u.login_identifier_hash, u.role_codes) == before[u.id] for u in users)
    assert service.normalize_existing_usernames(db_session) == []


def test_normalize_usernames_caller_can_roll_back(db_session):
    user = db_session.scalar(select(User).order_by(User.id))
    user.username = 'rollback.user'
    user.username_key = service.username_service.username_key(user.username)
    db_session.commit()
    service.normalize_existing_usernames(db_session)
    assert user.username == 'rollbackuser'
    db_session.rollback()
    db_session.refresh(user)
    assert user.username == 'rollback.user'
