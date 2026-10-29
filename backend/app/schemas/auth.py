"""Authentication and identity schemas."""

from __future__ import annotations

import uuid

from pydantic import AliasChoices, BaseModel, Field, field_validator, model_validator
from typing import Literal

from app.core.security import (
    PASSWORD_MAX_LENGTH,
    assess_password,
    normalize_identifier,
)
from app.schemas.common import ORMModel


class LoginRequest(BaseModel):
    """Sign-in payload.

    `identifier` accepts the customer's card number **or** account number
    (staff use their employee number). `card_number` remains a supported alias
    so older clients keep working. Separators and letter case are normalised by
    `normalize_identifier`.
    """

    identifier: str = Field(
        min_length=3,
        max_length=32,
        validation_alias=AliasChoices("identifier", "card_number"),
        description="Username, card number, account number or staff employee number",
    )
    password: str = Field(min_length=1, max_length=PASSWORD_MAX_LENGTH)
    remember_device: bool = False
    bank_code: str | None = Field(default=None, pattern=r'^[a-z][a-z0-9_]{1,31}$')
    identifier_type: Literal['legacy','username'] = 'legacy'

    @model_validator(mode='before')
    @classmethod
    def username_input(cls, value):
        if isinstance(value,dict) and value.get('identifier_type')=='username':
            from app.services.username_service import normalize_username
            value=dict(value)
            value['identifier']=normalize_username(str(value.get('identifier',value.get('card_number',''))))
        return value

    @field_validator("identifier")
    @classmethod
    def _normalise(cls, value: str) -> str:
        cleaned = normalize_identifier(value)
        if not cleaned:
            raise ValueError(
                "The card/account number may contain digits, letters and separators only"
            )
        if cleaned.isdigit() and len(cleaned) < 6:
            raise ValueError('Enter a valid card or account number')
        return cleaned


class CustomerProfileResponse(ORMModel):
    bank_code: str = "faisal"
    id: uuid.UUID
    customer_number: str
    first_name_en: str
    last_name_en: str
    first_name_ar: str
    last_name_ar: str
    email: str | None = None
    phone: str | None = None
    address: str | None = None
    national_id_masked: str | None = None
    segment: str
    identity_verified: bool


class SessionUserResponse(ORMModel):
    id: uuid.UUID
    username: str | None = None
    login_identifier_masked: str
    login_type: str
    must_change_password: bool
    profile: CustomerProfileResponse | None = None
    roles: list[str] = Field(default_factory=list)
    permissions: list[str] = Field(default_factory=list)
    preferred_language: str | None = None
    preferred_theme: str | None = None

    @classmethod
    def from_user(cls, user) -> "SessionUserResponse":
        return cls(
            id=user.id,
            username=user.username,
            login_identifier_masked=user.login_identifier_masked,
            login_type=user.login_type,
            must_change_password=user.must_change_password,
            profile=user.profile,
            roles=user.role_codes,
            permissions=user.permission_codes,
            preferred_language=user.preferences.language if user.preferences else None,
            preferred_theme=user.preferences.theme if user.preferences else None,
        )


class LoginResponse(BaseModel):
    status: str = Field(description="authenticated or password_setup_required")
    access_token: str | None = None
    token_type: str = "bearer"
    expires_in: int | None = None
    refresh_token: str | None = None
    setup_token: str | None = None
    setup_expires_in: int | None = None
    user: SessionUserResponse | None = None


class FirstLoginCompleteRequest(BaseModel):
    new_password: str = Field(min_length=1, max_length=PASSWORD_MAX_LENGTH)
    confirm_password: str = Field(min_length=1, max_length=PASSWORD_MAX_LENGTH)

    @field_validator("new_password")
    @classmethod
    def _policy(cls, value: str) -> str:
        assessment = assess_password(value)
        if not assessment.valid:
            raise ValueError(
                "Password does not satisfy the policy: " + ", ".join(assessment.failed_codes)
            )
        return value

    @field_validator("confirm_password")
    @classmethod
    def _match(cls, value: str, info) -> str:
        if info.data.get("new_password") and value != info.data["new_password"]:
            raise ValueError("The passwords do not match")
        return value


class ChangePasswordRequest(BaseModel):
    authorization_token: str = Field(min_length=20, max_length=128)
    current_password: str = Field(min_length=1, max_length=PASSWORD_MAX_LENGTH)
    new_password: str = Field(min_length=1, max_length=PASSWORD_MAX_LENGTH)
    confirm_password: str = Field(min_length=1, max_length=PASSWORD_MAX_LENGTH)

    @field_validator("new_password")
    @classmethod
    def _policy(cls, value: str) -> str:
        assessment = assess_password(value)
        if not assessment.valid:
            raise ValueError(
                "Password does not satisfy the policy: " + ", ".join(assessment.failed_codes)
            )
        return value


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=10)


class LogoutRequest(BaseModel):
    refresh_token: str | None = None
    all_devices: bool = False


class ForgotPasswordRequest(BaseModel):
    card_number: str = Field(min_length=6, max_length=32)


class ForgotPasswordResponse(BaseModel):
    message: str
    demo_reference: str | None = None


class ResetPasswordRequest(BaseModel):
    card_number: str = Field(min_length=6, max_length=32)
    reset_reference: str = Field(min_length=6, max_length=64)
    new_password: str = Field(min_length=1, max_length=PASSWORD_MAX_LENGTH)
    confirm_password: str = Field(min_length=1, max_length=PASSWORD_MAX_LENGTH)
