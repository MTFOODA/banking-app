"""Administrative reporting: dashboard and customer directory."""

from __future__ import annotations

from collections import Counter

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.models.banking import Account, Card
from app.models.content import Announcement
from app.models.enums import AccountStatus, AnnouncementCategory, LoginType, RequestStatus
from app.models.service import ServiceRequest
from app.models.user import AuditLog, CustomerProfile, User
from app.services.common import utcnow

PENDING_STATUSES = [
    RequestStatus.SUBMITTED,
    RequestStatus.UNDER_REVIEW,
    RequestStatus.PENDING_APPROVAL,
    RequestStatus.PENDING_CUSTOMER_INFO,
]


def dashboard(db: Session) -> dict:
    customers_count = (
        db.scalar(select(func.count(User.id)).where(User.login_type == LoginType.CUSTOMER)) or 0
    )
    active_accounts = (
        db.scalar(select(func.count(Account.id)).where(Account.status == AccountStatus.ACTIVE))
        or 0
    )
    cards_by_status = {
        str(status): int(count)
        for status, count in db.execute(
            select(Card.status, func.count(Card.id)).group_by(Card.status)
        ).all()
    }
    requests_by_status = {
        str(status): int(count)
        for status, count in db.execute(
            select(ServiceRequest.status, func.count(ServiceRequest.id)).group_by(
                ServiceRequest.status
            )
        ).all()
    }
    pending_requests = int(
        db.scalar(
            select(func.count(ServiceRequest.id)).where(
                ServiceRequest.status.in_([s.value for s in PENDING_STATUSES])
            )
        )
        or 0
    )
    published_announcements = int(
        db.scalar(select(func.count(Announcement.id)).where(Announcement.status == "published"))
        or 0
    )
    scheduled_maintenance = int(
        db.scalar(
            select(func.count(Announcement.id)).where(
                Announcement.category.in_(
                    [
                        AnnouncementCategory.MAINTENANCE,
                        AnnouncementCategory.SERVICE_INTERRUPTION,
                    ]
                ),
                Announcement.status.in_(["published", "scheduled"]),
            )
        )
        or 0
    )
    recent = db.scalars(select(AuditLog).order_by(AuditLog.created_at.desc()).limit(10)).all()
    return {
        "demo_data": True,
        "customers_count": int(customers_count),
        "active_accounts": int(active_accounts),
        "cards_by_status": cards_by_status,
        "requests_by_status": requests_by_status,
        "pending_requests": pending_requests,
        "published_announcements": published_announcements,
        "scheduled_maintenance": scheduled_maintenance,
        "recent_actions": recent,
        "generated_at": utcnow(),
    }


def counts(db: Session) -> tuple[Counter, Counter, Counter]:
    accounts = Counter(
        customer_id
        for (customer_id,) in db.execute(
            select(Account.customer_id).where(Account.status != AccountStatus.CLOSED)
        ).all()
    )
    cards = Counter(
        customer_id
        for (customer_id,) in db.execute(
            select(Card.customer_id).where(Card.status != "cancelled")
        ).all()
    )
    requests = Counter(
        customer_id
        for (customer_id,) in db.execute(
            select(ServiceRequest.customer_id).where(
                ServiceRequest.status.notin_(
                    [
                        RequestStatus.REJECTED.value,
                        RequestStatus.CANCELLED.value,
                        RequestStatus.COMPLETED.value,
                    ]
                )
            )
        ).all()
    )
    return accounts, cards, requests


def customer_item(user: User, profile: CustomerProfile, aggregates) -> dict:
    accounts, cards, requests = aggregates
    return {
        "id": user.id,
        "customer_number": profile.customer_number,
        "name_en": f"{profile.first_name_en} {profile.last_name_en}".strip(),
        "name_ar": f"{profile.first_name_ar} {profile.last_name_ar}".strip(),
        "email": profile.email,
        "phone": profile.phone,
        "segment": profile.segment,
        "identity_verified": profile.identity_verified,
        "is_active": user.is_active,
        "must_change_password": user.must_change_password,
        "accounts_count": accounts.get(user.id, 0),
        "cards_count": cards.get(user.id, 0),
        "open_requests": requests.get(user.id, 0),
        "created_at": user.created_at,
    }


def list_customers(
    db: Session, *, search: str | None = None, page: int = 1, page_size: int = 20
) -> tuple[list[dict], int]:
    stmt = (
        select(User, CustomerProfile)
        .join(CustomerProfile, CustomerProfile.user_id == User.id)
        .where(User.login_type == LoginType.CUSTOMER)
    )
    if search:
        pattern = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                CustomerProfile.first_name_en.ilike(pattern),
                CustomerProfile.last_name_en.ilike(pattern),
                CustomerProfile.first_name_ar.ilike(pattern),
                CustomerProfile.last_name_ar.ilike(pattern),
                CustomerProfile.customer_number.ilike(pattern),
                CustomerProfile.email.ilike(pattern),
                CustomerProfile.phone.ilike(pattern),
            )
        )
    total = db.scalar(select(func.count()).select_from(stmt.subquery())) or 0
    rows = db.execute(
        stmt.order_by(CustomerProfile.customer_number)
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()
    aggregates = counts(db)
    return [customer_item(user, profile, aggregates) for user, profile in rows], int(total)
