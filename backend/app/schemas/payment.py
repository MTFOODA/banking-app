"""Bill payment schemas (simulated)."""

from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field

from app.schemas.common import Money


class BillerResponse(BaseModel):
    code: str
    name_en: str
    name_ar: str
    category: str
    amount_due: Money | None = None


class PaymentCreate(BaseModel):
    biller_code: str = Field(min_length=2, max_length=40)
    amount: Decimal = Field(gt=0, le=Decimal("200000"))
    funding_account_id: uuid.UUID
    note: str | None = Field(default=None, max_length=255)


class PaymentResponse(BaseModel):
    reference: str
    status: str
    amount: Money
    currency: str
    biller_code: str
    biller_name_en: str
    biller_name_ar: str
    is_simulated: bool
    created_at: datetime
