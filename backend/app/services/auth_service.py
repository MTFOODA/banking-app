"""Authentication, first-login onboarding and session management."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import timedelta

import jwt
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import AppError
from app.core.security import (
    TokenType,
    assess_password,
    create_access_token,
    create_first_login_token,
    decode_token,
    generate_opaque_token,
    hash_identifier,
    hash_password,
    hash_token,
    needs_rehash,
    normalize_identifier,
    verify_password,
)
from app.models.banking import Account
from app.models.enums import LoginType
from app.models.user import RefreshSession, User
from app.services.common import record_audit, utcnow
from app.services.rate_limit import check_rate_limit

GENERIC_AUTH_ERROR = "The username, card/account number or password is incorrect."


@dataclass
class IssuedSession:
    access_token: str
    refresh_token: str
    expires_in: int
    session: RefreshSession


def _client_ip(meta: dict | None) -> str | None:
    return (meta or {}).get("ip_address")


def resolve_login_user(db: Session, identifier: str) -> User | None:
    """Resolve the user for a supported login identifier.

    Supported identifiers:
      * card number (customers) / employee number (staff) — stored as
        ``users.login_identifier_hash``;
      * account number (customers) — stored as ``accounts.account_number_hash``
        using the ``acct:`` namespace.

    If the same input happens to match records belonging to two different
    users, the identifier is rejected as ambiguous rather than guessing.
    """
    normalized = normalize_identifier(identifier)
    if not normalized:
        return None

    card_user = db.scalar(
        select(User).where(User.login_identifier_hash == hash_identifier(normalized))
    )
    account = db.scalar(
        select(Account).where(
            Account.account_number_hash == hash_identifier(f"acct:{normalized}")
        )
    )
    account_user = db.get(User, account.customer_id) if account is not None else None

    username_user = db.scalar(select(User).where(User.username_key == hash_identifier(f"username:{normalized}")))
    matches = {u.id: u for u in (card_user, account_user, username_user) if u is not None}
    return next(iter(matches.values())) if len(matches) == 1 else None


def _create_refresh_session(
    db: Session,
    user: User,
    *,
    scope: str,
    remember_device: bool,
    meta: dict | None,
) -> tuple[RefreshSession, str]:
    raw_token = generate_opaque_token()
    now = utcnow()
    ttl = (
        timedelta(days=settings.refresh_token_days)
        if scope == "full"
        else timedelta(minutes=settings.first_login_token_minutes)
    )
    session = RefreshSession(
        user_id=user.id,
        token_hash=hash_token(raw_token),
        scope=scope,
        expires_at=now + ttl,
        remember_device=remember_device,
        user_agent=(meta or {}).get("user_agent"),
        ip_address=(meta or {}).get("ip_address"),
        last_used_at=now,
    )
    db.add(session)
    db.flush()
    return session, raw_token


def _issue_full_session(
    db: Session, user: User, *, remember: bool, meta: dict | None
) -> IssuedSession:
    session, refresh_token = _create_refresh_session(
        db, user, scope="full", remember_device=remember, meta=meta
    )
    access_token, expires_in = create_access_token(
        user_id=str(user.id), session_id=str(session.id), roles=user.role_codes
    )
    return IssuedSession(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=expires_in,
        session=session,
    )


def _register_failed_attempt(db: Session, user: User) -> None:
    user.failed_login_attempts = (user.failed_login_attempts or 0) + 1
    if user.failed_login_attempts >= settings.max_failed_login_attempts:
        user.is_locked = True
        user.locked_until = utcnow() + timedelta(minutes=settings.login_lock_minutes)
        user.failed_login_attempts = 0
    db.commit()


def authenticate(
    db: Session,
    *,
    identifier: str,
    password: str,
    remember_device: bool,
    meta: dict | None = None,
    bank_code: str | None = None,
) -> tuple[str, IssuedSession | None, str | None, int | None, User | None]:
    """Authenticate a customer or staff member.

    Returns (status, session|None, setup_token|None, setup_expires|None, user).
    All credential failures return a single generic error message.
    """
    check_rate_limit(
        f"login:{_client_ip(meta) or 'unknown'}:{hash_identifier(identifier)[:16]}",
        limit=settings.login_rate_limit_attempts,
    )

    user = resolve_login_user(db, identifier)
    if user is None:
        # Burn comparable time so unknown identifiers are not distinguishable.
        verify_password(password, hash_password("dummy-password-value"))
        raise AppError(code="invalid_credentials", message=GENERIC_AUTH_ERROR, status_code=401)

    user = db.scalar(select(User).where(User.id == user.id).with_for_update().execution_options(populate_existing=True))
    if not user.is_active or not user.enrollment_completed:
        raise AppError(code="invalid_credentials", message=GENERIC_AUTH_ERROR, status_code=401)

    now = utcnow()
    if (user.is_locked and user.locked_until is None) or (user.locked_until and user.locked_until > now):
        raise AppError(
            code="account_temporarily_locked",
            message="Too many failed attempts. Please try again later.",
            status_code=423,
            details={"retry_after_seconds": int((user.locked_until - now).total_seconds()) if user.locked_until else 900},
        )

    password_valid = verify_password(password, user.password_hash)
    bank_matches = bank_code is None or user.login_type == 'staff' or (user.profile is not None and user.profile.bank_code == bank_code)
    if not password_valid or not bank_matches:
        _register_failed_attempt(db, user)
        record_audit(
            db,
            actor=None,
            action="auth.login_failed",
            entity_type="user",
            entity_id=user.id,
            details={"login_type": user.login_type},
            ip_address=_client_ip(meta),
            actor_label=user.login_identifier_masked,
        )
        db.commit()
        raise AppError(code="invalid_credentials", message=GENERIC_AUTH_ERROR, status_code=401)

    # Successful credential check: clear counters and opportunistically rehash.
    user.failed_login_attempts = 0
    user.is_locked = False
    user.locked_until = None
    user.last_login_at = now
    if needs_rehash(user.password_hash):
        user.password_hash = hash_password(password)

    if user.must_change_password:
        session, _ = _create_refresh_session(
            db, user, scope="first_login", remember_device=remember_device, meta=meta
        )
        setup_jwt, setup_expires = create_first_login_token(
            user_id=str(user.id), session_id=str(session.id)
        )
        record_audit(
            db,
            actor=user,
            action="auth.first_login_required",
            entity_type="user",
            entity_id=user.id,
            ip_address=_client_ip(meta),
        )
        db.commit()
        return "password_setup_required", None, setup_jwt, setup_expires, user

    issued = _issue_full_session(db, user, remember=remember_device, meta=meta)
    record_audit(
        db,
        actor=user,
        action="auth.login_succeeded",
        entity_type="user",
        entity_id=user.id,
        ip_address=_client_ip(meta),
    )
    db.commit()
    return "authenticated", issued, None, None, user


def complete_first_login(
    db: Session,
    *,
    setup_token: str,
    new_password: str,
    confirm_password: str,
    meta: dict | None = None,
) -> IssuedSession:
    try:
        payload = decode_token(setup_token)
    except jwt.PyJWTError as exc:
        raise AppError(
            code="invalid_setup_token",
            message="Your setup session has expired. Please sign in again.",
            status_code=401,
        ) from exc

    if payload.get("typ") != TokenType.FIRST_LOGIN:
        raise AppError(
            code="invalid_setup_token",
            message="This session is not allowed to set a password.",
            status_code=403,
        )

    session = db.get(RefreshSession, payload.get("sid"))
    now = utcnow()
    if (
        session is None
        or session.revoked_at is not None
        or session.expires_at <= now
        or session.scope != "first_login"
    ):
        raise AppError(
            code="invalid_setup_token",
            message="Your setup session has expired. Please sign in again.",
            status_code=401,
        )

    user = db.scalar(select(User).where(User.id == session.user_id).with_for_update().execution_options(populate_existing=True))
    session = db.scalar(select(RefreshSession).where(RefreshSession.id == session.id).with_for_update().execution_options(populate_existing=True))
    if user is None or not user.is_active or not user.enrollment_completed or user.is_locked or not user.must_change_password or session.revoked_at:
        raise AppError(
            code="invalid_setup_token", message="Session is no longer valid.", status_code=401
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
    if verify_password(new_password, user.password_hash):
        raise AppError(
            code="password_reuse",
            message="Choose a password different from your temporary credential.",
            status_code=422,
        )

    user.password_hash = hash_password(new_password)
    user.must_change_password = False
    user.password_updated_at = now

    # The restricted first-login session is invalidated immediately.
    session.revoked_at = now
    session.revoked_reason = "password_set"

    issued = _issue_full_session(db, user, remember=session.remember_device, meta=meta)
    record_audit(
        db,
        actor=user,
        action="auth.first_login_completed",
        entity_type="user",
        entity_id=user.id,
        ip_address=_client_ip(meta),
    )
    db.commit()
    return issued


def refresh_session(db: Session, *, refresh_token: str, meta: dict | None = None) -> IssuedSession:
    token_hash = hash_token(refresh_token)
    session = db.scalar(select(RefreshSession).where(RefreshSession.token_hash == token_hash))
    now = utcnow()
    if (
        session is None
        or session.revoked_at is not None
        or session.expires_at <= now
        or session.scope != "full"
    ):
        raise AppError(
            code="invalid_refresh_token",
            message="Your session has expired. Please sign in again.",
            status_code=401,
        )

    user = db.scalar(select(User).where(User.id == session.user_id).with_for_update().execution_options(populate_existing=True))
    session = db.scalar(select(RefreshSession).where(RefreshSession.id == session.id).with_for_update().execution_options(populate_existing=True))
    if user is None or not user.is_active or not user.enrollment_completed or user.is_locked or (user.locked_until and user.locked_until > now) or session.revoked_at:
        raise AppError(
            code="invalid_refresh_token",
            message="Your session has expired. Please sign in again.",
            status_code=401,
        )
    if user.must_change_password:
        raise AppError(
            code="password_setup_required",
            message="Please complete your password setup first.",
            status_code=403,
        )

    # Rotate the refresh token: the old session is revoked on use.
    session.revoked_at = now
    session.revoked_reason = "rotated"
    issued = _issue_full_session(
        db,
        user,
        remember=session.remember_device,
        meta=meta
        or {"user_agent": session.user_agent, "ip_address": session.ip_address},
    )
    db.commit()
    return issued


def logout(
    db: Session, *, user: User, refresh_token: str | None, all_devices: bool, meta: dict | None
) -> None:
    now = utcnow()
    if all_devices:
        sessions = db.scalars(
            select(RefreshSession).where(
                RefreshSession.user_id == user.id, RefreshSession.revoked_at.is_(None)
            )
        ).all()
        for session in sessions:
            session.revoked_at = now
            session.revoked_reason = "logout_all"
    elif refresh_token:
        session = db.scalar(
            select(RefreshSession).where(
                RefreshSession.token_hash == hash_token(refresh_token),
                RefreshSession.user_id == user.id,
            )
        )
        if session and session.revoked_at is None:
            session.revoked_at = now
            session.revoked_reason = "logout"
    record_audit(
        db,
        actor=user,
        action="auth.logout",
        entity_type="user",
        entity_id=user.id,
        ip_address=_client_ip(meta),
        details={"all_devices": all_devices},
    )
    db.commit()


def login_type_for(identifier: str) -> str:
    return LoginType.STAFF if identifier.upper().startswith("EMP") else LoginType.CUSTOMER

