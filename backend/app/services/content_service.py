"""Customer-facing announcements and featured banners."""

from __future__ import annotations

from sqlalchemy import and_, case, or_, select
from sqlalchemy.orm import Session

from app.models.content import Announcement, AnnouncementAudience
from app.models.enums import AnnouncementStatus
from app.models.user import User
from app.services.common import utcnow


def effective_status(item: Announcement) -> str:
    now = utcnow()
    if item.status == AnnouncementStatus.ARCHIVED:
        return AnnouncementStatus.ARCHIVED
    if item.expires_at and item.expires_at <= now:
        return AnnouncementStatus.EXPIRED
    if item.status == AnnouncementStatus.PUBLISHED and item.publish_at and item.publish_at > now:
        return AnnouncementStatus.SCHEDULED
    return item.status


def _audience_matches(item: Announcement, user: User | None) -> bool:
    if not item.audiences:
        return True
    for audience in item.audiences:
        if audience.audience_type == "all":
            return True
        if (
            audience.audience_type == "customer_segment"
            and user is not None
            and user.profile is not None
            and audience.audience_value == user.profile.segment
        ):
            return True
        if (
            audience.audience_type == "customer"
            and user is not None
            and audience.audience_value == str(user.id)
        ):
            return True
    return False


def public_announcements(
    db: Session,
    user: User | None,
    *,
    category: str | None = None,
    limit: int = 20,
    location: str = 'home',
    bank_code: str | None = None,
) -> list[Announcement]:
    now = utcnow()
    stmt = (
        select(Announcement)
        .where(
            Announcement.status.in_([AnnouncementStatus.PUBLISHED, AnnouncementStatus.SCHEDULED]),
            or_(Announcement.status == AnnouncementStatus.PUBLISHED, Announcement.publish_at.is_not(None)),
            or_(Announcement.publish_at.is_(None), Announcement.publish_at <= now),
            or_(Announcement.expires_at.is_(None), Announcement.expires_at > now),
            Announcement.display_location.in_([location, 'both']),
        )
        .order_by(case((Announcement.priority == 'high', 0), (Announcement.priority == 'normal', 1), else_=2),
                  Announcement.publish_at.desc().nullslast(), Announcement.created_at.desc())
        .limit(limit)
    )
    if category:
        stmt = stmt.where(Announcement.category == category)
    audience = AnnouncementAudience
    # Session affiliation overrides any public bank preference for private reads.
    effective_bank = user.profile.bank_code if user and user.profile else bank_code
    allowed = [audience.audience_type == 'all']
    if effective_bank:
        allowed.append(and_(audience.audience_type == 'bank', audience.audience_value == effective_bank))
    if user:
        allowed.append(and_(audience.audience_type == 'customer', audience.audience_value == str(user.id)))
        if user.profile:
            allowed.append(and_(audience.audience_type == 'customer_segment', audience.audience_value == user.profile.segment))
    stmt = stmt.where(or_(~Announcement.audiences.any(), Announcement.audiences.any(or_(*allowed))))
    if location == 'pre_login':
        stmt = stmt.where(~Announcement.audiences.any(audience.audience_type.notin_(['all', 'bank'])))
    return list(db.scalars(stmt).all())


def featured_banners(db: Session, user: User | None, limit: int = 5) -> list[Announcement]:
    items = public_announcements(db, user, limit=limit * 3)
    priority_rank = {"high": 0, "normal": 1, "low": 2}
    items.sort(key=lambda item: priority_rank.get(item.priority, 3))
    return items[:limit]
