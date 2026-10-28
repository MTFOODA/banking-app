"""Simulated subscriptions backed by the existing product and transaction ledger."""
import uuid
from datetime import datetime
from decimal import Decimal
from sqlalchemy import CheckConstraint, DateTime, ForeignKey, JSON, Numeric, String, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base, TimestampMixin, uuid_pk


class InvestmentTerms(Base, TimestampMixin):
    __tablename__ = 'investment_terms'
    __table_args__ = (CheckConstraint('minimum_amount > 0 AND amount_step > 0 AND unit_price > 0', name='investment_terms_positive'),
        CheckConstraint('term_months >= 0 AND max_penalty_percent >= 0 AND max_penalty_percent <= 100', name='investment_terms_policy'),)
    product_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey('banking_products.id', ondelete='RESTRICT'), primary_key=True)
    term_months: Mapped[int] = mapped_column(default=0)
    minimum_amount: Mapped[Decimal] = mapped_column(Numeric(18, 2))
    amount_step: Mapped[Decimal] = mapped_column(Numeric(18, 2))
    unit_price: Mapped[Decimal] = mapped_column(Numeric(18, 2), default=1)
    max_penalty_percent: Mapped[Decimal] = mapped_column(Numeric(5, 2), default=5)


class InvestmentHolding(Base, TimestampMixin):
    __tablename__ = 'investment_holdings'
    __table_args__ = (CheckConstraint('principal > 0 AND units > 0 AND unit_price > 0', name='investment_holding_positive'),
        CheckConstraint("status IN ('active','redeemed')", name='investment_holding_status'),)
    id = uuid_pk()
    customer_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey('users.id', ondelete='RESTRICT'), index=True)
    account_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey('accounts.id', ondelete='RESTRICT'), index=True)
    product_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey('banking_products.id', ondelete='RESTRICT'), index=True)
    principal: Mapped[Decimal] = mapped_column(Numeric(18, 2))
    units: Mapped[Decimal] = mapped_column(Numeric(18, 6))
    unit_price: Mapped[Decimal] = mapped_column(Numeric(18, 2))
    max_penalty_percent: Mapped[Decimal] = mapped_column(Numeric(5, 2))
    opened_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    matures_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    redeemed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(String(16), default='active', index=True)


class InvestmentOperation(Base, TimestampMixin):
    __tablename__ = 'investment_operations'
    __table_args__ = (UniqueConstraint('customer_id', 'idempotency_key', name='uq_investment_operation_retry'),)
    id = uuid_pk()
    customer_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey('users.id', ondelete='RESTRICT'), index=True)
    holding_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey('investment_holdings.id', ondelete='RESTRICT'), index=True)
    transaction_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey('transactions.id', ondelete='RESTRICT'), unique=True, index=True)
    idempotency_key: Mapped[str] = mapped_column(String(40))
    request_fingerprint: Mapped[str] = mapped_column(String(64))
    authorization_hash: Mapped[str] = mapped_column(String(64))
    receipt: Mapped[dict] = mapped_column(JSON)
