"""Backend-managed marketing, product and notice content."""

from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Numeric,
    String,
    Text,
    Uuid,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, uuid_pk


class Announcement(Base, TimestampMixin):
    __tablename__ = "announcements"
    __table_args__ = (CheckConstraint("display_location IN ('home','pre_login','both')", name='announcement_display_location'),)

    id = uuid_pk()
    title_en: Mapped[str] = mapped_column(String(160))
    title_ar: Mapped[str] = mapped_column(String(160))
    body_en: Mapped[str] = mapped_column(Text)
    body_ar: Mapped[str] = mapped_column(Text)
    summary_en: Mapped[str | None] = mapped_column(String(255))
    summary_ar: Mapped[str | None] = mapped_column(String(255))
    category: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    image_url: Mapped[str | None] = mapped_column(String(400))
    priority: Mapped[str] = mapped_column(String(16), default="normal", nullable=False)
    display_location: Mapped[str] = mapped_column(String(16), default='home', server_default='home', nullable=False)
    status: Mapped[str] = mapped_column(String(16), default="draft", index=True, nullable=False)
    publish_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    cta_label_en: Mapped[str | None] = mapped_column(String(80))
    cta_label_ar: Mapped[str | None] = mapped_column(String(80))
    cta_route: Mapped[str | None] = mapped_column(String(160))
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    audiences: Mapped[list["AnnouncementAudience"]] = relationship(
        back_populates="announcement", cascade="all, delete-orphan", lazy="selectin"
    )


class AnnouncementAudience(Base):
    __tablename__ = "announcement_audiences"

    id = uuid_pk()
    announcement_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("announcements.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    audience_type: Mapped[str] = mapped_column(String(24), default="all", nullable=False)
    audience_value: Mapped[str | None] = mapped_column(String(80))

    announcement: Mapped[Announcement] = relationship(back_populates="audiences")


class BankingProduct(Base, TimestampMixin):
    __tablename__ = "banking_products"

    id = uuid_pk()
    code: Mapped[str] = mapped_column(String(40), unique=True, index=True)
    name_en: Mapped[str] = mapped_column(String(160))
    name_ar: Mapped[str] = mapped_column(String(160))
    product_type: Mapped[str] = mapped_column(String(24), index=True, nullable=False)
    summary_en: Mapped[str] = mapped_column(String(255))
    summary_ar: Mapped[str] = mapped_column(String(255))
    details_en: Mapped[str] = mapped_column(Text)
    details_ar: Mapped[str] = mapped_column(Text)
    # Descriptive text only - the demo never asserts real bank rates.
    pricing_note_en: Mapped[str | None] = mapped_column(String(255))
    pricing_note_ar: Mapped[str | None] = mapped_column(String(255))
    eligibility_en: Mapped[str | None] = mapped_column(Text)
    eligibility_ar: Mapped[str | None] = mapped_column(Text)
    image_url: Mapped[str | None] = mapped_column(String(400))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    publish_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    cta_route: Mapped[str | None] = mapped_column(String(160))


class Offer(Base, TimestampMixin):
    __tablename__ = "offers"

    id = uuid_pk()
    title_en: Mapped[str] = mapped_column(String(160))
    title_ar: Mapped[str] = mapped_column(String(160))
    description_en: Mapped[str] = mapped_column(Text)
    description_ar: Mapped[str] = mapped_column(Text)
    image_url: Mapped[str | None] = mapped_column(String(400))
    cta_route: Mapped[str | None] = mapped_column(String(160))
    status: Mapped[str] = mapped_column(String(16), default="draft", index=True, nullable=False)
    start_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    end_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    display_order: Mapped[int] = mapped_column(default=0, nullable=False)
