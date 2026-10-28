"""Profile, preferences and active session endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_token
from app.dependencies.auth import bearer_scheme, get_current_customer
from app.models.user import User
from app.schemas.profile import (
    CustomerSessionResponse,
    PreferencesResponse,
    PreferencesUpdate,
    ProfileResponse,
    ProfileUpdate,
)
from app.services import profile_service

router = APIRouter(tags=["Profile"])


@router.get("/profile", response_model=ProfileResponse, summary="Customer profile")
def get_profile(user: User = Depends(get_current_customer), db: Session = Depends(get_db)) -> ProfileResponse:
    return ProfileResponse(**profile_service.get_profile(user, db))


@router.patch("/profile", summary="Submit contact changes for bank review")
def update_profile(
    payload: ProfileUpdate,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
):
    return profile_service.update_profile(db, user, payload.model_dump(exclude_unset=True))


@router.get("/preferences", response_model=PreferencesResponse, summary="Customer preferences")
def get_preferences(
    user: User = Depends(get_current_customer), db: Session = Depends(get_db)
) -> PreferencesResponse:
    preferences = profile_service.get_or_create_preferences(db, user)
    return PreferencesResponse.model_validate(preferences)


@router.patch(
    "/preferences", response_model=PreferencesResponse, summary="Update customer preferences"
)
def update_preferences(
    payload: PreferencesUpdate,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> PreferencesResponse:
    preferences = profile_service.update_preferences(
        db, user, payload.model_dump(exclude_unset=True)
    )
    return PreferencesResponse.model_validate(preferences)


@router.get(
    "/profile/sessions",
    response_model=list[CustomerSessionResponse],
    summary="Active sessions and trusted devices",
)
def sessions(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> list[CustomerSessionResponse]:
    current_id = None
    if credentials is not None:
        try:
            current_id = decode_token(credentials.credentials).get("sid")
        except Exception:  # pragma: no cover - token already validated by dependency
            current_id = None
    return [
        CustomerSessionResponse(**item)
        for item in profile_service.active_sessions(db, user, current_id)
    ]
