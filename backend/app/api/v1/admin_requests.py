"""Administration: request queue, review and decisions."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import require_permissions
from app.models.enums import LoginType
from app.models.user import CustomerProfile, User
from app.schemas.admin import (
    AdminCustomerListItem,
    AdminRequestDetail,
    AdminRequestListItem,
)
from app.schemas.common import Page
from app.schemas.request import AdminDecisionRequest, AdminRejectRequest, ServiceRequestResponse
from app.services import admin_service, request_service

router = APIRouter(prefix="/admin", tags=["Administration"])


def _customer_names(db: Session, customer_ids: set[uuid.UUID]) -> dict[uuid.UUID, str]:
    if not customer_ids:
        return {}
    rows = db.execute(
        select(User.id, CustomerProfile)
        .join(CustomerProfile, CustomerProfile.user_id == User.id)
        .where(User.id.in_(customer_ids), User.login_type == LoginType.CUSTOMER)
    ).all()
    return {
        user_id: f"{profile.first_name_en} {profile.last_name_en}".strip()
        for user_id, profile in rows
    }


def build_detail(db: Session, request) -> AdminRequestDetail:
    base = ServiceRequestResponse.from_model(
        request, available_actions=request_service.customer_actions(request)
    )
    customer = db.get(User, request.customer_id)
    customer_item = None
    if customer is not None and customer.profile is not None:
        customer_item = AdminCustomerListItem(
            **admin_service.customer_item(
                customer, customer.profile, admin_service.counts(db)
            )
        )
    return AdminRequestDetail(**base.model_dump(), customer=customer_item)


@router.get("/requests", response_model=Page[AdminRequestListItem], summary="Requests queue")
def list_requests(
    status: str | None = None,
    request_type: str | None = None,
    search: str | None = Query(None, max_length=80),
    assigned_to: uuid.UUID | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: User = Depends(require_permissions("admin.requests.view")),
    db: Session = Depends(get_db),
) -> Page[AdminRequestListItem]:
    rows, total = request_service.admin_list_requests(
        db,
        status=status,
        request_type=request_type,
        search=search,
        assigned_to=assigned_to,
        page=page,
        page_size=page_size,
    )
    names = _customer_names(db, {item.customer_id for item in rows})
    return Page.build(
        [
            AdminRequestListItem(
                id=item.id,
                reference=item.reference,
                customer_id=item.customer_id,
                customer_name=names.get(item.customer_id, "Customer"),
                request_type=item.request_type,
                status=item.status,
                priority=item.priority,
                submitted_at=item.submitted_at,
                assigned_label=item.assigned_label,
            )
            for item in rows
        ],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.get(
    "/requests/{request_id}",
    response_model=AdminRequestDetail,
    summary="Request detail for review",
)
def request_detail(
    request_id: uuid.UUID,
    user: User = Depends(require_permissions("admin.requests.view")),
    db: Session = Depends(get_db),
) -> AdminRequestDetail:
    return build_detail(db, request_service.admin_get_request(db, request_id))


@router.post(
    "/requests/{request_id}/approve",
    response_model=ServiceRequestResponse,
    summary="Approve a request",
)
def approve(
    request_id: uuid.UUID,
    payload: AdminDecisionRequest,
    user: User = Depends(require_permissions("admin.requests.decide")),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    request = request_service.admin_get_request(db, request_id)
    updated = request_service.approve_request(
        db, request, actor=user, reason=payload.reason, explanation=payload.customer_explanation
    )
    return ServiceRequestResponse.from_model(
        updated, available_actions=request_service.customer_actions(updated)
    )


@router.post(
    "/requests/{request_id}/reject",
    response_model=ServiceRequestResponse,
    summary="Reject a request with a reason",
)
def reject(
    request_id: uuid.UUID,
    payload: AdminRejectRequest,
    user: User = Depends(require_permissions("admin.requests.decide")),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    request = request_service.admin_get_request(db, request_id)
    updated = request_service.reject_request(
        db,
        request,
        actor=user,
        reason=payload.reason,
        explanation=payload.customer_explanation,
    )
    return ServiceRequestResponse.from_model(
        updated, available_actions=request_service.customer_actions(updated)
    )

