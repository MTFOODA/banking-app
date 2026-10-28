"""Administration endpoints: dashboard, customers, audit and reviewers."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import require_permissions
from app.models.user import User
from app.schemas.admin import (
    AdminCustomerDetail,
    AdminCustomerListItem,
    AdminDashboardResponse,
    AdminReviewerResponse,
    AuditLogResponse,
)
from app.schemas.common import Page
from app.services import admin_audit, admin_customer_detail, admin_service

router = APIRouter(prefix="/admin", tags=["Administration"])


@router.get(
    "/dashboard",
    response_model=AdminDashboardResponse,
    summary="Demo operations dashboard",
)
def dashboard(
    user: User = Depends(require_permissions("admin.dashboard.view")),
    db: Session = Depends(get_db),
) -> AdminDashboardResponse:
    return AdminDashboardResponse(**admin_service.dashboard(db))


@router.get(
    "/customers",
    response_model=Page[AdminCustomerListItem],
    summary="Search customers",
)
def customers(
    search: str | None = Query(None, max_length=80),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: User = Depends(require_permissions("admin.customers.view")),
    db: Session = Depends(get_db),
) -> Page[AdminCustomerListItem]:
    rows, total = admin_service.list_customers(
        db, search=search, page=page, page_size=page_size
    )
    return Page.build(
        [AdminCustomerListItem(**row) for row in rows],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.get(
    "/customers/{customer_id}",
    response_model=AdminCustomerDetail,
    summary="Customer profile with masked data",
)
def customer_details(
    customer_id: uuid.UUID,
    user: User = Depends(require_permissions("admin.customers.view")),
    db: Session = Depends(get_db),
) -> AdminCustomerDetail:
    return AdminCustomerDetail(**admin_customer_detail.customer_detail(db, customer_id))


@router.get(
    "/audit-logs",
    response_model=Page[AuditLogResponse],
    summary="Audit trail",
)
def audit_logs(
    action: str | None = Query(None, max_length=80),
    entity_type: str | None = Query(None, max_length=64),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    user: User = Depends(require_permissions("admin.audit.view")),
    db: Session = Depends(get_db),
) -> Page[AuditLogResponse]:
    rows, total = admin_audit.audit_logs(
        db, action=action, entity_type=entity_type, page=page, page_size=page_size
    )
    return Page.build(
        [AuditLogResponse.model_validate(row) for row in rows],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.get(
    "/reviewers",
    response_model=list[AdminReviewerResponse],
    summary="Staff available for request assignment",
)
def reviewers(
    user: User = Depends(require_permissions("admin.requests.view")),
    db: Session = Depends(get_db),
) -> list[AdminReviewerResponse]:
    result = []
    for staff in admin_audit.staff_reviewers(db):
        display = (
            f"{staff.profile.first_name_en} {staff.profile.last_name_en}".strip()
            if staff.profile
            else staff.login_identifier_masked
        )
        result.append(
            AdminReviewerResponse(id=staff.id, display_name=display, roles=staff.role_codes)
        )
    return result
