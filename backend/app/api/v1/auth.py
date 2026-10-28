"""Authentication endpoints: sign-in, first-login setup and sessions."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Request
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.exceptions import AppError
from app.dependencies.auth import (
    bearer_scheme,
    client_meta,
    get_current_user,
    get_first_login_user,
)
from app.models.user import User
from app.schemas.auth import (
    ChangePasswordRequest,
    FirstLoginCompleteRequest,
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    LoginRequest,
    LoginResponse,
    LogoutRequest,
    RefreshRequest,
    ResetPasswordRequest,
    SessionUserResponse,
)
from app.schemas.common import MessageResponse
from app.services import auth_service, password_service

router = APIRouter(prefix="/auth", tags=["Authentication"])


def _login_response(status, issued, setup_token, setup_expires, user) -> LoginResponse:
    if status == "password_setup_required":
        return LoginResponse(
            status=status,
            setup_token=setup_token,
            setup_expires_in=setup_expires,
            user=SessionUserResponse.from_user(user) if user else None,
        )
    return LoginResponse(
        status="authenticated",
        access_token=issued.access_token if issued else None,
        expires_in=issued.expires_in if issued else None,
        refresh_token=issued.refresh_token if issued else None,
        user=SessionUserResponse.from_user(user) if user else None,
    )


@router.post("/login", response_model=LoginResponse, summary="Sign in with card number")
def login(payload: LoginRequest, request: Request, db: Session = Depends(get_db)) -> LoginResponse:
    status, issued, setup_token, setup_expires, user = auth_service.authenticate(
        db,
        identifier=payload.identifier,
        password=payload.password,
        remember_device=payload.remember_device,
        bank_code=payload.bank_code,
        meta=client_meta(request),
    )
    return _login_response(status, issued, setup_token, setup_expires, user)


@router.post(
    "/first-login/complete",
    response_model=LoginResponse,
    summary="Set the mandatory password using the restricted first-login session",
)
def complete_first_login(
    payload: FirstLoginCompleteRequest,
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> LoginResponse:
    if credentials is None or not credentials.credentials:
        raise AppError(
            code="invalid_setup_token",
            message="A first-login session is required.",
            status_code=401,
        )
    issued = auth_service.complete_first_login(
        db,
        setup_token=credentials.credentials,
        new_password=payload.new_password,
        confirm_password=payload.confirm_password,
        meta=client_meta(request),
    )
    user = db.get(User, issued.session.user_id)
    return LoginResponse(
        status="authenticated",
        access_token=issued.access_token,
        expires_in=issued.expires_in,
        refresh_token=issued.refresh_token,
        user=SessionUserResponse.from_user(user) if user else None,
    )


@router.post("/refresh", response_model=LoginResponse, summary="Rotate the refresh token")
def refresh(
    payload: RefreshRequest, request: Request, db: Session = Depends(get_db)
) -> LoginResponse:
    issued = auth_service.refresh_session(
        db, refresh_token=payload.refresh_token, meta=client_meta(request)
    )
    user = db.get(User, issued.session.user_id)
    return LoginResponse(
        status="authenticated",
        access_token=issued.access_token,
        expires_in=issued.expires_in,
        refresh_token=issued.refresh_token,
        user=SessionUserResponse.from_user(user) if user else None,
    )


@router.post("/logout", response_model=MessageResponse, summary="Revoke the current session")
def logout(
    payload: LogoutRequest,
    request: Request,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    auth_service.logout(
        db,
        user=user,
        refresh_token=payload.refresh_token,
        all_devices=payload.all_devices,
        meta=client_meta(request),
    )
    return MessageResponse(message="Signed out")



@router.post(
    "/forgot-password",
    response_model=ForgotPasswordResponse,
    summary="Request a staff-issued password reset code",
)
def forgot_password(
    payload: ForgotPasswordRequest, request: Request, db: Session = Depends(get_db)
) -> ForgotPasswordResponse:
    message = password_service.request_password_reset(
        db, identifier=payload.card_number, meta=client_meta(request)
    )
    return ForgotPasswordResponse(message=message)


@router.post(
    "/reset-password",
    response_model=MessageResponse,
    summary="Reset the password with a one-time code issued by the bank",
)
def reset_password(payload: ResetPasswordRequest, db: Session = Depends(get_db)) -> MessageResponse:
    password_service.reset_password(
        db,
        identifier=payload.card_number,
        reset_reference=payload.reset_reference,
        new_password=payload.new_password,
        confirm_password=payload.confirm_password,
    )
    return MessageResponse(message="Your password has been reset. Please sign in again.")


@router.post("/change-password", response_model=MessageResponse, summary="Change password")
def change_password(
    payload: ChangePasswordRequest,
    request: Request,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    password_service.change_password(
        db,
        user=user,
        current_password=payload.current_password,
        authorization_token=payload.authorization_token,
        new_password=payload.new_password,
        confirm_password=payload.confirm_password,
        meta=client_meta(request),
    )
    return MessageResponse(message="Password updated. Please sign in again.")


@router.get("/me", response_model=SessionUserResponse, summary="Current session identity")
def me(user: User = Depends(get_current_user)) -> SessionUserResponse:
    return SessionUserResponse.from_user(user)


@router.get(
    "/first-login/session",
    response_model=SessionUserResponse,
    summary="Identity available to the restricted first-login session",
)
def first_login_session(user: User = Depends(get_first_login_user)) -> SessionUserResponse:
    return SessionUserResponse.from_user(user)

