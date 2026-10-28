"""Accounts, card products and customer relationships."""

from __future__ import annotations

import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    Uuid,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, uuid_pk
from app.models.enums import AccountType, CardKind
from app.models.user import User


class AccountProduct(Base, TimestampMixin):
    __tablename__ = "account_products"

    id = uuid_pk()
    code: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    name_en: Mapped[str] = mapped_column(String(120))
    name_ar: Mapped[str] = mapped_column(String(120))
    account_type: Mapped[str] = mapped_column(String(24), default=AccountType.CURRENT)
    currency: Mapped[str] = mapped_column(String(3), default="EGP")
    description_en: Mapped[str] = mapped_column(Text)
    description_ar: Mapped[str] = mapped_column(Text)
    minimum_balance: Mapped[Decimal] = mapped_column(Numeric(18, 2), default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class Account(Base, TimestampMixin):
    __tablename__ = "accounts"
    __table_args__ = (
        CheckConstraint("current_balance >= 0", name="current_balance_non_negative"),
        CheckConstraint("available_balance >= 0", name="available_balance_non_negative"),
        CheckConstraint("blocked_balance >= 0", name="blocked_balance_non_negative"),
    )

    id = uuid_pk()
    customer_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("account_products.id", ondelete="RESTRICT"), nullable=False
    )
    account_number_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    account_number_masked: Mapped[str] = mapped_column(String(32))
    iban: Mapped[str | None] = mapped_column(String(34), unique=True, index=True)
    account_type: Mapped[str] = mapped_column(String(24), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), default="EGP", nullable=False)
    status: Mapped[str] = mapped_column(String(24), default="active", index=True, nullable=False)
    current_balance: Mapped[Decimal] = mapped_column(Numeric(18, 2), default=Decimal("0.00"))
    available_balance: Mapped[Decimal] = mapped_column(Numeric(18, 2), default=Decimal("0.00"))
    blocked_balance: Mapped[Decimal] = mapped_column(Numeric(18, 2), default=Decimal("0.00"))
    opened_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    closed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    customer: Mapped[User] = relationship(lazy="selectin")
    product: Mapped[AccountProduct] = relationship(lazy="selectin")


class CardProduct(Base, TimestampMixin):
    __tablename__ = "card_products"

    id = uuid_pk()
    code: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    name_en: Mapped[str] = mapped_column(String(120))
    name_ar: Mapped[str] = mapped_column(String(120))
    card_kind: Mapped[str] = mapped_column(String(16), default=CardKind.DEBIT)
    network: Mapped[str | None] = mapped_column(String(24))
    description_en: Mapped[str] = mapped_column(Text)
    description_ar: Mapped[str] = mapped_column(Text)
    annual_fee: Mapped[Decimal] = mapped_column(Numeric(18, 2), default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class Card(Base, TimestampMixin):
    __tablename__ = "cards"
    __table_args__ = (
        CheckConstraint(
            "available_credit IS NULL OR available_credit >= 0", name="credit_available_positive"
        ),
        CheckConstraint(
            "credit_limit IS NULL OR credit_limit >= 0", name="credit_limit_positive"
        ),
    )

    id = uuid_pk()
    customer_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    account_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("accounts.id", ondelete="SET NULL"), index=True
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("card_products.id", ondelete="RESTRICT"), nullable=False
    )
    # Only a keyed hash and a tokenised demo reference are stored - never the PAN.
    card_number_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    pan_token: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    card_last4: Mapped[str] = mapped_column(String(4))
    cardholder_name: Mapped[str] = mapped_column(String(120))
    card_kind: Mapped[str] = mapped_column(String(16), default=CardKind.DEBIT, nullable=False)
    network: Mapped[str | None] = mapped_column(String(24))
    expiry_month: Mapped[int] = mapped_column(Integer)
    expiry_year: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(24), default="active", index=True, nullable=False)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_supplementary: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    credit_limit: Mapped[Decimal | None] = mapped_column(Numeric(18, 2))
    available_credit: Mapped[Decimal | None] = mapped_column(Numeric(18, 2))
    outstanding_balance: Mapped[Decimal | None] = mapped_column(Numeric(18, 2))
    statement_balance: Mapped[Decimal | None] = mapped_column(Numeric(18, 2))
    minimum_payment: Mapped[Decimal | None] = mapped_column(Numeric(18, 2))
    payment_due_date: Mapped[date | None] = mapped_column(Date)
    issued_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    customer: Mapped[User] = relationship(lazy="selectin")
    account: Mapped[Account | None] = relationship(lazy="selectin")
    product: Mapped[CardProduct] = relationship(lazy="selectin")
    limits: Mapped["CardLimit | None"] = relationship(
        back_populates="card", uselist=False, cascade="all, delete-orphan", lazy="selectin"
    )


class CardLimit(Base, TimestampMixin):
    __tablename__ = "card_limits"

    id = uuid_pk()
    card_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("cards.id", ondelete="CASCADE"),
        unique=True,
        index=True,
        nullable=False,
    )
    daily_purchase_limit: Mapped[Decimal] = mapped_column(Numeric(18, 2), default=0)
    daily_atm_limit: Mapped[Decimal] = mapped_column(Numeric(18, 2), default=0)
    monthly_limit: Mapped[Decimal] = mapped_column(Numeric(18, 2), default=0)
    online_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    international_enabled: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    contactless_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    card: Mapped[Card] = relationship(back_populates="limits")


class SupplementaryCardRelationship(Base, TimestampMixin):
    __tablename__ = "supplementary_card_relationships"

    id = uuid_pk()
    primary_card_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("cards.id", ondelete="CASCADE"), index=True, nullable=False
    )
    supplementary_card_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("cards.id", ondelete="CASCADE"),
        unique=True,
        index=True,
        nullable=False,
    )
    holder_name: Mapped[str] = mapped_column(String(120))
    relationship_type: Mapped[str] = mapped_column(String(48))


class Beneficiary(Base, TimestampMixin):
    __tablename__ = "beneficiaries"

    id = uuid_pk()
    destination_account_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("accounts.id", ondelete="RESTRICT"), index=True
    )
    customer_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(120))
    nickname: Mapped[str | None] = mapped_column(String(80))
    bank_name: Mapped[str] = mapped_column(String(120))
    account_number_masked: Mapped[str] = mapped_column(String(32))
    iban: Mapped[str | None] = mapped_column(String(34))
    currency: Mapped[str] = mapped_column(String(3), default="EGP", nullable=False)
    status: Mapped[str] = mapped_column(String(16), default="active", nullable=False)
