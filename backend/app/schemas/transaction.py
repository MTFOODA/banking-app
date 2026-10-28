"""Transaction, transfer and repayment schemas."""

from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field, model_validator, field_validator
from typing import Literal
from app.schemas.transfer_recipient import TransferRecipient, OUTBOUND_TYPES

from app.schemas.common import Money, MoneyOrNone, ORMModel


class TransactionResponse(ORMModel):
    id: uuid.UUID
    reference: str
    transaction_type: str
    direction: str
    amount: Money
    currency: str
    description: str
    description_ar: str | None = None
    counterparty: str | None = None
    merchant: str | None = None
    status: str
    is_simulated: bool
    balance_after: MoneyOrNone = None
    occurred_at: datetime
    account_id: uuid.UUID | None = None
    card_id: uuid.UUID | None = None
    card_last4: str | None = None
    account_number_masked: str | None = None

    @classmethod
    def from_model(cls, transaction, *, account=None, card=None) -> "TransactionResponse":
        return cls(
            id=transaction.id,
            reference=transaction.reference,
            transaction_type=transaction.transaction_type,
            direction=transaction.direction,
            amount=transaction.amount,
            currency=transaction.currency,
            description=transaction.description,
            description_ar=transaction.description_ar,
            counterparty=transaction.counterparty,
            merchant=transaction.merchant,
            status=transaction.status,
            is_simulated=transaction.is_simulated,
            balance_after=transaction.balance_after,
            occurred_at=transaction.occurred_at,
            account_id=transaction.account_id,
            card_id=transaction.card_id,
            card_last4=card.card_last4 if card is not None else None,
            account_number_masked=account.account_number_masked if account is not None else None,
        )


class TransactionFilterOptions(BaseModel):
    types: list[str]
    statuses: list[str]
    directions: list[str]


class TransactionDetailResponse(TransactionResponse):
    fees: Money = Decimal("0.00")
    source_label: str | None = None
    destination_label: str | None = None
    receipt_available: bool = False


class BeneficiaryResponse(ORMModel):
    id: uuid.UUID
    name: str
    nickname: str | None = None
    bank_name: str
    account_number_masked: str
    iban: str | None = None
    currency: str
    status: str


class BeneficiaryCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    nickname: str | None = Field(default=None, max_length=80)
    bank_name: str = Field(min_length=2, max_length=120)
    account_number: str = Field(min_length=6, max_length=34)
    iban: str | None = Field(default=None, max_length=34)
    currency: str = Field(default="EGP", min_length=3, max_length=3)


class TransferCreate(BaseModel):
    fx_quote_id: uuid.UUID | None = None
    transfer_type: Literal['own_accounts','internal','external_domestic','international','wallet','instapay'] | None = None
    recipient: TransferRecipient | None = None
    source_account_id: uuid.UUID
    amount: Decimal = Field(gt=0, le=Decimal("1000000"), decimal_places=2, allow_inf_nan=False)
    currency: str = Field(default="EGP", min_length=3, max_length=3)
    destination_account_id: uuid.UUID | None = None
    beneficiary_id: uuid.UUID | None = None
    purpose: str | None = Field(default=None, max_length=160)
    note: str | None = Field(default=None, max_length=255)
    authorization_token: str | None = Field(default=None, max_length=128)

    @model_validator(mode="after")
    def _destination_required(self) -> "TransferCreate":
        if self.fx_quote_id and self.transfer_type!='own_accounts':
            raise ValueError('Currency conversion is restricted to own-account transfers')
        if self.transfer_type in OUTBOUND_TYPES:
            if self.recipient is None or self.destination_account_id or self.beneficiary_id:
                raise ValueError('Provide routing details only for an outbound transfer')
            self.recipient.for_channel(self.transfer_type)
            if self.transfer_type in {'external_domestic','wallet','instapay'} and self.currency.upper()!='EGP':
                raise ValueError('Domestic, wallet and InstaPay transfers require EGP')
            return self
        if self.recipient is not None:
            raise ValueError('Recipient routing details are only allowed for outbound transfers')
        if self.transfer_type=='own_accounts' and self.beneficiary_id:
            raise ValueError('Choose your own destination account')
        if self.transfer_type=='internal' and not self.beneficiary_id:
            raise ValueError('Choose a saved same-bank beneficiary')
        if self.destination_account_id is None and self.beneficiary_id is None:
            raise ValueError("A destination account or beneficiary is required")
        if self.destination_account_id and self.beneficiary_id:
            raise ValueError("Provide either a destination account or a beneficiary, not both")
        return self

    @field_validator('currency',mode='before')
    @classmethod
    def _currency(cls,value):return value.strip().upper() if isinstance(value,str) else value


class TransferResponse(BaseModel):
    exchange_rate: str | None = None
    received_amount: MoneyOrNone = None
    received_currency: str | None = None
    rate_provider: str | None = None
    rate_as_of: str | None = None
    purpose: str | None = None
    transfer_type: str | None = None
    delivery_status: str | None = None
    provider_reference: str | None = None
    recipient_name: str | None = None
    bank_name: str | None = None
    country_code: str | None = None
    fees: Money = Decimal("0.00")
    total_debit: Money
    reference: str
    status: str
    amount: Money
    currency: str
    source_account_id: uuid.UUID
    destination_label: str
    is_simulated: bool
    created_at: datetime
    journal_id: uuid.UUID
    note: str | None = None


class RepaymentCreate(BaseModel):
    card_id: uuid.UUID
    funding_account_id: uuid.UUID
    mode: str = Field(pattern="^(full|statement|minimum|custom)$")
    amount: Decimal | None = Field(default=None, gt=0, le=Decimal("1000000"))

    @model_validator(mode="after")
    def _custom_amount(self) -> "RepaymentCreate":
        if self.mode == "custom" and self.amount is None:
            raise ValueError("A custom repayment requires an amount")
        return self


class RepaymentQuote(BaseModel):
    card_id: uuid.UUID
    mode: str
    amount: Money
    statement_balance: Money
    outstanding_balance: Money
    minimum_payment: Money
    available_credit: Money
    charges: Money
    payable: Money
    funding_account_id: uuid.UUID
    funding_available_balance: Money
    eligible: bool
    ineligibility_reason: str | None = None


class RepaymentResponse(BaseModel):
    id: uuid.UUID
    reference: str
    card_id: uuid.UUID
    card_last4: str
    funding_account_id: uuid.UUID
    amount: Money
    mode: str
    status: str
    is_simulated: bool
    charges: Money
    created_at: datetime
    completed_at: datetime | None = None
    notes: str | None = None
