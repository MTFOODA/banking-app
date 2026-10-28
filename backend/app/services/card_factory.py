"""Factories for demo accounts and cards (no PAN or PIN is ever stored)."""

from __future__ import annotations

import random
import uuid
from datetime import UTC, datetime
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import hash_identifier
from app.models.banking import Account, Card, CardLimit, CardProduct
from app.models.enums import CardStatus, RequestStatus


def new_account_number(db: Session) -> tuple[str, str, str]:
    """Return (hashed_number, masked_number, iban) for a fresh demo account."""
    for _ in range(20):
        digits = "".join(str(random.randint(0, 9)) for _ in range(14))
        masked = f"**** **** {digits[-4:]}"
        hashed = hash_identifier(f"acct:{digits}")
        if db.scalar(select(Account.id).where(Account.account_number_hash == hashed)):
            continue
        iban = "EG38" + "0019" + "0005" + "".join(str(random.randint(0, 9)) for _ in range(17))
        return hashed, masked, iban
    raise RuntimeError("Unable to allocate a unique demo account number")


def first_card_product(db: Session, code: str | None = None) -> CardProduct:
    stmt = select(CardProduct).where(CardProduct.is_active.is_(True))
    if code:
        stmt = stmt.where(CardProduct.code == code)
    product = db.scalar(stmt.order_by(CardProduct.code))
    if product is None:
        raise RuntimeError("No active card product is configured for this demo")
    return product


def new_card(
    db: Session,
    *,
    customer_id: uuid.UUID,
    account_id: uuid.UUID | None,
    product: CardProduct,
    holder_name: str,
    is_primary: bool,
    is_supplementary: bool,
    credit_limit: Decimal | None = None,
    status: str = CardStatus.PENDING_ACTIVATION,
    last4: str | None = None,
) -> Card:
    card_last4 = last4 or f"{random.randint(0, 9999):04d}"
    pan = f"4508{random.randint(0, 999999999999):012d}"
    now = datetime.now(UTC)
    card = Card(
        customer_id=customer_id,
        account_id=account_id,
        product_id=product.id,
        card_number_hash=hash_identifier(f"pan:{pan}:{uuid.uuid4()}"),
        pan_token=f"tok_{uuid.uuid4().hex}",
        card_last4=card_last4,
        cardholder_name=holder_name.upper(),
        card_kind=product.card_kind,
        network=product.network,
        expiry_month=now.month,
        expiry_year=now.year + 3,
        status=status,
        is_primary=is_primary,
        is_supplementary=is_supplementary,
        credit_limit=credit_limit,
        available_credit=credit_limit,
        outstanding_balance=Decimal("0.00") if credit_limit is not None else None,
        statement_balance=Decimal("0.00") if credit_limit is not None else None,
        minimum_payment=Decimal("0.00") if credit_limit is not None else None,
    )
    db.add(card)
    db.flush()
    db.add(
        CardLimit(
            card_id=card.id,
            daily_purchase_limit=Decimal("20000.00"),
            daily_atm_limit=Decimal("5000.00"),
            monthly_limit=Decimal("100000.00"),
            online_enabled=True,
            international_enabled=False,
            contactless_enabled=True,
        )
    )
    return card


def card_status_after_issue() -> str:
    return RequestStatus.PROCESSING
