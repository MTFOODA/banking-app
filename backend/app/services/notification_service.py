"""Customer notifications: creation, listing and read state."""

from __future__ import annotations

import uuid

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.service import Notification, NotificationRead
from app.models.user import User
from app.schemas.content import NotificationListResponse, NotificationResponse


def notify(
    db: Session,
    *,
    customer_id: uuid.UUID | None,
    category: str,
    title_en: str,
    title_ar: str,
    body_en: str,
    body_ar: str,
    priority: str = "normal",
    related_entity_type: str | None = None,
    related_entity_id: str | None = None,
    cta_route: str | None = None,
) -> Notification:
    item = Notification(
        customer_id=customer_id,
        category=category,
        title_en=title_en,
        title_ar=title_ar,
        body_en=body_en,
        body_ar=body_ar,
        priority=priority,
        related_entity_type=related_entity_type,
        related_entity_id=str(related_entity_id) if related_entity_id else None,
        cta_route=cta_route,
    )
    db.add(item)
    db.flush()
    return item


def list_notifications(
    db: Session,
    user: User,
    *,
    page: int,
    page_size: int,
    unread_only: bool = False,
    category: str | None = None,
) -> NotificationListResponse:
    base = (
        select(Notification)
        .where(or_(Notification.customer_id == user.id, Notification.customer_id.is_(None)))
        .order_by(Notification.created_at.desc())
    )
    if category:
        base = base.where(Notification.category == category)

    rows = db.execute(
        base.add_columns(
            select(NotificationRead.id)
            .where(
                NotificationRead.notification_id == Notification.id,
                NotificationRead.customer_id == user.id,
            )
            .exists()
            .label("is_read")
        )
    ).all()

    items: list[NotificationResponse] = []
    for notification, is_read in rows:
        if unread_only and is_read:
            continue
        items.append(
            NotificationResponse(
                id=notification.id,
                category=notification.category,
                title_en=notification.title_en,
                title_ar=notification.title_ar,
                body_en=notification.body_en,
                body_ar=notification.body_ar,
                priority=notification.priority,
                cta_route=notification.cta_route,
                related_entity_type=notification.related_entity_type,
                related_entity_id=notification.related_entity_id,
                is_read=bool(is_read),
                created_at=notification.created_at,
            )
        )

    total = len(items)
    start = max(0, (page - 1) * page_size)
    paged = items[start : start + page_size]
    unread = _unread_count(db, user)
    return NotificationListResponse(items=paged, unread_count=unread)


def _unread_count(db: Session, user: User) -> int:
    total = db.scalar(
        select(func.count(Notification.id)).where(
            or_(Notification.customer_id == user.id, Notification.customer_id.is_(None))
        )
    ) or 0
    read = db.scalar(
        select(func.count(NotificationRead.id)).where(NotificationRead.customer_id == user.id)
    ) or 0
    return max(0, int(total) - int(read))


def unread_count(db: Session, user: User) -> int:
    return _unread_count(db, user)


def mark_read(db: Session, user: User, notification_id: uuid.UUID) -> None:
    notification = db.get(Notification, notification_id)
    if notification is None or (
        notification.customer_id is not None and notification.customer_id != user.id
    ):
        raise AppError(code="notification_not_found", message="Notification not found.", status_code=404)
    existing = db.scalar(
        select(NotificationRead).where(
            NotificationRead.notification_id == notification.id,
            NotificationRead.customer_id == user.id,
        )
    )
    if existing is None:
        db.add(NotificationRead(notification_id=notification.id, customer_id=user.id))
        db.commit()


def mark_all_read(db: Session, user: User) -> int:
    rows = db.execute(
        select(Notification.id).where(
            or_(Notification.customer_id == user.id, Notification.customer_id.is_(None))
        )
    ).all()
    existing = {
        read.notification_id
        for read in db.scalars(
            select(NotificationRead).where(NotificationRead.customer_id == user.id)
        ).all()
    }
    created = 0
    for (notification_id,) in rows:
        if notification_id in existing:
            continue
        db.add(NotificationRead(notification_id=notification_id, customer_id=user.id))
        created += 1
    db.commit()
    return created
