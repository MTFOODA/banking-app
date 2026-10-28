"""Password hashing, JWT handling and the authoritative password policy."""

from __future__ import annotations

import hashlib
import re
import secrets
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError

from app.core.config import settings

_hasher = PasswordHasher(
    time_cost=settings.password_argon2_time_cost,
    memory_cost=settings.password_argon2_memory_cost,
    parallelism=settings.password_argon2_parallelism,
    hash_len=32,
    salt_len=16,
)


def hash_password(raw_password: str) -> str:
    return _hasher.hash(raw_password)


def verify_password(raw_password: str, stored_hash: str) -> bool:
    try:
        return _hasher.verify(stored_hash, raw_password)
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False
    except Exception:  # pragma: no cover - defensive
        return False


def needs_rehash(stored_hash: str) -> bool:
    try:
        return _hasher.check_needs_rehash(stored_hash)
    except Exception:  # pragma: no cover
        return False


def normalize_identifier(value: str) -> str:
    """Canonical form for login identifiers.

    Separators (spaces, dashes, dots) are dropped so a card number or a staff
    employee number hashes identically however the customer types it. This must
    stay in sync with the login schema in `app.schemas.auth`.
    """
    return re.sub(r"[^a-z0-9]", "", (value or "").lower())


def hash_identifier(value: str) -> str:
    """Keyed SHA-256 so card numbers are never stored in plaintext.

    Lookup must be deterministic, so a keyed hash (not Argon2) is used and the
    pepper is kept server-side.
    """
    payload = f"{settings.login_identifier_pepper}:{normalize_identifier(value)}".encode()
    return hashlib.sha256(payload).hexdigest()


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def generate_opaque_token(nbytes: int = 48) -> str:
    return secrets.token_urlsafe(nbytes)


class TokenType:
    ACCESS = "access"
    FIRST_LOGIN = "first_login"


def create_access_token(
    *, user_id: str, session_id: str, roles: list[str], expires_minutes: int | None = None
) -> tuple[str, int]:
    minutes = expires_minutes or settings.access_token_minutes
    now = datetime.now(UTC)
    payload = {
        "sub": user_id,
        "sid": session_id,
        "typ": TokenType.ACCESS,
        "roles": roles,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=minutes)).timestamp()),
        "jti": secrets.token_hex(8),
    }
    token = jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    return token, minutes * 60


def create_first_login_token(*, user_id: str, session_id: str) -> tuple[str, int]:
    minutes = settings.first_login_token_minutes
    now = datetime.now(UTC)
    payload = {
        "sub": user_id,
        "sid": session_id,
        "typ": TokenType.FIRST_LOGIN,
        "roles": [],
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=minutes)).timestamp()),
        "jti": secrets.token_hex(8),
    }
    token = jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    return token, minutes * 60


def decode_token(token: str) -> dict[str, Any]:
    """Decode and verify a JWT. Raises jwt.PyJWTError on any problem."""
    return jwt.decode(
        token,
        settings.jwt_secret,
        algorithms=[settings.jwt_algorithm],
        options={"require": ["exp", "iat", "sub", "typ"]},
    )




# --------------------------------------------------------------------------
# Password policy (authoritative - mirrored in Dart for live UI feedback)
# --------------------------------------------------------------------------
PASSWORD_MIN_LENGTH = 8
PASSWORD_MAX_LENGTH = 128
SPECIAL_CHARACTERS = "!@#$%^&*()_+-=[]{};:'\",.<>/?\\|`~"
_TRIPLE_REPEAT = re.compile(r"(.)\1\1", re.DOTALL)

PASSWORD_REQUIREMENT_CODES = (
    "min_length",
    "uppercase",
    "lowercase",
    "digit",
    "special",
    "no_triple_repeat",
)


@dataclass(frozen=True)
class PasswordAssessment:
    valid: bool
    failed: tuple[str, ...]

    @property
    def failed_codes(self) -> list[str]:
        return list(self.failed)


def assess_password(password: str) -> PasswordAssessment:
    """Evaluate the exact bank password policy.

    Rules:
      1. at least 8 characters
      2. at least one uppercase ASCII letter
      3. at least one lowercase ASCII letter
      4. at least one digit
      5. at least one special character
      6. no character repeated three or more times consecutively
    """
    failed: list[str] = []
    candidate = password or ""
    if len(candidate) < PASSWORD_MIN_LENGTH or len(candidate) > PASSWORD_MAX_LENGTH:
        failed.append("min_length")
    if not re.search(r"[A-Z]", candidate):
        failed.append("uppercase")
    if not re.search(r"[a-z]", candidate):
        failed.append("lowercase")
    if not re.search(r"[0-9]", candidate):
        failed.append("digit")
    if not any(char in SPECIAL_CHARACTERS for char in candidate):
        failed.append("special")
    if _TRIPLE_REPEAT.search(candidate):
        failed.append("no_triple_repeat")
    return PasswordAssessment(valid=not failed, failed=tuple(failed))


def validate_password_or_raise(password: str, confirmation: str | None = None) -> None:
    """Raise AppError when the password (or confirmation) violates policy."""
    from app.core.exceptions import AppError

    assessment = assess_password(password)
    if not assessment.valid:
        raise AppError(
            code="password_policy_violation",
            message="Password does not satisfy the security policy.",
            status_code=422,
            details={"failed_requirements": assessment.failed_codes},
        )
    if confirmation is not None and password != confirmation:
        raise AppError(
            code="password_mismatch",
            message="The passwords do not match.",
            status_code=422,
        )

