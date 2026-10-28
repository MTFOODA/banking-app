"""Customer profile, preferences and support schemas."""

from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.schemas.auth import CustomerProfileResponse


class ProfileResponse(BaseModel):
    username: str | None = None
    pending_reference: str | None = None
    user_id: uuid.UUID
    login_identifier_masked: str
    must_change_password: bool
    profile: CustomerProfileResponse
    roles: list[str]
    permissions: list[str]
    preferred_language: str | None = None
    preferred_theme: str | None = None


class ProfileUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    authorization_token: str = Field(min_length=20, max_length=128)
    email: EmailStr | None = None
    phone: str | None = Field(default=None, pattern=r"^\+?[0-9]{8,15}$")
    address: str | None = Field(default=None, min_length=5, max_length=255)

    @field_validator("address")
    @classmethod
    def trim_address(cls, value):
        if value is not None and len(value.strip()) < 5:
            raise ValueError("Enter a valid address")
        return value.strip() if value else value


class PreferencesResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    language: str
    theme: str
    notifications_enabled: bool
    transaction_notifications: bool
    marketing_notifications: bool
    biometric_enabled: bool


class PreferencesUpdate(BaseModel):
    language: str | None = Field(default=None, pattern="^(en|ar)$")
    theme: str | None = Field(default=None, pattern="^(light|dark|system)$")
    notifications_enabled: bool | None = None
    transaction_notifications: bool | None = None
    marketing_notifications: bool | None = None


class SupportMessageResponse(BaseModel):
    id: uuid.UUID
    sender_type: str
    body: str
    created_at: datetime


class SupportTicketResponse(BaseModel):
    id: uuid.UUID
    reference: str
    subject: str
    status: str
    priority: str
    created_at: datetime
    messages: list[SupportMessageResponse] = Field(default_factory=list)


class SupportTicketCreate(BaseModel):
    subject: str = Field(min_length=3, max_length=160)
    message: str = Field(min_length=3, max_length=2000)
    priority: str = Field(default="normal", pattern="^(low|normal|high)$")


class SupportMessageCreate(BaseModel):
    message: str = Field(min_length=1, max_length=2000)


class DocumentUploadResponse(BaseModel):
    id: uuid.UUID
    filename: str
    content_type: str
    size_bytes: int
    created_at: datetime


class CustomerSessionResponse(BaseModel):
    id: uuid.UUID
    user_agent: str | None = None
    ip_address: str | None = None
    created_at: datetime
    last_used_at: datetime | None = None
    expires_at: datetime
    current: bool = False


class DateOfBirthUpdate(BaseModel):
    date_of_birth: date | None = None
