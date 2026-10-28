"""Announcements, banking products and offers for customers."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.exceptions import AppError
from app.dependencies.auth import get_current_customer
from app.models.content import Announcement
from app.models.user import User
from app.schemas.content import (
    AnnouncementResponse,
    PublicAnnouncementResponse,
    BankingProductResponse,
    FeaturedBannerResponse,
    OfferResponse,
)
from app.services import content_catalog, content_service

router = APIRouter(tags=["Discover"])


@router.get('/public/announcements', response_model=list[PublicAnnouncementResponse], summary='Public notices before sign-in')
def pre_login_announcements(limit: int = Query(20, ge=1, le=50), db: Session = Depends(get_db)):
    items = content_service.public_announcements(db, None, limit=limit, location='pre_login')
    return [PublicAnnouncementResponse.model_validate(item) for item in items]


@router.get(
    "/announcements", response_model=list[AnnouncementResponse], summary="Published announcements"
)
def announcements(
    category: str | None = None,
    limit: int = Query(20, ge=1, le=50),
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> list[AnnouncementResponse]:
    items = content_service.public_announcements(db, user, category=category, limit=limit)
    return [AnnouncementResponse.from_model(item) for item in items]


@router.get("/announcements/{announcement_id}", response_model=AnnouncementResponse)
def announcement_details(
    announcement_id: uuid.UUID,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> AnnouncementResponse:
    item = db.get(Announcement, announcement_id)
    visible = content_service.public_announcements(db, user, limit=100)
    if item is None or item not in visible:
        raise AppError(
            code="announcement_not_found", message="Announcement not found.", status_code=404
        )
    return AnnouncementResponse.from_model(item)


@router.get("/banners", response_model=list[FeaturedBannerResponse], summary="Home banners")
def banners(
    user: User = Depends(get_current_customer), db: Session = Depends(get_db)
) -> list[FeaturedBannerResponse]:
    return [
        FeaturedBannerResponse(
            id=item.id,
            title_en=item.title_en,
            title_ar=item.title_ar,
            body_en=item.summary_en or item.body_en[:160],
            body_ar=item.summary_ar or item.body_ar[:160],
            category=item.category,
            image_url=item.image_url,
            cta_label_en=item.cta_label_en,
            cta_label_ar=item.cta_label_ar,
            cta_route=item.cta_route,
        )
        for item in content_service.featured_banners(db, user)
    ]


@router.get("/products", response_model=list[BankingProductResponse], summary="Banking products")
def products(
    user: User = Depends(get_current_customer), db: Session = Depends(get_db)
) -> list[BankingProductResponse]:
    return [
        BankingProductResponse.model_validate(item) for item in content_catalog.public_products(db)
    ]


@router.get("/offers", response_model=list[OfferResponse], summary="Current offers")
def offers(
    user: User = Depends(get_current_customer), db: Session = Depends(get_db)
) -> list[OfferResponse]:
    return [OfferResponse.model_validate(item) for item in content_catalog.public_offers(db)]
