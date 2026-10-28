"""Password change and staff-assisted reset flows."""

from __future__ import annotations

from datetime import timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.core.security import (
    assess_password,
    generate_opaque_token,
    hash_identifier,
    hash_password,
    hash_token,
    verify_password,
)
from app.models.user import RefreshSession, User
from app.services.common import record_audit, utcnow


def change_password(
    db: Session,
    *,
    user: User,
    current_password: str,
    authorization_token: str,
    new_password: str,
    confirm_password: str,
    meta: dict | None,
) -> None:
    from app.services import security_service
    security_service.throttle(db, f"password_change:{user.id}", 10, 600)
    user = security_service.lock_user(db, user)
    security_service.reauthenticate(db, user, current_password)
    security_service.consume_grant(db, user, authorization_token, "password_change")
    assessment = assess_password(new_password)
    if not assessment.valid:
        raise AppError(
            code="password_policy_violation",
            message="Password does not satisfy the security policy.",
            status_code=422,
            details={"failed_requirements": assessment.failed_codes},
        )
    if new_password != confirm_password:
        raise AppError(
            code="password_mismatch", message="The passwords do not match.", status_code=422
        )
    if verify_password(new_password, user.password_hash):
        raise AppError(
            code="password_reuse",
            message="Choose a password different from the current one.",
            status_code=422,
        )

    user.password_hash = hash_password(new_password)
    user.password_updated_at = utcnow()
    user.must_change_password = False
    user.reset_token_hash = None
    user.reset_token_expires_at = None
    from app.models.security import AuthorizationGrant
    from sqlalchemy import update
    db.execute(update(AuthorizationGrant).where(AuthorizationGrant.user_id == user.id,
        AuthorizationGrant.consumed_at.is_(None)).values(consumed_at=utcnow()))

    sessions = db.scalars(
        select(RefreshSession).where(
            RefreshSession.user_id == user.id, RefreshSession.revoked_at.is_(None)
        )
    ).all()
    for session in sessions:
        session.revoked_at = utcnow()
        session.revoked_reason = "password_changed"

    record_audit(
        db,
        actor=user,
        action="auth.password_changed",
        entity_type="user",
        entity_id=user.id,
        ip_address=(meta or {}).get("ip_address"),
    )
    db.commit()


def request_password_reset(db: Session, *, identifier: str, meta: dict | None) -> str:
    """Always return a generic message to prevent account enumeration."""
    user = db.scalar(select(User).where(User.login_identifier_hash == hash_identifier(identifier)))
    if user is not None:
        record_audit(
            db,
            actor=None,
            action="auth.password_reset_requested",
            entity_type="user",
            entity_id=user.id,
            ip_address=(meta or {}).get("ip_address"),
        )
        db.commit()
    return (
        "If the details match a customer record, a bank representative will contact you "
        "with a one-time password reset code."
    )


def issue_reset_token(db: Session, *, user: User, ttl_minutes: int = 30) -> str:
    """Staff/CLI-issued one-time code. Never exposed through public endpoints."""
    raw = generate_opaque_token(24)
    user.reset_token_hash = hash_token(raw)
    user.reset_token_expires_at = utcnow() + timedelta(minutes=ttl_minutes)
    user.reset_token_used_at = None
    db.commit()
    return raw


def reset_password(
    db: Session,
    *,
    identifier: str,
    reset_reference: str,
    new_password: str,
    confirm_password: str,
) -> None:
    user = db.scalar(select(User).where(User.login_identifier_hash == hash_identifier(identifier)))
    now = utcnow()
    if (
        user is None
        or not user.reset_token_hash
        or user.reset_token_used_at is not None
        or not user.reset_token_expires_at
        or user.reset_token_expires_at <= now
        or hash_token(reset_reference) != user.reset_token_hash
    ):
        raise AppError(
            code="invalid_reset_code",
            message="The reset code is invalid or has expired.",
            status_code=400,
        )

    assessment = assess_password(new_password)
    if not assessment.valid:
        raise AppError(
            code="password_policy_violation",
            message="Password does not satisfy the security policy.",
            status_code=422,
            details={"failed_requirements": assessment.failed_codes},
        )
    if new_password != confirm_password:
        raise AppError(
            code="password_mismatch", message="The passwords do not match.", status_code=422
        )

    user.password_hash = hash_password(new_password)
    user.must_change_password = False
    user.password_updated_at = now
    user.reset_token_used_at = now
    user.reset_token_hash = None
    user.reset_token_expires_at = None
    user.failed_login_attempts = 0
    user.is_locked = False
    user.locked_until = None

    sessions = db.scalars(
        select(RefreshSession).where(
            RefreshSession.user_id == user.id, RefreshSession.revoked_at.is_(None)
        )
    ).all()
    for session in sessions:
        session.revoked_at = now
        session.revoked_reason = "password_reset"

    record_audit(
        db,
        actor=user,
        action="auth.password_reset_completed",
        entity_type="user",
        entity_id=user.id,
    )
    db.commit()
