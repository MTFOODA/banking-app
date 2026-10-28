"""Security flows accept no client-supplied customer identity."""
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.auth import FirstLoginCompleteRequest
from app.schemas.transaction import TransferCreate
from app.schemas.investment import InvestmentAction
from app.services.registration_service import normalize_registration_identifier


class RegistrationStart(BaseModel):
    model_config = ConfigDict(extra="forbid")
    identifier: str = Field(min_length=6, max_length=64)

    @field_validator("identifier")
    @classmethod
    def normalize(cls, value):
        return normalize_registration_identifier(value)


class ChallengeRequest(BaseModel):
    challenge: str = Field(min_length=20, max_length=128)


class OtpVerify(ChallengeRequest):
    code: str = Field(pattern=r"^[0-9]{6}$")


class RegistrationComplete(FirstLoginCompleteRequest):
    authorization_token: str = Field(min_length=20, max_length=128)
    username: str = Field(min_length=3, max_length=30)


class UsernameCheck(BaseModel):
    authorization_token: str = Field(min_length=20, max_length=128)
    username: str = Field(min_length=3, max_length=30)


class AuthorizationRequest(BaseModel):
    scope: Literal["transfer", "password_change", "profile_update", "biometric", "investment_subscribe", "investment_redeem"]
    current_password: str = Field(min_length=1, max_length=128)
    transfer: TransferCreate | None = None
    investment: InvestmentAction | None = None


class AuthorizationConsume(BaseModel):
    authorization_token: str = Field(min_length=20, max_length=128)
