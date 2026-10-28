"""Transaction history queries with server-side filtering and scoping."""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, time
from decimal import Decimal

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.banking import Account, Card
from app.models.enums import TransactionDirection, TransactionStatus, TransactionType
from app.models.transactions import CreditCardStatement, Transaction
from app.models.user import User
from app.schemas.transaction import TransactionDetailResponse, TransactionResponse


def _scope_account(db: Session, user: User, account_id: uuid.UUID) -> Account:
    account = db.scalar(
        select(Account).where(Account.id == account_id, Account.customer_id == user.id)
    )
    if account is None:
        raise AppError(code="account_not_found", message="Account not found.", status_code=404)
    return account


def _scope_card(db: Session, user: User, card_id: uuid.UUID) -> Card:
    card = db.scalar(select(Card).where(Card.id == card_id, Card.customer_id == user.id))
    if card is None:
        raise AppError(code="card_not_found", message="Card not found.", status_code=404)
    return card


def list_transactions(
    db: Session,
    user: User,
    *,
    account_id: uuid.UUID | None = None,
    card_id: uuid.UUID | None = None,
    transaction_type: str | None = None,
    direction: str | None = None,
    status: str | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
    min_amount: Decimal | None = None,
    max_amount: Decimal | None = None,
    search: str | None = None,
    page: int = 1,
    page_size: int = 20,
) -> tuple[list[TransactionResponse], int]:
    if account_id is not None:
        _scope_account(db, user, account_id)
    if card_id is not None:
        _scope_card(db, user, card_id)

    conditions = [Transaction.customer_id == user.id]
    if account_id is not None:
        conditions.append(Transaction.account_id == account_id)
    if card_id is not None:
        conditions.append(Transaction.card_id == card_id)
    if transaction_type:
        conditions.append(Transaction.transaction_type == transaction_type)
    if direction:
        conditions.append(Transaction.direction == direction)
    if status:
        conditions.append(Transaction.status == status)
    if date_from:
        conditions.append(
            Transaction.occurred_at >= datetime.combine(date_from, time.min, tzinfo=UTC)
        )
    if date_to:
        conditions.append(
            Transaction.occurred_at <= datetime.combine(date_to, time.max, tzinfo=UTC)
        )
    if min_amount is not None:
        conditions.append(Transaction.amount >= min_amount)
    if max_amount is not None:
        conditions.append(Transaction.amount <= max_amount)
    if search:
        pattern = f"%{search.strip()}%"
        conditions.append(
            or_(
                Transaction.description.ilike(pattern),
                Transaction.description_ar.ilike(pattern),
                Transaction.reference.ilike(pattern),
                Transaction.counterparty.ilike(pattern),
                Transaction.merchant.ilike(pattern),
            )
        )

    total = db.scalar(select(func.count(Transaction.id)).where(*conditions)) or 0
    rows = db.execute(
        select(Transaction, Account, Card)
        .outerjoin(Account, Transaction.account_id == Account.id)
        .outerjoin(Card, Transaction.card_id == Card.id)
        .where(*conditions)
        .order_by(Transaction.occurred_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()

    items = [
        TransactionResponse.from_model(transaction, account=account, card=card)
        for transaction, account, card in rows
    ]
    return items, int(total)


def get_transaction(db: Session, user: User, transaction_id: uuid.UUID) -> TransactionDetailResponse:
    row = db.execute(
        select(Transaction, Account, Card)
        .outerjoin(Account, Transaction.account_id == Account.id)
        .outerjoin(Card, Transaction.card_id == Card.id)
        .where(Transaction.id == transaction_id, Transaction.customer_id == user.id)
    ).first()
    if row is None:
        raise AppError(
            code="transaction_not_found", message="Transaction not found.", status_code=404
        )
    transaction, account, card = row
    base = TransactionResponse.from_model(transaction, account=account, card=card)
    return TransactionDetailResponse(
        **base.model_dump(),
        fees=Decimal("0.00"),
        source_label=account.account_number_masked if account else (card.card_last4 if card else None),
        destination_label=transaction.counterparty,
        receipt_available=transaction.status == TransactionStatus.POSTED,
    )


def recent_for_customer(db: Session, user: User, limit: int = 5) -> list[TransactionResponse]:
    items, _ = list_transactions(db, user, page=1, page_size=limit)
    return items


def filter_options() -> dict:
    return {
        "types": [item.value for item in TransactionType],
        "statuses": [item.value for item in TransactionStatus],
        "directions": [item.value for item in TransactionDirection],
    }


def statements(db: Session, user: User, card_id: uuid.UUID) -> list[CreditCardStatement]:
    card = _scope_card(db, user, card_id)
    return list(
        db.scalars(
            select(CreditCardStatement)
            .where(CreditCardStatement.card_id == card.id)
            .order_by(CreditCardStatement.period_end.desc())
        ).all()
    )
