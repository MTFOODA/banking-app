"""Shared service helpers: references, money rounding, audit and pagination."""

from __future__ import annotations

import secrets
import string
from datetime import UTC, datetime
from decimal import ROUND_HALF_UP, Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.user import AuditLog, User

REFERENCE_ALPHABET = string.ascii_uppercase + string.digits


def utcnow() -> datetime:
    return datetime.now(UTC)


def quantize_money(value: Decimal | int | float | str) -> Decimal:
    return Decimal(str(value)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def generate_reference(prefix: str) -> str:
    """Human-readable, non-sequential reference (e.g. TRF-2026-7QK4M2)."""
    suffix = "".join(secrets.choice(REFERENCE_ALPHABET) for _ in range(6))
    return f"{prefix}-{utcnow().year}-{suffix}"


def record_audit(
    db: Session,
    *,
    actor: User | None,
    action: str,
    entity_type: str,
    entity_id: str | None = None,
    details: dict | None = None,
    ip_address: str | None = None,
    actor_label: str | None = None,
) -> AuditLog:
    label = actor_label
    if label is None and actor is not None:
        if actor.profile:
            label = f"{actor.profile.first_name_en} {actor.profile.last_name_en}".strip()
        else:
            label = actor.login_identifier_masked
    entry = AuditLog(
        actor_id=actor.id if actor is not None else None,
        actor_label=label,
        action=action,
        entity_type=entity_type,
        entity_id=str(entity_id) if entity_id is not None else None,
        details=details or {},
        ip_address=ip_address,
        created_at=utcnow(),
    )
    db.add(entry)
    return entry


def count_query(db: Session, stmt) -> int:
    return int(db.scalar(select(func.count()).select_from(stmt.subquery())) or 0)


def clamp_page(page: int, page_size: int) -> tuple[int, int]:
    safe_page = max(1, page)
    safe_size = min(max(1, page_size), 100)
    return safe_page, safe_size
