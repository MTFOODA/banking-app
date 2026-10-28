"""Demo dataset idempotency and rollback tests."""

from __future__ import annotations

import pytest
from sqlalchemy import func, select

import seed_demo_banking_data as seed_module
from app.core.security import hash_identifier, verify_password
from app.models.banking import Account, Beneficiary, Card
from app.models.service import Notification
from app.models.transactions import Repayment, Transaction
from app.models.user import CustomerProfile, User
from demo_banking_data import (
    ACCOUNTS,
    BENEFICIARIES,
    CARDS,
    CUSTOMERS,
    NOTIFICATIONS,
    REPAYMENTS,
    demo_id,
)
from seed_demo_banking_data import seed_demo_banking


def _counts(db) -> dict[str, int]:
    return {
        "customers": db.scalar(
            select(func.count())
            .select_from(CustomerProfile)
            .where(CustomerProfile.customer_number.like("DEMO-C-%"))
        ),
        "accounts": db.scalar(
            select(func.count())
            .select_from(Account)
            .where(
                Account.account_number_hash.in_(
                    [hash_identifier(f"acct:{spec['number']}") for spec in ACCOUNTS]
                )
            )
        ),
        "cards": db.scalar(
            select(func.count())
            .select_from(Card)
            .where(
                Card.card_number_hash.in_(
                    [hash_identifier(spec["pan"]) for spec in CARDS]
                )
            )
        ),
        "transactions": db.scalar(
            select(func.count())
            .select_from(Transaction)
            .where(Transaction.reference.like("DEMO-BNK-%"))
        ),
        "beneficiaries": db.scalar(
            select(func.count())
            .select_from(Beneficiary)
            .where(
                Beneficiary.id.in_(
                    [demo_id(f"beneficiary:{index}") for index in range(1, len(BENEFICIARIES) + 1)]
                )
            )
        ),
        "notifications": db.scalar(
            select(func.count())
            .select_from(Notification)
            .where(
                Notification.id.in_(
                    [demo_id(f"notification:{index}") for index in range(1, len(NOTIFICATIONS) + 1)]
                )
            )
        ),
        "repayments": db.scalar(
            select(func.count())
            .select_from(Repayment)
            .where(Repayment.reference.like("DEMO-BNK-RPY-%"))
        ),
    }


def test_second_run_creates_no_duplicates(db_session):
    before = _counts(db_session)
    assert before == {
        "customers": len(CUSTOMERS),
        "accounts": len(ACCOUNTS),
        "cards": len(CARDS),
        "transactions": 68,
        "beneficiaries": len(BENEFICIARIES),
        "notifications": len(NOTIFICATIONS),
        "repayments": len(REPAYMENTS),
    }

    summary = seed_demo_banking(db_session)
    after = _counts(db_session)

    assert after == before
    assert all(value == 0 for value in summary.values()), summary


def test_reseed_does_not_reset_existing_passwords(db_session):
    youssef = db_session.scalar(
        select(User).where(
            User.login_identifier_hash == hash_identifier(CUSTOMERS[0]["pan"])
        )
    )
    original_hash = youssef.password_hash
    seed_demo_banking(db_session)
    db_session.refresh(youssef)
    assert youssef.password_hash == original_hash
    assert verify_password(CUSTOMERS[0]["password"], youssef.password_hash)
    assert youssef.must_change_password is False


def test_seed_failure_rolls_back_cleanly(db_session, monkeypatch):
    before = _counts(db_session)

    def boom(*args, **kwargs):
        raise RuntimeError("simulated seeding failure")

    monkeypatch.setattr(seed_module, "_ensure_repayments", boom)
    with pytest.raises(RuntimeError, match="simulated seeding failure"):
        seed_demo_banking(db_session)

    assert _counts(db_session) == before
