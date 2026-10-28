"""Announcement CMS operations for content managers."""

from __future__ import annotations

import uuid

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.content import Announcement, AnnouncementAudience
from app.models.enums import AnnouncementStatus
from app.models.user import User
from app.services.common import record_audit, utcnow


def admin_list_announcements(
    db: Session,
    *,
    status: str | None = None,
    search: str | None = None,
    page: int = 1,
    page_size: int = 20,
) -> tuple[list[Announcement], int]:
    stmt = select(Announcement)
    if status:
        stmt = stmt.where(Announcement.status == status)
    if search:
        pattern = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(Announcement.title_en.ilike(pattern), Announcement.title_ar.ilike(pattern))
        )
    total = db.scalar(select(func.count()).select_from(stmt.subquery())) or 0
    rows = db.scalars(
        stmt.order_by(Announcement.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()
    return list(rows), int(total)


def get_announcement(db: Session, announcement_id: uuid.UUID) -> Announcement:
    item = db.scalar(select(Announcement).where(Announcement.id == announcement_id)
        .with_for_update().execution_options(populate_existing=True))
    if item is None:
        raise AppError(
            code="announcement_not_found", message="Announcement not found.", status_code=404
        )
    return item


def _validate_public_location(location, audiences):
    if location not in {'home', 'pre_login', 'both'}:
        raise AppError(code='invalid_announcement_location', message='Choose a valid display location.', status_code=422)
    if location != 'home' and any(kind != 'all' for kind in audiences):
        raise AppError(code='private_announcement_not_public',
            message='Before-login announcements must be addressed to everyone.', status_code=422)


def create_announcement(db: Session, actor: User, payload: dict) -> Announcement:
    data = dict(payload)
    audience_type = data.pop("audience_type", "all")
    audience_value = data.pop("audience_value", None)
    status = data.pop("status", AnnouncementStatus.DRAFT)
    _validate_public_location(data.get('display_location', 'home'), [audience_type])
    if status == AnnouncementStatus.PUBLISHED:
        data.setdefault("published_at", utcnow())
    item = Announcement(created_by=actor.id, **data, status=status)
    item.audiences = [
        AnnouncementAudience(audience_type=audience_type, audience_value=audience_value)
    ]
    db.add(item)
    db.flush()
    record_audit(
        db,
        actor=actor,
        action="announcement.created",
        entity_type="announcement",
        entity_id=item.id,
        details={"category": item.category, "status": status},
    )
    db.commit()
    db.refresh(item)
    return item


def update_announcement(
    db: Session, actor: User, item: Announcement, payload: dict
) -> Announcement:
    data = dict(payload)
    audience_type = data.pop("audience_type", None)
    audience_value = data.pop("audience_value", None)
    _validate_public_location(data.get('display_location', item.display_location),
        [audience_type] if audience_type else [a.audience_type for a in item.audiences])
    for field, value in data.items():
        if hasattr(item, field):
            setattr(item, field, value)
    if audience_type:
        item.audiences = [
            AnnouncementAudience(audience_type=audience_type, audience_value=audience_value)
        ]
    record_audit(
        db,
        actor=actor,
        action="announcement.updated",
        entity_type="announcement",
        entity_id=item.id,
        details={"fields": sorted(data.keys())},
    )
    db.commit()
    db.refresh(item)
    return item


def publish_announcement(db: Session, actor: User, item: Announcement) -> Announcement:
    _validate_public_location(item.display_location, [a.audience_type for a in item.audiences])
    item.status = AnnouncementStatus.PUBLISHED
    item.published_at = utcnow()
    record_audit(
        db,
        actor=actor,
        action="announcement.published",
        entity_type="announcement",
        entity_id=item.id,
    )
    db.commit()
    db.refresh(item)
    return item


def archive_announcement(db: Session, actor: User, item: Announcement) -> Announcement:
    item.status = AnnouncementStatus.ARCHIVED
    record_audit(
        db,
        actor=actor,
        action="announcement.archived",
        entity_type="announcement",
        entity_id=item.id,
    )
    db.commit()
    db.refresh(item)
    return item


def duplicate_announcement(db: Session, actor: User, item: Announcement) -> Announcement:
    clone = Announcement(
        title_en=f"{item.title_en} (copy)",
        title_ar=f"{item.title_ar} (نسخة)",
        body_en=item.body_en,
        body_ar=item.body_ar,
        summary_en=item.summary_en,
        summary_ar=item.summary_ar,
        category=item.category,
        image_url=item.image_url,
        priority=item.priority,
        display_location=item.display_location,
        status=AnnouncementStatus.DRAFT,
        cta_label_en=item.cta_label_en,
        cta_label_ar=item.cta_label_ar,
        cta_route=item.cta_route,
        created_by=actor.id,
    )
    clone.audiences = [
        AnnouncementAudience(audience_type=a.audience_type, audience_value=a.audience_value)
        for a in item.audiences
    ]
    db.add(clone)
    db.flush()
    record_audit(
        db,
        actor=actor,
        action="announcement.duplicated",
        entity_type="announcement",
        entity_id=clone.id,
    )
    db.commit()
    db.refresh(clone)
    return clone
