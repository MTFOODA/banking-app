"""Demo ledger: transactions, entries, statements and repayments."""

from __future__ import annotations

import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    String,
    Uuid,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, uuid_pk


class Transaction(Base, TimestampMixin):
    """A customer-visible movement on an account or a card.

    `journal_id` groups the paired debit/credit rows produced by a transfer so
    the simplified demo ledger keeps an audit trail. This is NOT the bank's core
    banking ledger.
    """

    __tablename__ = "transactions"
    __table_args__ = (
        CheckConstraint("amount > 0", name="amount_positive"),
        Index("ix_transactions_account_occurred", "account_id", "occurred_at"),
        Index("ix_transactions_customer_occurred", "customer_id", "occurred_at"),
    )

    id = uuid_pk()
    customer_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    account_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("accounts.id", ondelete="RESTRICT"), index=True
    )
    card_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("cards.id", ondelete="SET NULL"), index=True
    )
    journal_id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), index=True, default=uuid.uuid4)
    reference: Mapped[str] = mapped_column(String(40), unique=True, index=True)
    idempotency_key: Mapped[str | None] = mapped_column(String(80), unique=True, index=True)
    request_fingerprint: Mapped[str | None] = mapped_column(String(64))
    authorization_hash: Mapped[str | None] = mapped_column(String(64))
    transfer_metadata: Mapped[dict | None] = mapped_column(JSON)
    transaction_type: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    direction: Mapped[str] = mapped_column(String(8), nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(18, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), default="EGP", nullable=False)
    description: Mapped[str] = mapped_column(String(160))
    description_ar: Mapped[str | None] = mapped_column(String(160))
    counterparty: Mapped[str | None] = mapped_column(String(120))
    merchant: Mapped[str | None] = mapped_column(String(120))
    status: Mapped[str] = mapped_column(String(16), default="posted", index=True, nullable=False)
    is_simulated: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    balance_after: Mapped[Decimal | None] = mapped_column(Numeric(18, 2))
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True, nullable=False
    )


class TransactionEntry(Base):
    __tablename__ = "transaction_entries"
    __table_args__ = (CheckConstraint("amount > 0", name="entry_amount_positive"),)

    id = uuid_pk()
    transaction_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("transactions.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    account_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("accounts.id", ondelete="RESTRICT"), index=True
    )
    entry_type: Mapped[str] = mapped_column(String(8), nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(18, 2), nullable=False)
    investment_holding_id: Mapped[uuid.UUID | None] = mapped_column(Uuid(as_uuid=True), ForeignKey('investment_holdings.id', ondelete='RESTRICT'), index=True)
    ledger_bucket: Mapped[str | None] = mapped_column(String(32))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    transaction: Mapped[Transaction] = relationship(lazy="selectin")


class CreditCardStatement(Base, TimestampMixin):
    __tablename__ = "credit_card_statements"

    id = uuid_pk()
    card_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("cards.id", ondelete="CASCADE"), index=True, nullable=False
    )
    period_start: Mapped[date] = mapped_column(Date, nullable=False)
    period_end: Mapped[date] = mapped_column(Date, nullable=False)
    statement_balance: Mapped[Decimal] = mapped_column(Numeric(18, 2), nullable=False)
    minimum_payment: Mapped[Decimal] = mapped_column(Numeric(18, 2), nullable=False)
    due_date: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[str] = mapped_column(String(16), default="open", nullable=False)


class Repayment(Base, TimestampMixin):
    __tablename__ = "repayments"
    __table_args__ = (CheckConstraint("amount > 0", name="repayment_amount_positive"),)

    id = uuid_pk()
    customer_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    card_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("cards.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    funding_account_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("accounts.id", ondelete="RESTRICT"), nullable=False
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(18, 2), nullable=False)
    mode: Mapped[str] = mapped_column(String(16), default="custom", nullable=False)
    status: Mapped[str] = mapped_column(String(24), default="pending", index=True, nullable=False)
    reference: Mapped[str] = mapped_column(String(40), unique=True, index=True)
    idempotency_key: Mapped[str | None] = mapped_column(String(80), unique=True, index=True)
    is_simulated: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    charges: Mapped[Decimal] = mapped_column(Numeric(18, 2), default=Decimal("0.00"))
    notes: Mapped[str | None] = mapped_column(String(255))
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
