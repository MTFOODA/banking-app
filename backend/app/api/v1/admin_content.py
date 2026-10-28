"""Administration endpoints for content, products and offers."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import require_permissions
from app.models.user import User
from app.schemas.common import Page
from app.schemas.content import (
    AnnouncementCreate,
    AnnouncementResponse,
    AnnouncementUpdate,
    BankingProductCreate,
    BankingProductResponse,
    OfferCreate,
    OfferResponse,
)
from app.services import announcement_admin, content_catalog

router = APIRouter(prefix="/admin", tags=["Administration"])


@router.get(
    "/announcements",
    response_model=Page[AnnouncementResponse],
    summary="Announcement library",
)
def list_announcements(
    status: str | None = None,
    search: str | None = Query(None, max_length=80),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: User = Depends(require_permissions("admin.content.manage")),
    db: Session = Depends(get_db),
) -> Page[AnnouncementResponse]:
    rows, total = announcement_admin.admin_list_announcements(
        db, status=status, search=search, page=page, page_size=page_size
    )
    return Page.build(
        [AnnouncementResponse.from_model(item) for item in rows],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.post(
    "/announcements",
    response_model=AnnouncementResponse,
    status_code=201,
    summary="Create an announcement",
)
def create_announcement(
    payload: AnnouncementCreate,
    user: User = Depends(require_permissions("admin.content.manage")),
    db: Session = Depends(get_db),
) -> AnnouncementResponse:
    item = announcement_admin.create_announcement(db, user, payload.model_dump())
    return AnnouncementResponse.from_model(item)


@router.patch(
    "/announcements/{announcement_id}",
    response_model=AnnouncementResponse,
    summary="Edit an announcement",
)
def update_announcement(
    announcement_id: uuid.UUID,
    payload: AnnouncementUpdate,
    user: User = Depends(require_permissions("admin.content.manage")),
    db: Session = Depends(get_db),
) -> AnnouncementResponse:
    item = announcement_admin.get_announcement(db, announcement_id)
    updated = announcement_admin.update_announcement(
        db, user, item, payload.model_dump(exclude_unset=True)
    )
    return AnnouncementResponse.from_model(updated)


@router.post(
    "/announcements/{announcement_id}/publish",
    response_model=AnnouncementResponse,
    summary="Publish an announcement",
)
def publish_announcement(
    announcement_id: uuid.UUID,
    user: User = Depends(require_permissions("admin.content.manage")),
    db: Session = Depends(get_db),
) -> AnnouncementResponse:
    item = announcement_admin.get_announcement(db, announcement_id)
    return AnnouncementResponse.from_model(announcement_admin.publish_announcement(db, user, item))


@router.post(
    "/announcements/{announcement_id}/archive",
    response_model=AnnouncementResponse,
    summary="Archive an announcement",
)
def archive_announcement(
    announcement_id: uuid.UUID,
    user: User = Depends(require_permissions("admin.content.manage")),
    db: Session = Depends(get_db),
) -> AnnouncementResponse:
    item = announcement_admin.get_announcement(db, announcement_id)
    return AnnouncementResponse.from_model(announcement_admin.archive_announcement(db, user, item))


@router.post(
    "/announcements/{announcement_id}/duplicate",
    response_model=AnnouncementResponse,
    status_code=201,
    summary="Duplicate an announcement as a draft",
)
def duplicate_announcement(
    announcement_id: uuid.UUID,
    user: User = Depends(require_permissions("admin.content.manage")),
    db: Session = Depends(get_db),
) -> AnnouncementResponse:
    item = announcement_admin.get_announcement(db, announcement_id)
    return AnnouncementResponse.from_model(
        announcement_admin.duplicate_announcement(db, user, item)
    )


@router.get(
    "/products",
    response_model=list[BankingProductResponse],
    summary="All banking products including drafts",
)
def admin_products(
    user: User = Depends(require_permissions("admin.products.manage")),
    db: Session = Depends(get_db),
) -> list[BankingProductResponse]:
    return [
        BankingProductResponse.model_validate(item)
        for item in content_catalog.all_products(db)
    ]


@router.post(
    "/products",
    response_model=BankingProductResponse,
    status_code=201,
    summary="Create a banking product",
)
def create_product(
    payload: BankingProductCreate,
    user: User = Depends(require_permissions("admin.products.manage")),
    db: Session = Depends(get_db),
) -> BankingProductResponse:
    return BankingProductResponse.model_validate(
        content_catalog.create_product(db, user, payload.model_dump())
    )


@router.get(
    "/offers",
    response_model=list[OfferResponse],
    summary="All offers including drafts",
)
def admin_offers(
    user: User = Depends(require_permissions("admin.products.manage")),
    db: Session = Depends(get_db),
) -> list[OfferResponse]:
    return [OfferResponse.model_validate(item) for item in content_catalog.all_offers(db)]


@router.post(
    "/offers",
    response_model=OfferResponse,
    status_code=201,
    summary="Create an offer",
)
def create_offer(
    payload: OfferCreate,
    user: User = Depends(require_permissions("admin.products.manage")),
    db: Session = Depends(get_db),
) -> OfferResponse:
    return OfferResponse.model_validate(
        content_catalog.create_offer(db, user, payload.model_dump())
    )
