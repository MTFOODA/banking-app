"""Account queries and customer-scoped access checks."""

from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.banking import Account, AccountProduct, Card
from app.models.enums import AccountStatus
from app.models.user import User
from app.schemas.account import (
    AccountDetailResponse,
    AccountSummaryResponse,
    AccountTotalsResponse,
    LinkedCardSummary,
)


def list_accounts(db: Session, user: User, *, include_closed: bool = False) -> list[Account]:
    stmt = select(Account).where(Account.customer_id == user.id)
    if not include_closed:
        stmt = stmt.where(Account.status != AccountStatus.CLOSED)
    stmt = stmt.order_by(Account.opened_at.asc())
    return list(db.scalars(stmt).all())


def get_account(db: Session, user: User, account_id: uuid.UUID) -> Account:
    account = db.scalar(
        select(Account).where(Account.id == account_id, Account.customer_id == user.id)
    )
    if account is None:
        # 404 (not 403) so callers cannot probe for account existence.
        raise AppError(code="account_not_found", message="Account not found.", status_code=404)
    return account


def totals(accounts: list[Account]) -> AccountTotalsResponse:
    eligible = [a for a in accounts if a.status == AccountStatus.ACTIVE]
    available = sum((a.available_balance for a in eligible), Decimal("0.00"))
    current = sum((a.current_balance for a in eligible), Decimal("0.00"))
    return AccountTotalsResponse(
        total_available=available,
        total_current=current,
        currency=eligible[0].currency if eligible else "EGP",
        eligible_accounts=len(eligible),
    )


def detail(db: Session, user: User, account_id: uuid.UUID) -> AccountDetailResponse:
    account = get_account(db, user, account_id)
    cards = db.scalars(
        select(Card).where(Card.account_id == account.id, Card.customer_id == user.id)
    ).all()
    summary = AccountSummaryResponse.from_model(account)
    services = ["statement", "transactions"]
    if account.status == AccountStatus.ACTIVE:
        services.append("close_request")
    return AccountDetailResponse(
        **summary.model_dump(),
        linked_cards=[
            LinkedCardSummary(
                id=card.id,
                card_last4=card.card_last4,
                card_kind=card.card_kind,
                status=card.status,
                network=card.network,
            )
            for card in cards
        ],
        services=services,
    )


def list_products(db: Session) -> list[AccountProduct]:
    return list(
        db.scalars(
            select(AccountProduct)
            .where(AccountProduct.is_active.is_(True))
            .order_by(AccountProduct.name_en)
        ).all()
    )


def get_product_by_code(db: Session, code: str) -> AccountProduct:
    product = db.scalar(select(AccountProduct).where(AccountProduct.code == code))
    if product is None:
        raise AppError(code="product_not_found", message="Account product not found.", status_code=404)
    return product
