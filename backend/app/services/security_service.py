"""Shared step-up authorization. Callers own the business transaction commit."""
from __future__ import annotations

import hashlib
import json
from datetime import timedelta

from sqlalchemy import case, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import AppError
from app.core.security import generate_opaque_token, hash_token, verify_password
from app.models.security import AuthorizationGrant, SecurityThrottle
from app.models.user import User
from app.services.common import record_audit, utcnow


def fingerprint(data: dict | None = None) -> str:
    return hashlib.sha256(json.dumps(data or {}, sort_keys=True, separators=(",", ":"), default=str).encode()).hexdigest()


def throttle(db: Session, key: str, limit: int, seconds: int = 60) -> None:
    """Postgres-backed limiter shared by all workers; count failures durably."""
    now = utcnow()
    expired = SecurityThrottle.window_start <= now - timedelta(seconds=seconds)
    stmt = insert(SecurityThrottle).values(key=hash_token(key), window_start=now, attempts=1)
    count = db.execute(stmt.on_conflict_do_update(
        index_elements=[SecurityThrottle.key],
        set_={"window_start": case((expired, now), else_=SecurityThrottle.window_start),
              "attempts": case((expired, 1), else_=SecurityThrottle.attempts + 1)},
    ).returning(SecurityThrottle.attempts)).scalar_one()
    db.commit()
    if count > limit:
        raise AppError(code="rate_limited", message="Too many attempts. Please try again later.", status_code=429,
                       details={"retry_after_seconds": seconds})


def lock_user(db: Session, user: User) -> User:
    if user is None:
        raise AppError(code="invalid_authorization", message="Authorization is invalid.", status_code=403)
    user = db.scalar(select(User).where(User.id == user.id).with_for_update().execution_options(populate_existing=True))
    if not user or not user.is_active or user.is_locked or (user.locked_until and user.locked_until > utcnow()):
        raise AppError(code="account_temporarily_locked", message="This account cannot authorize operations.", status_code=423)
    return user


def reauthenticate(db: Session, user: User, password: str) -> None:
    if not verify_password(password, user.password_hash):
        from app.services.auth_service import _register_failed_attempt
        _register_failed_attempt(db, user)
        raise AppError(code="invalid_credentials", message="The current password is incorrect.", status_code=400)
    user.failed_login_attempts = 0


def issue_grant(db: Session, user: User, scope: str, binding: str | None = None) -> str:
    raw = generate_opaque_token(32)
    db.add(AuthorizationGrant(user_id=user.id, token_hash=hash_token(raw), scope=scope,
        binding=binding or fingerprint(), credential_version=hash_token(user.password_hash),
        expires_at=utcnow() + timedelta(seconds=settings.authorization_ttl_seconds)))
    record_audit(db, actor=user, action="authorization.issued", entity_type="user", entity_id=user.id,
                 details={"scope": scope})
    return raw


def consume_grant(db: Session, user: User, raw: str, scope: str, binding: str | None = None) -> AuthorizationGrant:
    grant = db.scalar(select(AuthorizationGrant).where(AuthorizationGrant.token_hash == hash_token(raw)).with_for_update())
    if (not grant or grant.user_id != user.id or grant.scope != scope
        or grant.binding != (binding or fingerprint()) or grant.credential_version != hash_token(user.password_hash)):
        raise AppError(code="invalid_authorization", message="The authorization token does not match this operation.", status_code=403)
    if grant.consumed_at:
        raise AppError(code="authorization_used", message="This authorization token has already been used.", status_code=409)
    if grant.expires_at <= utcnow():
        raise AppError(code="authorization_expired", message="The authorization token has expired. Authorize again.", status_code=403)
    grant.consumed_at = utcnow()
    return grant


def authorize_operation(db: Session, user: User, scope: str, password: str, transfer=None, investment=None) -> str:
    if scope not in {"transfer", "password_change", "profile_update", "biometric", "investment_subscribe", "investment_redeem"}:
        raise AppError(code="invalid_authorization", message="Unsupported authorization scope.", status_code=422)
    throttle(db, f"reauth:{user.id}", 10, 600)
    user = lock_user(db, user)
    reauthenticate(db, user, password)
    binding = None
    if scope.startswith('investment_'):
        from app.services import investment_service
        if investment is None or user.login_type != 'customer' or scope != f'investment_{investment.action}':
            raise AppError(code='invalid_authorization', message='A matching investment operation is required.', status_code=422)
        binding = investment_service.quote(db, user, investment)['binding']
    if scope == "transfer":
        from app.services import transfer_execution
        if transfer is None or user.login_type != "customer":
            raise AppError(code="invalid_destination", message="A customer transfer is required.", status_code=422)
        transfer_execution.quote_transfer(db, user, transfer,create_fx_quote=False)
        binding = transfer_execution.authorization_binding(db, transfer)
    token = issue_grant(db, user, scope, binding)
    db.commit()
    return token


def confirm_biometric_configuration(db: Session, user: User, token: str) -> None:
    throttle(db, f"biometric:{user.id}", 20)
    user = lock_user(db, user)
    consume_grant(db, user, token, "biometric")
    db.commit()
