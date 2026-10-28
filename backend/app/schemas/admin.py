"""Administration schemas."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field, ConfigDict

from app.schemas.request import ServiceRequestResponse


class AuditLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    actor_label: str | None = None
    action: str
    entity_type: str
    entity_id: str | None = None
    details: dict | None = None
    ip_address: str | None = None
    created_at: datetime


class AdminDashboardResponse(BaseModel):
    demo_data: bool = True
    customers_count: int
    active_accounts: int
    cards_by_status: dict[str, int]
    requests_by_status: dict[str, int]
    pending_requests: int
    published_announcements: int
    scheduled_maintenance: int
    recent_actions: list[AuditLogResponse]
    generated_at: datetime



class AdminCustomerListItem(BaseModel):
    id: uuid.UUID
    customer_number: str
    name_en: str
    name_ar: str
    email: str | None = None
    phone: str | None = None
    segment: str
    identity_verified: bool
    is_active: bool
    must_change_password: bool
    accounts_count: int
    cards_count: int
    open_requests: int
    created_at: datetime


class AdminCustomerAccount(BaseModel):
    id: uuid.UUID
    account_type: str
    account_number_masked: str
    status: str
    current_balance: float
    available_balance: float
    currency: str


class AdminCustomerCard(BaseModel):
    id: uuid.UUID
    card_last4: str
    card_kind: str
    status: str
    is_supplementary: bool


class AdminCustomerDetail(AdminCustomerListItem):
    accounts: list[AdminCustomerAccount] = Field(default_factory=list)
    cards: list[AdminCustomerCard] = Field(default_factory=list)
    requests: list[ServiceRequestResponse] = Field(default_factory=list)
    national_id_masked: str | None = None
    date_of_birth: str | None = None


class AdminRequestListItem(BaseModel):
    id: uuid.UUID
    reference: str
    customer_id: uuid.UUID
    customer_name: str
    request_type: str
    status: str
    priority: str
    submitted_at: datetime | None = None
    assigned_label: str | None = None


class AdminRequestDetail(ServiceRequestResponse):
    customer: AdminCustomerListItem | None = None


class AdminReviewerResponse(BaseModel):
    id: uuid.UUID
    display_name: str
    roles: list[str] = Field(default_factory=list)

