"""Usernames share the existing authentication identity, never a second account."""
import re
import secrets

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.core.security import hash_identifier, hash_token
from app.models.security import AuthorizationGrant
from app.models.user import User
from app.services.common import utcnow
from app.services import security_service


def normalize_username(value: str) -> str:
    value = value.strip().lower()
    if not re.fullmatch(r"[a-z][a-z0-9]{2,29}", value):
        raise AppError(code="invalid_username", message="Use 3–30 English letters and digits only, starting with a letter.", status_code=422)
    if value in {'admin', 'administrator', 'support', 'faisalbank', 'root', 'system'}:
        raise AppError(code="invalid_username", message="Choose a different username.", status_code=422)
    return value


def username_key(value: str) -> str:
    return hash_identifier(f"username:{value}")


def available(db: Session, value: str) -> bool:
    return db.scalar(select(User.id).where(or_(User.username_key == username_key(value),
        User.login_identifier_hash == hash_identifier(value))).limit(1)) is None


def suggestions(db: Session, value: str) -> list[str]:
    base = re.sub(r'[^a-z0-9]', '', value.lower())[:23] or 'customer'
    if not base[0].isalpha():
        base = 'user' + base[:19]
    result = []
    for _ in range(64):
        candidate = f"{base}{secrets.randbelow(900000) + 100000}"
        if candidate not in result and available(db, candidate):
            result.append(candidate)
        if len(result) == 3:
            return result
    raise AppError(code="username_suggestions_unavailable", message="Please choose another username.", status_code=503)


def registration_user(db: Session, token: str) -> User:
    grant = db.scalar(select(AuthorizationGrant).where(AuthorizationGrant.token_hash == hash_token(token)))
    if not grant or grant.scope != 'registration' or grant.consumed_at or grant.expires_at <= utcnow():
        raise AppError(code="invalid_authorization", message="A valid registration authorization is required.", status_code=403)
    user = db.get(User, grant.user_id)
    if (not user or user.enrollment_completed or not user.is_active or user.is_locked
        or (user.locked_until and user.locked_until > utcnow())
        or grant.credential_version != hash_token(user.password_hash)):
        raise AppError(code="invalid_authorization", message="Registration authorization is invalid.", status_code=403)
    return user


def check(db: Session, token: str, value: str, ip: str) -> dict:
    user = registration_user(db, token)
    security_service.throttle(db, f'username:{user.id}:{ip}', 40, 600)
    value = normalize_username(value)
    free = available(db, value)
    return {'username': value, 'available': free, 'suggestions': [] if free else suggestions(db, value)}


def taken(db: Session, value: str) -> AppError:
    return AppError(code='username_taken', message='This username is already in use. Choose another.',
        status_code=409, details={'suggestions': suggestions(db, value)})
