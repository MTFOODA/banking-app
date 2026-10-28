"""Reusable FastAPI dependencies: authentication, roles and request metadata."""

from __future__ import annotations

from collections.abc import Callable

import jwt
from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.exceptions import AppError
from app.core.security import TokenType, decode_token
from app.models.enums import LoginType
from app.models.user import RefreshSession, User
from app.services.common import utcnow

bearer_scheme = HTTPBearer(auto_error=False)


def client_meta(request: Request) -> dict:
    # Uvicorn's trusted-proxy configuration handles forwarded addresses.
    # Never let an arbitrary client choose its own brute-force limiter bucket.
    ip = request.client.host if request.client else None
    return {"ip_address": ip, "user_agent": request.headers.get("user-agent", "")[:250]}


def _resolve_user(
    db: Session, credentials: HTTPAuthorizationCredentials | None, *, expected_type: str
) -> User:
    if credentials is None or not credentials.credentials:
        raise AppError(
            code="not_authenticated", message="Authentication is required.", status_code=401
        )
    try:
        payload = decode_token(credentials.credentials)
    except jwt.ExpiredSignatureError as exc:
        raise AppError(
            code="token_expired", message="Your session has expired.", status_code=401
        ) from exc
    except jwt.PyJWTError as exc:
        raise AppError(
            code="invalid_token", message="Your session is invalid.", status_code=401
        ) from exc

    if payload.get("typ") != expected_type:
        raise AppError(
            code="invalid_token",
            message="This session cannot access the requested resource.",
            status_code=403,
        )

    session = db.get(RefreshSession, payload.get("sid"))
    now = utcnow()
    if session is None or session.revoked_at is not None or session.expires_at <= now:
        raise AppError(
            code="session_expired", message="Your session has ended. Please sign in again.", status_code=401
        )

    user = db.get(User, payload.get("sub"))
    if (user is None or not user.is_active or not user.enrollment_completed or user.is_locked
        or (user.locked_until and user.locked_until > now) or session.user_id != user.id):
        raise AppError(
            code="session_expired", message="Your session has ended. Please sign in again.", status_code=401
        )

    return user


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    user = _resolve_user(db, credentials, expected_type=TokenType.ACCESS)
    if user.must_change_password:
        raise AppError(
            code="password_setup_required",
            message="Complete your mandatory password setup first.",
            status_code=403,
        )
    return user


def get_current_customer(user: User = Depends(get_current_user)) -> User:
    if user.login_type != LoginType.CUSTOMER or user.profile is None:
        raise AppError(
            code="customer_only", message="This resource is for customers only.", status_code=403
        )
    return user


def require_permissions(*required: str) -> Callable[..., User]:
    """Dependency factory enforcing server-side RBAC for staff endpoints."""

    def _dependency(user: User = Depends(get_current_user)) -> User:
        if user.login_type != LoginType.STAFF:
            raise AppError(code="forbidden", message="Administrator access required.", status_code=403)
        granted = set(user.permission_codes)
        missing = [code for code in required if code not in granted]
        if missing:
            raise AppError(
                code="forbidden",
                message="You do not have permission to perform this action.",
                status_code=403,
                details={"missing_permissions": missing},
            )
        return user

    return _dependency


def get_first_login_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    return _resolve_user(db, credentials, expected_type=TokenType.FIRST_LOGIN)
