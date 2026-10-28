"""Notification endpoints."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_customer
from app.models.user import User
from app.schemas.common import MessageResponse
from app.schemas.content import NotificationListResponse
from app.services import notification_service

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("", response_model=NotificationListResponse, summary="List notifications")
def list_notifications(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    unread_only: bool = False,
    category: str | None = None,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> NotificationListResponse:
    return notification_service.list_notifications(
        db, user, page=page, page_size=page_size, unread_only=unread_only, category=category
    )


@router.post(
    "/{notification_id}/read", response_model=MessageResponse, summary="Mark one notification read"
)
def mark_read(
    notification_id: uuid.UUID,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> MessageResponse:
    notification_service.mark_read(db, user, notification_id)
    return MessageResponse(message="Notification marked as read")


@router.post("/read-all", response_model=MessageResponse, summary="Mark all notifications read")
def mark_all_read(
    user: User = Depends(get_current_customer), db: Session = Depends(get_db)
) -> MessageResponse:
    count = notification_service.mark_all_read(db, user)
    return MessageResponse(message=f"{count} notifications marked as read")
