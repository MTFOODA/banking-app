"""One settings document and immutable published branding snapshots."""
from __future__ import annotations

import uuid
from datetime import datetime
from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Integer, Uuid, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base


class BrandingPublication(Base):
    __tablename__ = "branding_publications"
    __table_args__ = (CheckConstraint("version > 0", name="branding_version_positive"),)
    version: Mapped[int] = mapped_column(Integer, primary_key=True)
    config: Mapped[dict] = mapped_column(JSONB, nullable=False)
    published_by: Mapped[uuid.UUID | None] = mapped_column(Uuid, ForeignKey("users.id", ondelete="SET NULL"))
    published_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class BrandingSettings(Base):
    __tablename__ = "branding_settings"
    __table_args__ = (
        CheckConstraint("id = 1", name="branding_singleton"),
        CheckConstraint("revision >= 0", name="branding_revision_positive"),
    )
    id: Mapped[int] = mapped_column(Integer, primary_key=True, default=1)
    revision: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    active_version: Mapped[int | None] = mapped_column(ForeignKey("branding_publications.version", ondelete="RESTRICT"))
    draft: Mapped[dict | None] = mapped_column(JSONB)
    updated_by: Mapped[uuid.UUID | None] = mapped_column(Uuid, ForeignKey("users.id", ondelete="SET NULL"))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
