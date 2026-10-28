"""Audit trail queries and staff directory for reviewer assignment."""

from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.enums import LoginType
from app.models.user import AuditLog, User


def audit_logs(
    db: Session,
    *,
    action: str | None = None,
    entity_type: str | None = None,
    page: int = 1,
    page_size: int = 50,
) -> tuple[list[AuditLog], int]:
    stmt = select(AuditLog)
    if action:
        stmt = stmt.where(AuditLog.action.ilike(f"%{action}%"))
    if entity_type:
        stmt = stmt.where(AuditLog.entity_type == entity_type)
    total = db.scalar(select(func.count()).select_from(stmt.subquery())) or 0
    rows = db.scalars(
        stmt.order_by(AuditLog.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()
    return list(rows), int(total)


def staff_reviewers(db: Session) -> list[User]:
    return list(
        db.scalars(
            select(User)
            .where(User.login_type == LoginType.STAFF, User.is_active.is_(True))
            .order_by(User.created_at)
        ).all()
    )
