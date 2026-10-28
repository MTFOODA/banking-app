"""Administration: reviewer assignment, information requests and notes."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import require_permissions
from app.models.user import User
from app.schemas.request import (
    AdminAssignRequest,
    AdminNoteRequest,
    AdminRequestInformationRequest,
    ServiceRequestResponse,
)
from app.services import request_service

router = APIRouter(prefix="/admin", tags=["Administration"])


@router.post(
    "/requests/{request_id}/request-information",
    response_model=ServiceRequestResponse,
    summary="Ask the customer for more information",
)
def request_information(
    request_id: uuid.UUID,
    payload: AdminRequestInformationRequest,
    user: User = Depends(require_permissions("admin.requests.request_information")),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    request = request_service.admin_get_request(db, request_id)
    updated = request_service.request_more_information(
        db,
        request,
        actor=user,
        message=payload.message,
        required_fields=payload.required_fields,
    )
    return ServiceRequestResponse.from_model(
        updated, available_actions=request_service.customer_actions(updated)
    )


@router.post(
    "/requests/{request_id}/assign",
    response_model=ServiceRequestResponse,
    summary="Assign a reviewer",
)
def assign(
    request_id: uuid.UUID,
    payload: AdminAssignRequest,
    user: User = Depends(require_permissions("admin.requests.assign")),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    request = request_service.admin_get_request(db, request_id)
    reviewer = db.get(User, payload.reviewer_id) if payload.reviewer_id else None
    updated = request_service.assign_request(db, request, reviewer=reviewer, actor=user)
    return ServiceRequestResponse.from_model(
        updated, available_actions=request_service.customer_actions(updated)
    )


@router.post(
    "/requests/{request_id}/notes",
    response_model=ServiceRequestResponse,
    summary="Add an internal note",
)
def add_note(
    request_id: uuid.UUID,
    payload: AdminNoteRequest,
    user: User = Depends(require_permissions("admin.requests.view")),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    request = request_service.admin_get_request(db, request_id)
    updated = request_service.add_internal_note(db, request, actor=user, note=payload.note)
    return ServiceRequestResponse.from_model(
        updated, available_actions=request_service.customer_actions(updated)
    )
