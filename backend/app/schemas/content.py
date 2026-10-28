"""Notification, announcement, product and offer schemas (bilingual)."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class NotificationResponse(BaseModel):
    id: uuid.UUID
    category: str
    title_en: str
    title_ar: str
    body_en: str
    body_ar: str
    priority: str
    cta_route: str | None = None
    related_entity_type: str | None = None
    related_entity_id: str | None = None
    is_read: bool
    created_at: datetime


class NotificationListResponse(BaseModel):
    items: list[NotificationResponse]
    unread_count: int


class AnnouncementAudienceResponse(ORMModel):
    audience_type: str
    audience_value: str | None = None


class PublicAnnouncementResponse(ORMModel):
    id: uuid.UUID
    title_en: str
    title_ar: str
    body_en: str
    body_ar: str
    category: str
    priority: str
    publish_at: datetime | None = None
    expires_at: datetime | None = None


class AnnouncementResponse(BaseModel):
    id: uuid.UUID
    title_en: str
    title_ar: str
    body_en: str
    body_ar: str
    summary_en: str | None = None
    summary_ar: str | None = None
    category: str
    image_url: str | None = None
    priority: str
    display_location: str = 'home'
    status: str
    publish_at: datetime | None = None
    expires_at: datetime | None = None
    cta_label_en: str | None = None
    cta_label_ar: str | None = None
    cta_route: str | None = None
    audiences: list[AnnouncementAudienceResponse] = Field(default_factory=list)

    @classmethod
    def from_model(cls, item):
        return cls(
            id=item.id,
            title_en=item.title_en,
            title_ar=item.title_ar,
            body_en=item.body_en,
            body_ar=item.body_ar,
            summary_en=item.summary_en,
            summary_ar=item.summary_ar,
            category=item.category,
            image_url=item.image_url,
            priority=item.priority,
            display_location=item.display_location,
            status=item.status,
            publish_at=item.publish_at,
            expires_at=item.expires_at,
            cta_label_en=item.cta_label_en,
            cta_label_ar=item.cta_label_ar,
            cta_route=item.cta_route,
            audiences=[
                AnnouncementAudienceResponse(
                    audience_type=a.audience_type, audience_value=a.audience_value
                )
                for a in item.audiences
            ],
        )


class AnnouncementCreate(BaseModel):
    display_location: str = Field(default='home', pattern='^(home|pre_login|both)$')
    title_en: str = Field(min_length=3, max_length=160)
    title_ar: str = Field(min_length=3, max_length=160)
    body_en: str = Field(min_length=3)
    body_ar: str = Field(min_length=3)
    summary_en: str | None = Field(default=None, max_length=255)
    summary_ar: str | None = Field(default=None, max_length=255)
    category: str = Field(default="announcement")
    image_url: str | None = Field(default=None, max_length=400)
    priority: str = Field(default="normal", pattern="^(low|normal|high)$")
    publish_at: datetime | None = None
    expires_at: datetime | None = None
    cta_label_en: str | None = Field(default=None, max_length=80)
    cta_label_ar: str | None = Field(default=None, max_length=80)
    cta_route: str | None = Field(default=None, max_length=160)
    audience_type: str = Field(default="all", pattern="^(all|customer_segment)$")
    audience_value: str | None = Field(default=None, max_length=80)
    status: str = Field(default="draft", pattern="^(draft|scheduled|published)$")


class AnnouncementUpdate(BaseModel):
    display_location: str | None = Field(default=None, pattern='^(home|pre_login|both)$')
    title_en: str | None = Field(default=None, min_length=3, max_length=160)
    title_ar: str | None = Field(default=None, min_length=3, max_length=160)
    body_en: str | None = Field(default=None, min_length=3)
    body_ar: str | None = Field(default=None, min_length=3)
    summary_en: str | None = Field(default=None, max_length=255)
    summary_ar: str | None = Field(default=None, max_length=255)
    category: str | None = None
    image_url: str | None = Field(default=None, max_length=400)
    priority: str | None = Field(default=None, pattern="^(low|normal|high)$")
    publish_at: datetime | None = None
    expires_at: datetime | None = None
    cta_label_en: str | None = Field(default=None, max_length=80)
    cta_label_ar: str | None = Field(default=None, max_length=80)
    cta_route: str | None = Field(default=None, max_length=160)
    audience_type: str | None = Field(default=None, pattern="^(all|customer_segment)$")
    audience_value: str | None = Field(default=None, max_length=80)
    status: str | None = Field(default=None, pattern="^(draft|scheduled|published|archived)$")



class BankingProductResponse(ORMModel):
    id: uuid.UUID
    code: str
    name_en: str
    name_ar: str
    product_type: str
    summary_en: str
    summary_ar: str
    details_en: str
    details_ar: str
    pricing_note_en: str | None = None
    pricing_note_ar: str | None = None
    eligibility_en: str | None = None
    eligibility_ar: str | None = None
    image_url: str | None = None
    is_active: bool
    publish_at: datetime | None = None
    expires_at: datetime | None = None
    cta_route: str | None = None


class BankingProductCreate(BaseModel):
    code: str = Field(min_length=2, max_length=40)
    name_en: str = Field(min_length=2, max_length=160)
    name_ar: str = Field(min_length=2, max_length=160)
    product_type: str = Field(
        default="investment", pattern="^(investment|savings|certificate|financing)$"
    )
    summary_en: str = Field(min_length=3, max_length=255)
    summary_ar: str = Field(min_length=3, max_length=255)
    details_en: str = Field(min_length=3)
    details_ar: str = Field(min_length=3)
    pricing_note_en: str | None = Field(default=None, max_length=255)
    pricing_note_ar: str | None = Field(default=None, max_length=255)
    eligibility_en: str | None = None
    eligibility_ar: str | None = None
    image_url: str | None = Field(default=None, max_length=400)
    is_active: bool = True
    publish_at: datetime | None = None
    expires_at: datetime | None = None
    cta_route: str | None = Field(default=None, max_length=160)


class OfferResponse(ORMModel):
    id: uuid.UUID
    title_en: str
    title_ar: str
    description_en: str
    description_ar: str
    image_url: str | None = None
    cta_route: str | None = None
    status: str
    start_at: datetime | None = None
    end_at: datetime | None = None
    is_featured: bool
    display_order: int


class OfferCreate(BaseModel):
    title_en: str = Field(min_length=3, max_length=160)
    title_ar: str = Field(min_length=3, max_length=160)
    description_en: str = Field(min_length=3)
    description_ar: str = Field(min_length=3)
    image_url: str | None = Field(default=None, max_length=400)
    cta_route: str | None = Field(default=None, max_length=160)
    status: str = Field(default="draft", pattern="^(draft|published|archived)$")
    start_at: datetime | None = None
    end_at: datetime | None = None
    is_featured: bool = False
    display_order: int = 0


class FeaturedBannerResponse(BaseModel):
    id: uuid.UUID
    title_en: str
    title_ar: str
    body_en: str
    body_ar: str
    category: str
    image_url: str | None = None
    cta_label_en: str | None = None
    cta_label_ar: str | None = None
    cta_route: str | None = None
