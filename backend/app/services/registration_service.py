"""Enrollment of bank-provisioned, explicitly unenrolled customer identities."""
from __future__ import annotations

import hmac
import re
import secrets
from datetime import timedelta

from sqlalchemy import or_, select, update
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.core.config import settings
from app.core.exceptions import AppError
from app.core.security import generate_opaque_token, hash_identifier, hash_password, hash_token, validate_password_or_raise
from app.integrations.otp import get_otp_provider
from app.models.banking import Account, Card
from app.models.security import AuthorizationGrant, OtpChallenge
from app.models.user import RefreshSession, User
from app.services import auth_service, security_service
from app.services.common import record_audit, utcnow


def normalize_registration_identifier(value: str) -> str:
    if not re.fullmatch(r"[0-9\s.\-]+", value):
        raise ValueError("Enter a card or account number using digits and separators only")
    digits = re.sub(r"[\s.\-]", "", value)
    if not 6 <= len(digits) <= 24:
        raise ValueError("Enter a card or account number containing 6 to 24 digits")
    return digits


def resolve_eligible_customer(db: Session, identifier: str) -> User | None:
    card = db.scalar(select(Card).where(Card.card_number_hash == hash_identifier(identifier)))
    account = db.scalar(select(Account).where(Account.account_number_hash == hash_identifier(f"acct:{identifier}")))
    legacy = db.scalar(select(User).where(User.login_identifier_hash == hash_identifier(identifier)))
    owners = {row.customer_id for row in (card, account) if row is not None}
    if legacy:
        owners.add(legacy.id)
    if len(owners) != 1 or not (card or account):
        return None
    user = db.get(User, next(iter(owners)))
    now = utcnow()
    if (not user or user.login_type != "customer" or user.enrollment_completed or not user.is_active
        or user.is_locked or (user.locked_until and user.locked_until > now)
        or not user.profile or not user.profile.identity_verified
        or not (user.profile.email or user.profile.phone)):
        return None
    if account and account.status != "active":
        return None
    if not db.scalar(select(Account.id).where(Account.customer_id == user.id, Account.status == "active").limit(1)):
        return None
    if card:
        if card.status != "active" or card.is_supplementary or (card.expiry_year, card.expiry_month) < (now.year, now.month):
            return None
        if card.account_id:
            linked = db.get(Account, card.account_id)
            if not linked or linked.customer_id != user.id or linked.status != "active":
                return None
    return user


def _otp_hash(challenge: OtpChallenge, code: str) -> str:
    return hmac.new(settings.login_identifier_pepper.encode(), f"{challenge.reference_hash}:{code}".encode(), "sha256").hexdigest()


def _issue_code(db: Session, challenge: OtpChallenge, user: User | None, reference: str) -> dict:
    now = utcnow()
    code = f"{secrets.randbelow(1000000):06d}"
    while hmac.compare_digest(challenge.otp_hash, _otp_hash(challenge, code)):
        code = f"{secrets.randbelow(1000000):06d}"
    challenge.otp_hash = _otp_hash(challenge, code)
    challenge.sent_at = now
    challenge.expires_at = now + timedelta(seconds=settings.otp_ttl_seconds)
    challenge.attempts = 0
    challenge.consumed_at = None
    # Older codes are invalidated even when another identifier of the same user was used.
    clauses = [OtpChallenge.identifier_hash == challenge.identifier_hash]
    if user:
        clauses.append(OtpChallenge.user_id == user.id)
    db.execute(update(OtpChallenge).where(or_(*clauses), OtpChallenge.id != challenge.id,
               OtpChallenge.consumed_at.is_(None)).values(consumed_at=now))
    delivery_failed = False
    if user:
        try:
            get_otp_provider().send(email=user.profile.email, phone=user.profile.phone, code=code)
        except Exception:
            # Do not leak a provider exception containing a recipient or message body.
            challenge.user_id = None
            challenge.otp_hash = hash_token(generate_opaque_token())
            delivery_failed = True
            record_audit(db, actor=None, action="otp.delivery_failed", entity_type="user", entity_id=user.id)
    db.commit()
    dev = settings.otp_provider == "development" and settings.environment in {"development", "test"}
    response = {"challenge": reference, "expires_in": settings.otp_ttl_seconds,
        "resend_after": settings.otp_resend_seconds, "contact_masked": "*** registered contact",
        "delivery": "development_no_delivery" if dev else "verification_requested",
        "message": "If eligible, verification uses the contact already registered with the bank."}
    if dev and settings.otp_dev_expose:
        response["development_code"] = code if user and not delivery_failed else None
    # Identical public response for unknown, already enrolled, and provider failure.
    return response


def start(db: Session, identifier: str, ip: str) -> dict:
    security_service.throttle(db, f"registration:ip:{ip}", 10, 600)
    security_service.throttle(db, f"registration:id:{hash_identifier(identifier)}", 4, 600)
    user = resolve_eligible_customer(db, identifier)
    if user:
        user = security_service.lock_user(db, user)
        if user.enrollment_completed:
            user = None
    clauses = [OtpChallenge.identifier_hash == hash_identifier(identifier)]
    if user:
        clauses.append(OtpChallenge.user_id == user.id)
    recent = db.scalar(select(OtpChallenge).where(or_(*clauses)).order_by(OtpChallenge.sent_at.desc()))
    if recent and (utcnow() - recent.sent_at).total_seconds() < settings.otp_resend_seconds:
        raise AppError(code="otp_cooldown", message="Please wait before requesting another code.", status_code=429,
                       details={"retry_after_seconds": settings.otp_resend_seconds})
    reference = generate_opaque_token(32)
    challenge = OtpChallenge(reference_hash=hash_token(reference), identifier_hash=hash_identifier(identifier),
        user_id=user.id if user else None, otp_hash="", sent_at=utcnow(), expires_at=utcnow())
    db.add(challenge)
    db.flush()
    return _issue_code(db, challenge, user, reference)


def _get_challenge(db: Session, reference: str) -> tuple[OtpChallenge, User | None]:
    row = db.scalar(select(OtpChallenge).where(OtpChallenge.reference_hash == hash_token(reference)))
    if not row:
        raise AppError(code="invalid_otp", message="The verification code is incorrect.", status_code=400)
    user = db.get(User, row.user_id) if row.user_id else None
    if user:
        user = security_service.lock_user(db, user)
    row = db.scalar(select(OtpChallenge).where(OtpChallenge.id == row.id).with_for_update().execution_options(populate_existing=True))
    return row, user


def resend(db: Session, reference: str, ip: str) -> dict:
    security_service.throttle(db, f"otp:resend:{ip}", 10, 600)
    row, user = _get_challenge(db, reference)
    if row.consumed_at:
        raise AppError(code="otp_used", message="This verification code is no longer usable. Start again.", status_code=409)
    if (utcnow() - row.sent_at).total_seconds() < settings.otp_resend_seconds:
        raise AppError(code="otp_cooldown", message="Please wait before requesting another code.", status_code=429,
                       details={"retry_after_seconds": settings.otp_resend_seconds})
    if user and user.enrollment_completed:
        user = None
    return _issue_code(db, row, user, reference)


def verify(db: Session, reference: str, code: str, ip: str) -> str:
    security_service.throttle(db, f"otp:verify:{ip}", 30, 600)
    row, user = _get_challenge(db, reference)
    if row.consumed_at:
        raise AppError(code="otp_used", message="This code has already been used or replaced.", status_code=409)
    if row.expires_at <= utcnow():
        raise AppError(code="otp_expired", message="This code has expired. Request another code.", status_code=400)
    if row.attempts >= settings.otp_max_attempts:
        raise AppError(code="otp_attempts_exceeded", message="Too many incorrect codes. Start registration again.", status_code=429)
    row.attempts += 1
    if not hmac.compare_digest(row.otp_hash, _otp_hash(row, code)) or not user or user.enrollment_completed:
        db.commit()
        raise AppError(code="invalid_otp", message="The verification code is incorrect.", status_code=400)
    row.consumed_at = utcnow()
    token = security_service.issue_grant(db, user, "registration")
    db.commit()
    return token


def complete(db: Session, token: str, password: str, confirmation: str, meta: dict, *, username: str):
    from app.services import username_service
    security_service.throttle(db, f"registration:complete:{meta.get('ip_address')}", 10, 600)
    grant = db.scalar(select(AuthorizationGrant).where(AuthorizationGrant.token_hash == hash_token(token)))
    if not grant:
        raise AppError(code="invalid_authorization", message="Registration authorization is invalid.", status_code=403)
    user = security_service.lock_user(db, db.get(User, grant.user_id))
    if user.enrollment_completed:
        raise AppError(code="already_enrolled", message="Enrollment is already complete. Please sign in.", status_code=409)
    validate_password_or_raise(password, confirmation)
    username = username_service.normalize_username(username)
    if not username_service.available(db, username):
        raise username_service.taken(db, username)
    try:
        with db.begin_nested():
            user.username = username
            user.username_key = username_service.username_key(username)
            db.flush()
    except IntegrityError:
        raise username_service.taken(db, username)
    security_service.consume_grant(db, user, token, "registration")
    user.password_hash = hash_password(password)
    user.password_updated_at = utcnow()
    user.enrollment_completed = True
    user.must_change_password = False
    db.execute(update(RefreshSession).where(RefreshSession.user_id == user.id, RefreshSession.revoked_at.is_(None))
               .values(revoked_at=utcnow(), revoked_reason="enrollment_completed"))
    record_audit(db, actor=user, action="auth.enrollment_completed", entity_type="user", entity_id=user.id)
    issued = auth_service._issue_full_session(db, user, remember=False, meta=meta)
    db.commit()
    return user, issued
