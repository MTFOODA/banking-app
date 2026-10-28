"""Card and card-request schemas. PAN, CVV and PIN are never serialised."""

from __future__ import annotations

import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field

from app.schemas.common import Money, MoneyOrNone


class CardLimitResponse(BaseModel):
    daily_purchase_limit: Money
    daily_atm_limit: Money
    monthly_limit: Money
    online_enabled: bool
    international_enabled: bool
    contactless_enabled: bool


class CardSummaryResponse(BaseModel):
    product_code: str = ''
    currency: str | None = None
    id: uuid.UUID
    card_last4: str
    card_kind: str
    network: str | None = None
    status: str
    cardholder_name: str
    expiry_month: int
    expiry_year: int
    is_primary: bool
    is_supplementary: bool
    account_id: uuid.UUID | None = None
    account_number_masked: str | None = None
    available_balance: MoneyOrNone = None
    product_name_en: str
    product_name_ar: str
    credit_limit: MoneyOrNone = None
    available_credit: MoneyOrNone = None
    outstanding_balance: MoneyOrNone = None
    statement_balance: MoneyOrNone = None
    minimum_payment: MoneyOrNone = None
    payment_due_date: date | None = None
    issued_at: datetime
    limits: CardLimitResponse | None = None

    @classmethod
    def from_model(cls, card) -> "CardSummaryResponse":
        limits = None
        if card.limits:
            limits = CardLimitResponse(
                daily_purchase_limit=card.limits.daily_purchase_limit,
                daily_atm_limit=card.limits.daily_atm_limit,
                monthly_limit=card.limits.monthly_limit,
                online_enabled=card.limits.online_enabled,
                international_enabled=card.limits.international_enabled,
                contactless_enabled=card.limits.contactless_enabled,
            )
        return cls(
            product_code=card.product.code if card.product else '',
            currency=card.account.currency if card.account else None,
            id=card.id,
            card_last4=card.card_last4,
            card_kind=card.card_kind,
            network=card.network,
            status=card.status,
            cardholder_name=card.cardholder_name,
            expiry_month=card.expiry_month,
            expiry_year=card.expiry_year,
            is_primary=card.is_primary,
            is_supplementary=card.is_supplementary,
            account_id=card.account_id,
            account_number_masked=card.account.account_number_masked if card.account else None,
            available_balance=card.account.available_balance if card.account else None,
            product_name_en=card.product.name_en if card.product else "",
            product_name_ar=card.product.name_ar if card.product else "",
            credit_limit=card.credit_limit,
            available_credit=card.available_credit,
            outstanding_balance=card.outstanding_balance,
            statement_balance=card.statement_balance,
            minimum_payment=card.minimum_payment,
            payment_due_date=card.payment_due_date,
            issued_at=card.issued_at,
            limits=limits,
        )


class CardEligibleAccount(BaseModel):
    id: uuid.UUID
    account_number_masked: str
    currency: str
    account_type: str


class CardProductOffer(BaseModel):
    code: str
    variant: str
    name_en: str
    name_ar: str
    network: str | None = None
    annual_fee: Money
    fee_currency: str
    investment_only: bool
    under_21_only: bool
    currencies: list[str]
    eligible: bool
    ineligibility_reason: str | None = None
    accounts: list[CardEligibleAccount]


class CardsOverviewResponse(BaseModel):
    cards: list[CardSummaryResponse]
    active_count: int
    frozen_count: int
    credit_outstanding_total: Money


class CardActionRequest(BaseModel):
    reason: str | None = Field(default=None, max_length=255)
    note: str | None = Field(default=None, max_length=500)


class ReportLostRequest(BaseModel):
    report_type: str = Field(pattern="^(lost|stolen)$")
    note: str | None = Field(default=None, max_length=500)


class ReplacementRequestCreate(BaseModel):
    reason: str = Field(min_length=3, max_length=255)
    delivery_branch: str | None = Field(default=None, max_length=120)
    urgent: bool = False


class LimitChangeRequestCreate(BaseModel):
    limit_type: str = Field(pattern="^(daily_purchase|daily_atm|monthly)$")
    requested_amount: Decimal = Field(gt=0, le=Decimal("1000000"))
    reason: str = Field(min_length=3, max_length=255)


class CardToggleRequest(BaseModel):
    enabled: bool


class SupplementaryCardRequestCreate(BaseModel):
    primary_card_id: uuid.UUID
    holder_first_name: str = Field(min_length=2, max_length=60)
    holder_last_name: str = Field(min_length=2, max_length=60)
    holder_relationship: str = Field(min_length=2, max_length=40)
    holder_national_id: str = Field(min_length=6, max_length=32)
    holder_phone: str | None = Field(default=None, max_length=32)
    card_product_code: str | None = Field(default=None, max_length=32)
    spending_limit: Decimal = Field(gt=0, le=Decimal("500000"))
    restrictions: list[str] = Field(default_factory=list)


class CardRequestCreate(BaseModel):
    request_type: str = Field(
        pattern=(
            "^(card_issue|card_replacement|card_renewal|card_cancellation|pin_reset|"
            "card_limit_increase|card_limit_decrease)$"
        )
    )
    card_id: uuid.UUID | None = None
    notes: str | None = Field(default=None, max_length=1000)
    form_data: dict = Field(default_factory=dict)
