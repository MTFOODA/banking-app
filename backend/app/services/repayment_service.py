"""Credit-card repayment quotes and history."""

from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.banking import Account, Card
from app.models.enums import AccountStatus, CardKind, RepaymentMode
from app.models.transactions import Repayment
from app.models.user import User
from app.services.common import quantize_money

ZERO = Decimal("0.00")


def owned_card(db: Session, user: User, card_id: uuid.UUID) -> Card:
    card = db.scalar(select(Card).where(Card.id == card_id, Card.customer_id == user.id))
    if card is None:
        raise AppError(code="card_not_found", message="Card not found.", status_code=404)
    return card


def owned_account(db: Session, user: User, account_id: uuid.UUID) -> Account:
    account = db.scalar(
        select(Account).where(Account.id == account_id, Account.customer_id == user.id)
    )
    if account is None:
        raise AppError(code="account_not_found", message="Account not found.", status_code=404)
    return account


def resolve_amount(card: Card, mode: str, amount: Decimal | None) -> Decimal:
    if mode == RepaymentMode.FULL:
        return quantize_money(card.outstanding_balance or ZERO)
    if mode == RepaymentMode.STATEMENT:
        return quantize_money(card.statement_balance or ZERO)
    if mode == RepaymentMode.MINIMUM:
        return quantize_money(card.minimum_payment or ZERO)
    if amount is None:
        raise AppError(
            code="invalid_repayment_amount",
            message="Enter the amount you want to repay.",
            status_code=422,
        )
    return quantize_money(amount)


def quote(
    db: Session,
    user: User,
    *,
    card_id: uuid.UUID,
    funding_account_id: uuid.UUID,
    mode: str,
    amount: Decimal | None = None,
) -> dict:
    card = owned_card(db, user, card_id)
    account = owned_account(db, user, funding_account_id)

    if card.card_kind != CardKind.CREDIT:
        raise AppError(
            code="not_a_credit_card",
            message="Repayments are available for credit cards only.",
            status_code=422,
        )
    if mode not in {m.value for m in RepaymentMode}:
        raise AppError(
            code="invalid_repayment_mode", message="Unknown repayment option.", status_code=422
        )

    payable_amount = resolve_amount(card, mode, amount)
    outstanding = quantize_money(card.outstanding_balance or ZERO)
    charges = ZERO  # No charges are configured for the demo credit product.
    total_due = quantize_money(payable_amount + charges)

    reason: str | None = None
    if payable_amount <= 0:
        reason = "no_amount_due"
    elif payable_amount > outstanding:
        reason = "amount_exceeds_outstanding"
    elif account.status != AccountStatus.ACTIVE:
        reason = "funding_account_inactive"
    elif account.currency != "EGP":
        reason = "funding_currency_not_supported"
    elif account.available_balance < total_due:
        reason = "insufficient_funds"

    return {
        "card_id": card.id,
        "mode": mode,
        "amount": payable_amount,
        "statement_balance": quantize_money(card.statement_balance or ZERO),
        "outstanding_balance": outstanding,
        "minimum_payment": quantize_money(card.minimum_payment or ZERO),
        "available_credit": quantize_money(card.available_credit or ZERO),
        "charges": charges,
        "payable": total_due,
        "funding_account_id": account.id,
        "funding_available_balance": quantize_money(account.available_balance),
        "eligible": reason is None,
        "ineligibility_reason": reason,
    }


def list_repayments(
    db: Session, user: User, *, page: int, page_size: int
) -> tuple[list[Repayment], int]:
    stmt = select(Repayment).where(Repayment.customer_id == user.id)
    total = db.scalar(select(func.count(Repayment.id)).where(Repayment.customer_id == user.id))
    rows = db.scalars(
        stmt.order_by(Repayment.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()
    return list(rows), int(total or 0)


def get_repayment(db: Session, user: User, repayment_id: uuid.UUID) -> Repayment:
    repayment = db.scalar(
        select(Repayment).where(
            Repayment.id == repayment_id, Repayment.customer_id == user.id
        )
    )
    if repayment is None:
        raise AppError(
            code="repayment_not_found", message="Repayment not found.", status_code=404
        )
    return repayment
