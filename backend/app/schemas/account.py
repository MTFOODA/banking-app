"""Account schemas."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import Money, MoneyOrNone, ORMModel


class AccountSummaryResponse(ORMModel):
    id: uuid.UUID
    account_type: str
    account_number_masked: str
    iban: str | None = None
    currency: str
    status: str
    current_balance: Money
    available_balance: Money
    blocked_balance: Money
    product_name_en: str
    product_name_ar: str
    opened_at: datetime

    @classmethod
    def from_model(cls, account) -> "AccountSummaryResponse":
        return cls(
            id=account.id,
            account_type=account.account_type,
            account_number_masked=account.account_number_masked,
            iban=account.iban,
            currency=account.currency,
            status=account.status,
            current_balance=account.current_balance,
            available_balance=account.available_balance,
            blocked_balance=account.blocked_balance,
            product_name_en=account.product.name_en if account.product else "",
            product_name_ar=account.product.name_ar if account.product else "",
            opened_at=account.opened_at,
        )


class LinkedCardSummary(BaseModel):
    id: uuid.UUID
    card_last4: str
    card_kind: str
    status: str
    network: str | None = None


class AccountDetailResponse(AccountSummaryResponse):
    linked_cards: list[LinkedCardSummary] = Field(default_factory=list)
    services: list[str] = Field(default_factory=list)


class AccountTotalsResponse(BaseModel):
    total_available: Money
    total_current: Money
    currency: str = "EGP"
    eligible_accounts: int


class AccountsOverviewResponse(BaseModel):
    totals: AccountTotalsResponse
    accounts: list[AccountSummaryResponse]


class AccountRequestCreate(BaseModel):
    request_type: str = Field(pattern="^(account_open|account_close)$")
    account_id: uuid.UUID | None = None
    account_type: str | None = None
    reason: str | None = Field(default=None, max_length=500)
    notes: str | None = Field(default=None, max_length=1000)


class AccountProductResponse(ORMModel):
    id: uuid.UUID
    code: str
    name_en: str
    name_ar: str
    account_type: str
    currency: str
    description_en: str
    description_ar: str
    minimum_balance: Money
    is_active: bool
