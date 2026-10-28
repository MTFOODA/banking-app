"""Seed the fictional, isolated demo banking dataset (LOCAL/DEVELOPMENT ONLY).

Run after migrations:

    cd backend
    .venv\\Scripts\\python.exe ..\\database\\seed_demo_banking_data.py

The script only touches records it owns (deterministic UUIDs and the
``DEMO-C-*`` / ``555...`` / ``4000 0000 0000 01xx`` identifiers). It never
resets existing users or deletes unrelated data, and rerunning it is a no-op.
"""

from __future__ import annotations

import argparse
import sys
from collections import Counter
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
for extra in (REPO_ROOT / "backend", REPO_ROOT / "database"):
    if str(extra) not in sys.path:
        sys.path.insert(0, str(extra))

from sqlalchemy import delete, select  # noqa: E402
from sqlalchemy.orm import Session  # noqa: E402

from app.core.config import settings  # noqa: E402
from app.core.database import SessionLocal  # noqa: E402
from app.core.security import hash_identifier, hash_password  # noqa: E402
from app.models.banking import (  # noqa: E402
    Account,
    AccountProduct,
    Beneficiary,
    Card,
    CardLimit,
    CardProduct,
)
from app.models.service import Notification  # noqa: E402
from app.models.transactions import Repayment, Transaction, TransactionEntry  # noqa: E402
from app.models.user import (  # noqa: E402
    CustomerPreference,
    CustomerProfile,
    RefreshSession,
    User,
)
from demo_banking_data import (  # noqa: E402
    ACCOUNTS,
    ACTIVITY,
    BENEFICIARIES,
    CARDS,
    CUSTOMERS,
    NOTIFICATIONS,
    PAYMENTS,
    REPAYMENTS,
    TRANSFERS,
    demo_id,
    iban_for,
    masked_account,
    masked_pan,
    pan_last4,
)
from demo_products import seed_products  # noqa: E402

ZERO = Decimal("0.00")


def _money(value: str | Decimal) -> Decimal:
    return Decimal(str(value)).quantize(Decimal("0.01"))


def _as_datetime(value: str) -> date:
    return date.fromisoformat(value)


def _ensure_customer(
    db: Session, spec: dict, now: datetime
) -> tuple[User, bool]:
    user = db.get(User, demo_id(f"user:{spec['key']}"))
    if user is None:
        user = db.scalar(
            select(User).where(User.login_identifier_hash == hash_identifier(spec["pan"]))
        )
    created = False
    if user is None:
        user = User(
            id=demo_id(f"user:{spec['key']}"),
            login_identifier_hash=hash_identifier(spec["pan"]),
            login_identifier_masked=masked_pan(spec["pan"]),
            login_type="customer",
            password_hash=hash_password(spec["password"]),
            must_change_password=spec["must_change_password"],
            password_updated_at=None if spec["must_change_password"] else now,
            is_active=True,
            is_locked=False,
            failed_login_attempts=0,
        )
        db.add(user)
        db.flush()
        created = True

    profile = db.scalar(
        select(CustomerProfile).where(CustomerProfile.user_id == user.id)
    )
    if profile is None:
        db.add(
            CustomerProfile(
                id=demo_id(f"profile:{spec['key']}"),
                user_id=user.id,
                first_name_en=spec["first_en"],
                last_name_en=spec["last_en"],
                first_name_ar=spec["first_ar"],
                last_name_ar=spec["last_ar"],
                email=spec["email"],
                phone=spec["phone"],
                national_id_masked=spec["national_id"],
                date_of_birth=_as_datetime(spec["date_of_birth"]),
                address=spec["address"],
                customer_number=spec["customer_number"],
                segment=spec["segment"],
                identity_verified=True,
            )
        )
        db.flush()

    preferences = db.scalar(
        select(CustomerPreference).where(CustomerPreference.user_id == user.id)
    )
    if preferences is None:
        db.add(
            CustomerPreference(
                id=demo_id(f"preferences:{spec['key']}"),
                user_id=user.id,
                language="en",
                theme="system",
            )
        )
        db.flush()
    return user, created


def _ensure_account(
    db: Session, spec: dict, user: User, products: dict[str, AccountProduct], now: datetime
) -> tuple[Account, bool]:
    account = db.get(Account, demo_id(f"account:{spec['number']}"))
    if account is None:
        account = db.scalar(
            select(Account).where(
                Account.account_number_hash == hash_identifier(f"acct:{spec['number']}")
            )
        )
    if account is not None:
        return account, False
    product = products[spec["product"]]
    opening = _money(spec["opening"])
    blocked = _money(spec["blocked"])
    account = Account(
        id=demo_id(f"account:{spec['number']}"),
        customer_id=user.id,
        product_id=product.id,
        account_number_hash=hash_identifier(f"acct:{spec['number']}"),
        account_number_masked=masked_account(spec["number"]),
        iban=iban_for(spec["number"]),
        account_type=product.account_type,
        currency="EGP",
        status=spec["status"],
        current_balance=opening,
        available_balance=opening - blocked,
        blocked_balance=blocked,
        opened_at=now - timedelta(days=spec["opened_days"]),
    )

    db.add(account)
    db.flush()
    return account, True


def _ensure_card(
    db: Session,
    spec: dict,
    user: User,
    accounts: dict[str, Account],
    card_products: dict[str, CardProduct],
    now: datetime,
) -> tuple[Card, bool]:
    card = db.get(Card, demo_id(f"card:{spec['pan']}"))
    if card is None:
        card = db.scalar(
            select(Card).where(Card.card_number_hash == hash_identifier(spec["pan"]))
        )
    if card is not None:
        return card, False
    product = card_products[spec["product"]]
    account = accounts.get(spec["account"]) if spec.get("account") else None
    credit_limit = _money(spec["credit_limit"]) if spec.get("credit_limit") else None
    outstanding = _money(spec["credit_opening"]) if spec.get("credit_opening") else None
    card = Card(
        id=demo_id(f"card:{spec['pan']}"),
        customer_id=user.id,
        account_id=account.id if account else None,
        product_id=product.id,
        card_number_hash=hash_identifier(spec["pan"]),
        pan_token=f"tok_demo_{spec['pan']}",
        card_last4=pan_last4(spec["pan"]),
        cardholder_name=spec["holder"],
        card_kind=spec["kind"],
        network=product.network,
        expiry_month=(now.month % 12) + 1,
        expiry_year=now.year + 3,
        status=spec["status"],
        is_primary=True,
        is_supplementary=False,
        credit_limit=credit_limit,
        available_credit=(credit_limit - outstanding)
        if credit_limit is not None and outstanding is not None
        else None,
        outstanding_balance=outstanding,
        statement_balance=_money(spec["statement"]) if spec.get("statement") else None,
        minimum_payment=_money(spec["minimum"]) if spec.get("minimum") else None,
        payment_due_date=date.today() + timedelta(days=spec["due_days"])
        if spec.get("due_days")
        else None,
    )
    db.add(card)
    db.flush()
    db.add(
        CardLimit(
            card_id=card.id,
            daily_purchase_limit=Decimal("20000.00"),
            daily_atm_limit=Decimal("8000.00"),
            monthly_limit=Decimal("120000.00"),
            online_enabled=True,
            international_enabled=False,
            contactless_enabled=True,
        )
    )
    db.flush()
    return card, True


def _transaction_rows(now: datetime) -> list[dict]:
    rows: list[dict] = []
    for index, row in enumerate(ACTIVITY, start=1):
        (
            customer,
            account_number,
            pan,
            tx_type,
            direction,
            amount,
            description,
            description_ar,
            counterparty,
            merchant,
            days_ago,
            status,
        ) = row
        rows.append(
            dict(
                reference=f"DEMO-BNK-ACT-{index:03d}",
                customer=customer,
                account=account_number,
                pan=pan,
                journal=None,
                type=tx_type,
                direction=direction,
                amount=_money(amount),
                description=description,
                description_ar=description_ar,
                counterparty=counterparty,
                merchant=merchant,
                occurred_at=now - timedelta(days=days_ago, minutes=index),
                status=status,
            )
        )
    for index, row in enumerate(PAYMENTS, start=1):
        customer, account_number, biller_en, biller_ar, amount, days_ago, status = row
        rows.append(
            dict(
                reference=f"DEMO-BNK-PAY-{index:02d}",
                customer=customer,
                account=account_number,
                pan=None,
                journal=None,
                type="bill_payment",
                direction="debit",
                amount=_money(amount),
                description=f"Bill payment • {biller_en}",
                description_ar=f"سداد فاتورة • {biller_ar}",
                counterparty=biller_en,
                merchant=None,
                occurred_at=now - timedelta(days=days_ago, minutes=100 + index),
                status=status,
            )
        )
    rows.extend(_transfer_rows(now))
    rows.sort(key=lambda item: item["occurred_at"])
    return rows


def _transfer_rows(now: datetime) -> list[dict]:
    rows: list[dict] = []
    for index, row in enumerate(TRANSFERS, start=1):
        (
            from_customer,
            from_account,
            to_customer,
            to_account,
            amount,
            days_ago,
            purpose_en,
            purpose_ar,
        ) = row
        journal = demo_id(f"journal:transfer:{index}")
        occurred_at = now - timedelta(days=days_ago, minutes=200 + index)
        rows.append(
            dict(
                reference=f"DEMO-BNK-TRF-{index:02d}-OUT",
                customer=from_customer,
                account=from_account,
                pan=None,
                journal=journal,
                type="transfer",
                direction="debit",
                amount=_money(amount),
                description=f"Transfer • {purpose_en}",
                description_ar=f"تحويل • {purpose_ar}",
                counterparty=masked_account(to_account),
                merchant=None,
                occurred_at=occurred_at,
                status="posted",
            )
        )
        rows.append(
            dict(
                reference=f"DEMO-BNK-TRF-{index:02d}-IN",
                customer=to_customer,
                account=to_account,
                pan=None,
                journal=journal,
                type="transfer",
                direction="credit",
                amount=_money(amount),
                description=f"Transfer • {purpose_en}",
                description_ar=f"تحويل • {purpose_ar}",
                counterparty=masked_account(from_account),
                merchant=None,
                occurred_at=occurred_at,
                status="posted",
            )
        )
    return rows


def _ensure_transactions(
    db: Session,
    rows: list[dict],
    users: dict[str, User],
    accounts: dict[str, Account],
    cards: dict[str, Card],
) -> list[tuple[dict, Transaction]]:
    created: list[tuple[dict, Transaction]] = []
    for row in rows:
        exists = db.scalar(
            select(Transaction.id).where(Transaction.reference == row["reference"])
        )
        if exists is not None:
            continue
        account = accounts.get(row["account"]) if row["account"] else None
        card = cards.get(row["pan"]) if row["pan"] else None
        transaction = Transaction(
            id=demo_id(f"transaction:{row['reference']}"),
            customer_id=users[row["customer"]].id,
            account_id=account.id if account else None,
            card_id=card.id if card else None,
            journal_id=row["journal"] or demo_id(f"journal:{row['reference']}"),
            reference=row["reference"],
            transaction_type=row["type"],
            direction=row["direction"],
            amount=row["amount"],
            currency="EGP",
            description=row["description"],
            description_ar=row["description_ar"],
            counterparty=row["counterparty"],
            merchant=row["merchant"],
            status=row["status"],
            is_simulated=True,
            occurred_at=row["occurred_at"],
        )
        db.add(transaction)
        db.flush()
        db.add(
            TransactionEntry(
                transaction_id=transaction.id,
                account_id=account.id if account else None,
                entry_type=row["direction"],
                amount=row["amount"],
            )
        )
        created.append((row, transaction))
    db.flush()
    return created


def _apply_account_balances(
    accounts: dict[str, Account],
    created: list[tuple[dict, Transaction]],
    opening: dict[str, Decimal],
    blocked: dict[str, Decimal],
    new_numbers: set[str],
) -> None:
    """Derive balances from the seeded ledger for accounts created in this run."""
    if not new_numbers:
        return
    balances = {number: opening[number] for number in new_numbers}
    for row, transaction in sorted(created, key=lambda item: item[1].occurred_at):
        number = row["account"]
        if number not in new_numbers or row["status"] != "posted":
            continue
        delta = row["amount"] if row["direction"] == "credit" else -row["amount"]
        balances[number] = balances[number] + delta
        transaction.balance_after = balances[number]
    for number in new_numbers:
        account = accounts[number]
        account.current_balance = balances[number]
        account.available_balance = balances[number] - blocked[number]


def _apply_credit_balances(
    cards: dict[str, Card],
    created_specs: list[dict],
    created: list[tuple[dict, Transaction]],
) -> None:
    for spec in created_specs:
        if spec["kind"] != "credit":
            continue
        outstanding = _money(spec["credit_opening"])
        for row, _transaction in created:
            if row["pan"] != spec["pan"] or row["status"] != "posted":
                continue
            if row["account"] is not None:
                continue
            if row["type"] == "purchase" and row["direction"] == "debit":
                outstanding += row["amount"]
            elif row["type"] == "card_repayment" and row["direction"] == "credit":
                outstanding -= row["amount"]
        card = cards[spec["pan"]]
        card.outstanding_balance = outstanding
        card.available_credit = _money(spec["credit_limit"]) - outstanding
        card.statement_balance = _money(spec["statement"])
        card.minimum_payment = _money(spec["minimum"])


def _ensure_beneficiaries(
    db: Session, users: dict[str, User]
) -> int:
    created = 0
    for index, row in enumerate(BENEFICIARIES, start=1):
        customer, name, nickname, bank, masked, iban = row
        beneficiary_id = demo_id(f"beneficiary:{index}")
        if db.get(Beneficiary, beneficiary_id) is not None:
            continue
        db.add(
            Beneficiary(
                id=beneficiary_id,
                customer_id=users[customer].id,
                name=name,
                nickname=nickname,
                bank_name=bank,
                account_number_masked=masked,
                iban=iban,
                currency="EGP",
                status="active",
            )
        )
        created += 1
    db.flush()
    return created


def _ensure_notifications(
    db: Session,
    users: dict[str, User],
    transactions_by_customer: dict[str, str],
) -> int:
    created = 0
    for index, row in enumerate(NOTIFICATIONS, start=1):
        (
            customer,
            category,
            title_en,
            title_ar,
            body_en,
            body_ar,
            priority,
            route,
            related_type,
        ) = row
        notification_id = demo_id(f"notification:{index}")
        if db.get(Notification, notification_id) is not None:
            continue
        related_id = (
            transactions_by_customer.get(customer)
            if related_type == "transaction"
            else None
        )
        db.add(
            Notification(
                id=notification_id,
                customer_id=users[customer].id,
                category=category,
                title_en=title_en,
                title_ar=title_ar,
                body_en=body_en,
                body_ar=body_ar,
                priority=priority,
                related_entity_type=related_type,
                related_entity_id=related_id,
                cta_route=route,
            )
        )
        created += 1
    db.flush()
    return created


def _ensure_repayments(
    db: Session,
    users: dict[str, User],
    cards: dict[str, Card],
    accounts: dict[str, Account],
    now: datetime,
) -> int:
    created = 0
    for index, row in enumerate(REPAYMENTS, start=1):
        customer, pan, funding_account, amount, mode, status, days_ago = row
        reference = f"DEMO-BNK-RPY-{index:02d}"
        repayment_id = demo_id(f"repayment:{reference}")
        if db.get(Repayment, repayment_id) is not None:
            continue
        db.add(
            Repayment(
                id=repayment_id,
                customer_id=users[customer].id,
                card_id=cards[pan].id,
                funding_account_id=accounts[funding_account].id,
                amount=_money(amount),
                mode=mode,
                status=status,
                reference=reference,
                is_simulated=True,
                charges=ZERO,
                notes="Fictional demo repayment (LOCAL/DEVELOPMENT ONLY)",
                completed_at=(
                    now - timedelta(days=days_ago)
                    if status == "simulated_completed"
                    else None
                ),
            )
        )
        created += 1
    db.flush()
    return created


def seed_demo_banking(
    db: Session, *, now: datetime | None = None
) -> dict[str, int]:
    """Create or top up the isolated demo dataset. Safe to run repeatedly."""
    if settings.environment == "production":
        raise RuntimeError("Refusing to seed fictional demo data in production.")

    from app.services.bank_catalogue import seed_bank_catalogue
    seed_bank_catalogue(db)
    now = now or datetime.now(UTC)
    products = seed_products(db)  # idempotent catalogue, commits internally
    account_products = {
        product.code: product
        for product in db.scalars(select(AccountProduct)).all()
    }
    card_products = {
        product.code: product
        for product in db.scalars(select(CardProduct)).all()
    }
    del products

    counts: Counter[str] = Counter()
    try:
        users: dict[str, User] = {}
        for spec in CUSTOMERS:
            user, created = _ensure_customer(db, spec, now)
            users[spec["key"]] = user
            counts["customers_created"] += int(created)

        accounts: dict[str, Account] = {}
        new_account_numbers: set[str] = set()
        for spec in ACCOUNTS:
            account, created = _ensure_account(
                db, spec, users[spec["customer"]], account_products, now
            )
            accounts[spec["number"]] = account
            if created:
                new_account_numbers.add(spec["number"])
                counts["accounts_created"] += 1

        cards: dict[str, Card] = {}
        new_card_specs: list[dict] = []
        for spec in CARDS:
            card, created = _ensure_card(
                db, spec, users[spec["customer"]], accounts, card_products, now
            )
            cards[spec["pan"]] = card
            if created:
                new_card_specs.append(spec)
                counts["cards_created"] += 1

        rows = _transaction_rows(now)
        created_rows = _ensure_transactions(db, rows, users, accounts, cards)
        counts["transactions_created"] += len(created_rows)

        _apply_account_balances(
            accounts,
            created_rows,
            {spec["number"]: _money(spec["opening"]) for spec in ACCOUNTS},
            {spec["number"]: _money(spec["blocked"]) for spec in ACCOUNTS},
            new_account_numbers,
        )
        _apply_credit_balances(cards, new_card_specs, created_rows)

        counts["beneficiaries_created"] += _ensure_beneficiaries(db, users)
        transactions_by_customer: dict[str, str] = {}
        for row, transaction in created_rows:
            transactions_by_customer.setdefault(row["customer"], transaction.reference)
        counts["notifications_created"] += _ensure_notifications(
            db, users, transactions_by_customer
        )
        counts["repayments_created"] += _ensure_repayments(
            db, users, cards, accounts, now
        )

        db.commit()
    except Exception:
        db.rollback()
        raise

    return dict(counts)


def reset_demo_dataset(db: Session) -> dict[str, int]:
    """Delete only the records owned by this demo dataset.

    Existing demo users from `database/seed_demo.py` are not touched, and no
    table outside the dataset's identifiers is cleared.
    """
    user_ids = set(
        db.scalars(
            select(User.id).where(
                User.login_identifier_hash.in_(
                    [hash_identifier(spec["pan"]) for spec in CUSTOMERS]
                )
            )
        ).all()
    )
    account_ids = set(
        db.scalars(
            select(Account.id).where(
                Account.account_number_hash.in_(
                    [hash_identifier(f"acct:{spec['number']}") for spec in ACCOUNTS]
                )
            )
        ).all()
    )
    card_ids = set(
        db.scalars(
            select(Card.id).where(
                Card.card_number_hash.in_(
                    [hash_identifier(spec["pan"]) for spec in CARDS]
                )
            )
        ).all()
    )
    transaction_ids = set(
        db.scalars(
            select(Transaction.id).where(Transaction.reference.like("DEMO-BNK-%"))
        ).all()
    )
    notification_ids = [
        demo_id(f"notification:{index}") for index in range(1, len(NOTIFICATIONS) + 1)
    ]
    beneficiary_ids = [
        demo_id(f"beneficiary:{index}") for index in range(1, len(BENEFICIARIES) + 1)
    ]
    repayment_ids = [
        demo_id(f"repayment:DEMO-BNK-RPY-{index:02d}")
        for index in range(1, len(REPAYMENTS) + 1)
    ]

    removed: dict[str, int] = {}
    try:
        if transaction_ids:
            removed["transaction_entries"] = db.execute(
                delete(TransactionEntry).where(
                    TransactionEntry.transaction_id.in_(transaction_ids)
                )
            ).rowcount
            removed["transactions"] = db.execute(
                delete(Transaction).where(Transaction.id.in_(transaction_ids))
            ).rowcount
        removed["repayments"] = db.execute(
            delete(Repayment).where(Repayment.id.in_(repayment_ids))
        ).rowcount
        removed["notifications"] = db.execute(
            delete(Notification).where(Notification.id.in_(notification_ids))
        ).rowcount
        removed["beneficiaries"] = db.execute(
            delete(Beneficiary).where(Beneficiary.id.in_(beneficiary_ids))
        ).rowcount
        if card_ids:
            db.execute(delete(CardLimit).where(CardLimit.card_id.in_(card_ids)))
            removed["cards"] = db.execute(
                delete(Card).where(Card.id.in_(card_ids))
            ).rowcount
        if account_ids:
            removed["accounts"] = db.execute(
                delete(Account).where(Account.id.in_(account_ids))
            ).rowcount
        if user_ids:
            db.execute(
                delete(CustomerPreference).where(
                    CustomerPreference.user_id.in_(user_ids)
                )
            )
            db.execute(
                delete(CustomerProfile).where(CustomerProfile.user_id.in_(user_ids))
            )
            db.execute(
                delete(RefreshSession).where(RefreshSession.user_id.in_(user_ids))
            )
            removed["customers"] = db.execute(
                delete(User).where(User.id.in_(user_ids))
            ).rowcount
        db.commit()
    except Exception:
        db.rollback()
        raise
    return removed


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Seed the fictional Faisal App demo banking dataset"
    )
    parser.add_argument(
        "--reset",
        action="store_true",
        help="Delete only this dataset's records before seeding (requires --yes)",
    )
    parser.add_argument("--yes", action="store_true", help="Confirm the reset")
    args = parser.parse_args(argv)

    with SessionLocal() as db:
        if args.reset:
            if not args.yes:
                print("Refusing to reset the demo dataset without --yes.")
                return 2
            removed = reset_demo_dataset(db)
            print("Removed demo-owned records:")
            for key, value in removed.items():
                print(f"  {key}: {value}")

        summary = seed_demo_banking(db)

    print("Demo banking dataset ready (records created this run):")
    for key, value in summary.items():
        print(f"  {key}: {value}")
    print("\nCredential reference: backend/DEMO_CREDENTIALS.md")
    print("LOCAL/DEVELOPMENT ONLY — never use these credentials in production.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
