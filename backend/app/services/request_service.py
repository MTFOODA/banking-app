"""Unified service-request lifecycle for customers and administrators."""

from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.banking import Account, Card
from app.models.enums import AccountStatus, CardStatus, RequestStatus, RequestType
from app.models.service import RequestDocument, RequestStatusHistory, ServiceRequest
from app.models.user import User
from app.services import notification_service
from app.services.common import generate_reference, record_audit, utcnow

FINAL_STATUSES = {
    RequestStatus.REJECTED,
    RequestStatus.COMPLETED,
    RequestStatus.CANCELLED,
}
CUSTOMER_ACTIONS: dict[str, list[str]] = {
    RequestStatus.PENDING_CUSTOMER_INFO: ["provide_information", "upload_document", "cancel"],
    RequestStatus.SUBMITTED: ["cancel"],
    RequestStatus.UNDER_REVIEW: ["upload_document"],
    RequestStatus.PENDING_APPROVAL: ["upload_document"],
    RequestStatus.APPROVED: ["upload_document"],
    RequestStatus.COMPLETED: ["upload_document"],
    RequestStatus.REJECTED: [],
    RequestStatus.CANCELLED: [],
    RequestStatus.PROCESSING: [],
    RequestStatus.DRAFT: ["submit", "cancel"],
}


def _parse_uuid(value: Any, field: str) -> uuid.UUID:
    try:
        return uuid.UUID(str(value))
    except (ValueError, TypeError) as exc:
        raise AppError(
            code="invalid_request_data",
            message=f"A valid {field.replace('_', ' ')} is required.",
            status_code=422,
        ) from exc


def _owned_account(db: Session, user: User, account_id: uuid.UUID) -> Account:
    account = db.scalar(
        select(Account).where(Account.id == account_id, Account.customer_id == user.id)
    )
    if account is None:
        raise AppError(code="account_not_found", message="Account not found.", status_code=404)
    return account


def _owned_card(db: Session, user: User, card_id: uuid.UUID) -> Card:
    card = db.scalar(select(Card).where(Card.id == card_id, Card.customer_id == user.id))
    if card is None:
        raise AppError(code="card_not_found", message="Card not found.", status_code=404)
    return card


def _add_history(
    db: Session,
    request: ServiceRequest,
    *,
    from_status: str | None,
    to_status: str,
    note: str | None,
    actor: User | None,
    actor_label: str | None = None,
) -> None:
    db.add(
        RequestStatusHistory(
            request_id=request.id,
            from_status=from_status,
            to_status=to_status,
            note=note,
            actor_id=actor.id if actor else None,
            actor_label=actor_label or "Bank",
        )
    )




def _validate_request(db: Session, user: User, request_type: str, form_data: dict) -> dict:
    data = dict(form_data or {})
    if request_type == RequestType.CARD_ISSUE:
        from app.services.card_catalogue import validate_issue
        _, _, data = validate_issue(db, user, data, lock=True)
    elif request_type == RequestType.ACCOUNT_OPEN:
        product_code = data.get("product_code") or data.get("account_type")
        if not product_code:
            raise AppError(
                code="invalid_request_data",
                message="Select the account product you want to open.",
                status_code=422,
            )
        data["product_code"] = str(product_code)
    elif request_type == RequestType.ACCOUNT_CLOSE:
        account = _owned_account(db, user, _parse_uuid(data.get("account_id"), "account id"))
        if account.status != AccountStatus.ACTIVE:
            raise AppError(
                code="account_not_closable",
                message="Only active accounts can be closed.",
                status_code=409,
            )
        if account.current_balance > 0:
            raise AppError(
                code="account_has_balance",
                message="Settle the account balance before requesting closure.",
                status_code=409,
                details={"current_balance": str(account.current_balance)},
            )
        data["account_id"] = str(account.id)
    elif request_type in {
        RequestType.CARD_REPLACEMENT,
        RequestType.CARD_RENEWAL,
        RequestType.CARD_CANCELLATION,
        RequestType.PIN_RESET,
        RequestType.CARD_LIMIT_INCREASE,
        RequestType.CARD_LIMIT_DECREASE,
    }:
        card = _owned_card(db, user, _parse_uuid(data.get("card_id"), "card id"))
        data["card_id"] = str(card.id)
        data["card_last4"] = card.card_last4
        if request_type in {RequestType.CARD_LIMIT_INCREASE, RequestType.CARD_LIMIT_DECREASE}:
            if not data.get("limit_type") or not data.get("requested_amount"):
                raise AppError(
                    code="invalid_request_data",
                    message="Provide the limit type and requested amount.",
                    status_code=422,
                )
    elif request_type == RequestType.SUPPLEMENTARY_CARD:
        primary = _owned_card(
            db, user, _parse_uuid(data.get("primary_card_id"), "primary card id")
        )
        if primary.is_supplementary:
            raise AppError(
                code="invalid_supplementary_primary",
                message="A supplementary card cannot sponsor another card.",
                status_code=422,
            )
        if primary.status not in {CardStatus.ACTIVE, CardStatus.FROZEN}:
            raise AppError(
                code="card_not_eligible",
                message="The selected primary card is not eligible.",
                status_code=409,
            )
        for field in ("holder_first_name", "holder_last_name", "holder_relationship"):
            if not str(data.get(field) or "").strip():
                raise AppError(
                    code="invalid_request_data",
                    message="Complete the supplementary cardholder details.",
                    status_code=422,
                )
        data["primary_card_id"] = str(primary.id)
    elif request_type == RequestType.CUSTOMER_INFO_UPDATE:
        from app.schemas.profile import ProfileUpdate
        try:
            data = ProfileUpdate(authorization_token="validation-placeholder", **data).model_dump(exclude={"authorization_token"}, exclude_none=True)
        except ValueError:
            raise AppError(code="invalid_request_data", message="Only valid email, phone and address changes are supported.", status_code=422)
        if not data:
            raise AppError(
                code="invalid_request_data",
                message="Provide the information you want to update.",
                status_code=422,
            )
    elif request_type == RequestType.INVESTMENT_PRODUCT:
        if not data.get("product_code"):
            raise AppError(
                code="invalid_request_data",
                message="Select an investment product.",
                status_code=422,
            )
    return data


def create_request(
    db: Session,
    user: User,
    *,
    request_type: str,
    form_data: dict,
    priority: str | None = None,
    submit: bool = True,
    authorization_token: str | None = None,
) -> ServiceRequest:
    data = _validate_request(db, user, request_type, form_data)
    if request_type == RequestType.CUSTOMER_INFO_UPDATE:
        from app.services import security_service
        user = security_service.lock_user(db, user)
        security_service.consume_grant(db, user, authorization_token or "", "profile_update")
        record_audit(db, actor=user, action="profile.update_requested", entity_type="customer_profile",
                     entity_id=user.profile.id, details={"fields": sorted(data)})

    duplicates = db.scalar(
        select(func.count(ServiceRequest.id)).where(
            ServiceRequest.customer_id == user.id,
            ServiceRequest.request_type == request_type,
            ServiceRequest.status.notin_([s.value for s in FINAL_STATUSES]),
        )
    )
    if duplicates:
        raise AppError(
            code="duplicate_open_request",
            message="You already have an open request of this type.",
            status_code=409,
        )

    request = ServiceRequest(
        reference=generate_reference("REQ"),
        customer_id=user.id,
        request_type=request_type,
        status=RequestStatus.SUBMITTED if submit else RequestStatus.DRAFT,
        priority=priority or "normal",
        form_data=data,
        submitted_at=utcnow() if submit else None,
    )
    db.add(request)
    db.flush()
    _add_history(
        db,
        request,
        from_status=None,
        to_status=request.status,
        note="Request submitted by the customer." if submit else "Draft created.",
        actor=user,
        actor_label="Customer",
    )
    notification_service.notify(
        db,
        customer_id=user.id,
        category="request_status",
        title_en="Request received",
        title_ar="تم استلام الطلب",
        body_en=f"Your request {request.reference} has been received and is under review.",
        body_ar=f"تم استلام طلبك رقم {request.reference} وهو قيد المراجعة.",
        related_entity_type="service_request",
        related_entity_id=request.id,
        cta_route=f"/requests/{request.id}",
    )
    record_audit(
        db,
        actor=user,
        action="request.created",
        entity_type="service_request",
        entity_id=request.id,
        details={"request_type": request_type, "reference": request.reference},
    )
    db.commit()
    db.refresh(request)
    return request



def list_requests(
    db: Session,
    user: User,
    *,
    status: str | None = None,
    request_type: str | None = None,
    page: int = 1,
    page_size: int = 20,
) -> tuple[list[ServiceRequest], int]:
    stmt = select(ServiceRequest).where(ServiceRequest.customer_id == user.id)
    if status:
        stmt = stmt.where(ServiceRequest.status == status)
    if request_type:
        stmt = stmt.where(ServiceRequest.request_type == request_type)
    total = db.scalar(select(func.count()).select_from(stmt.subquery())) or 0
    rows = db.scalars(
        stmt.order_by(ServiceRequest.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()
    return list(rows), int(total)


def get_request(db: Session, user: User, request_id: uuid.UUID) -> ServiceRequest:
    request = db.scalar(
        select(ServiceRequest).where(
            ServiceRequest.id == request_id, ServiceRequest.customer_id == user.id
        )
    )
    if request is None:
        raise AppError(code="request_not_found", message="Request not found.", status_code=404)
    return request


def add_information(
    db: Session, user: User, request_id: uuid.UUID, *, message: str, fields: dict,
    authorization_token: str | None = None,
) -> ServiceRequest:
    request = get_request(db, user, request_id)
    if request.request_type == RequestType.CUSTOMER_INFO_UPDATE and fields:
        from app.services import security_service
        fields = _validate_request(db, user, request.request_type, fields)
        user = security_service.lock_user(db, user)
        security_service.consume_grant(db, user, authorization_token or "", "profile_update")
    if request.status != RequestStatus.PENDING_CUSTOMER_INFO:
        raise AppError(
            code="request_not_awaiting_information",
            message="This request is not awaiting additional information.",
            status_code=409,
        )
    merged = dict(request.form_data or {})
    merged.update(fields or {})
    merged["customer_response"] = message
    request.form_data = merged
    previous = request.status
    request.status = RequestStatus.UNDER_REVIEW
    _add_history(
        db,
        request,
        from_status=previous,
        to_status=request.status,
        note="Customer provided the requested information.",
        actor=user,
        actor_label="Customer",
    )
    record_audit(
        db,
        actor=user,
        action="request.information_provided",
        entity_type="service_request",
        entity_id=request.id,
    )
    db.commit()
    db.refresh(request)
    return request


def cancel_request(db: Session, user: User, request_id: uuid.UUID) -> ServiceRequest:
    request = get_request(db, user, request_id)
    request = db.scalar(select(ServiceRequest).where(ServiceRequest.id == request.id)
        .with_for_update().execution_options(populate_existing=True))
    if request.status in FINAL_STATUSES:
        raise AppError(
            code="request_not_cancellable",
            message="This request can no longer be cancelled.",
            status_code=409,
        )
    previous = request.status
    request.status = RequestStatus.CANCELLED
    _add_history(
        db,
        request,
        from_status=previous,
        to_status=request.status,
        note="Cancelled by the customer.",
        actor=user,
        actor_label="Customer",
    )
    db.commit()
    db.refresh(request)
    return request


def attach_document(
    db: Session,
    user: User,
    request_id: uuid.UUID,
    *,
    filename: str,
    content_type: str,
    size_bytes: int,
    storage_path: str,
) -> RequestDocument:
    request = get_request(db, user, request_id)
    document = RequestDocument(
        request_id=request.id,
        filename=filename,
        content_type=content_type,
        size_bytes=size_bytes,
        storage_path=storage_path,
        uploaded_by=user.id,
    )
    db.add(document)
    record_audit(
        db,
        actor=user,
        action="request.document_uploaded",
        entity_type="service_request",
        entity_id=request.id,
        details={"filename": filename, "size_bytes": size_bytes},
    )
    db.commit()
    db.refresh(document)
    return document


def customer_actions(request: ServiceRequest) -> list[str]:
    return CUSTOMER_ACTIONS.get(request.status, [])



# --------------------------------------------------------------------------
# Administrator operations
# --------------------------------------------------------------------------
DECIDABLE_STATUSES = {
    RequestStatus.SUBMITTED,
    RequestStatus.UNDER_REVIEW,
    RequestStatus.PENDING_APPROVAL,
    RequestStatus.PENDING_CUSTOMER_INFO,
}


def admin_list_requests(
    db: Session,
    *,
    status: str | None = None,
    request_type: str | None = None,
    search: str | None = None,
    assigned_to: uuid.UUID | None = None,
    page: int = 1,
    page_size: int = 20,
) -> tuple[list[ServiceRequest], int]:
    stmt = select(ServiceRequest)
    if status:
        stmt = stmt.where(ServiceRequest.status == status)
    if request_type:
        stmt = stmt.where(ServiceRequest.request_type == request_type)
    if assigned_to:
        stmt = stmt.where(ServiceRequest.assigned_to == assigned_to)
    if search:
        stmt = stmt.where(ServiceRequest.reference.ilike(f"%{search.strip()}%"))
    total = db.scalar(select(func.count()).select_from(stmt.subquery())) or 0
    rows = db.scalars(
        stmt.order_by(ServiceRequest.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()
    return list(rows), int(total)


def admin_get_request(db: Session, request_id: uuid.UUID) -> ServiceRequest:
    request = db.get(ServiceRequest, request_id)
    if request is None:
        raise AppError(code="request_not_found", message="Request not found.", status_code=404)
    return request


def assign_request(
    db: Session, request: ServiceRequest, *, reviewer: User | None, actor: User
) -> ServiceRequest:
    request.assigned_to = reviewer.id if reviewer else None
    if reviewer:
        label = (
            f"{reviewer.profile.first_name_en} {reviewer.profile.last_name_en}".strip()
            if reviewer.profile
            else reviewer.login_identifier_masked
        )
    else:
        label = None
    request.assigned_label = label
    _add_history(
        db,
        request,
        from_status=request.status,
        to_status=request.status,
        note=f"Reviewer assigned: {label or 'unassigned'}.",
        actor=actor,
    )
    record_audit(
        db,
        actor=actor,
        action="request.assigned",
        entity_type="service_request",
        entity_id=request.id,
        details={"assigned_to": label},
    )
    db.commit()
    db.refresh(request)
    return request


def _ensure_decidable(request: ServiceRequest) -> None:
    if request.status not in DECIDABLE_STATUSES:
        raise AppError(
            code="request_not_decidable",
            message="This request cannot be decided in its current status.",
            status_code=409,
            details={"status": request.status},
        )


def approve_request(
    db: Session,
    request: ServiceRequest,
    *,
    actor: User,
    reason: str | None = None,
    explanation: str | None = None,
) -> ServiceRequest:
    from app.services.request_effects import apply_approval_effects

    request = db.scalar(select(ServiceRequest).where(ServiceRequest.id == request.id)
        .with_for_update().execution_options(populate_existing=True))
    _ensure_decidable(request)
    previous = request.status
    resulting_status = apply_approval_effects(db, request, actor=actor)
    request.status = resulting_status
    request.decision_reason = reason
    request.customer_explanation = explanation or "Your request has been approved."
    request.decided_at = utcnow()
    request.version = (request.version or 1) + 1
    _add_history(
        db,
        request,
        from_status=previous,
        to_status=resulting_status,
        note=explanation or reason or "Approved by the bank.",
        actor=actor,
    )
    notification_service.notify(
        db,
        customer_id=request.customer_id,
        category="request_status",
        title_en="Request approved",
        title_ar="تمت الموافقة على الطلب",
        body_en=f"Request {request.reference} has been approved.",
        body_ar=f"تمت الموافقة على الطلب رقم {request.reference}.",
        related_entity_type="service_request",
        related_entity_id=request.id,
        cta_route=f"/requests/{request.id}",
    )
    record_audit(
        db,
        actor=actor,
        action="request.approved",
        entity_type="service_request",
        entity_id=request.id,
        details={"resulting_status": resulting_status, "request_type": request.request_type},
    )
    db.commit()
    db.refresh(request)
    return request



def reject_request(
    db: Session,
    request: ServiceRequest,
    *,
    actor: User,
    reason: str,
    explanation: str | None = None,
) -> ServiceRequest:
    request = db.scalar(select(ServiceRequest).where(ServiceRequest.id == request.id)
        .with_for_update().execution_options(populate_existing=True))
    _ensure_decidable(request)
    if not reason or len(reason.strip()) < 5:
        raise AppError(
            code="rejection_reason_required",
            message="A rejection reason is required.",
            status_code=422,
        )
    previous = request.status
    request.status = RequestStatus.REJECTED
    request.decision_reason = reason
    request.customer_explanation = explanation or reason
    request.decided_at = utcnow()
    request.version = (request.version or 1) + 1
    _add_history(
        db,
        request,
        from_status=previous,
        to_status=request.status,
        note=reason,
        actor=actor,
    )
    notification_service.notify(
        db,
        customer_id=request.customer_id,
        category="request_status",
        title_en="Request rejected",
        title_ar="تم رفض الطلب",
        body_en=f"Request {request.reference} was rejected. {explanation or reason}",
        body_ar=f"تم رفض الطلب رقم {request.reference}. {explanation or reason}",
        related_entity_type="service_request",
        related_entity_id=request.id,
        cta_route=f"/requests/{request.id}",
    )
    record_audit(
        db,
        actor=actor,
        action="request.rejected",
        entity_type="service_request",
        entity_id=request.id,
        details={"reason": reason},
    )
    db.commit()
    db.refresh(request)
    return request


def request_more_information(
    db: Session,
    request: ServiceRequest,
    *,
    actor: User,
    message: str,
    required_fields: list[str] | None = None,
) -> ServiceRequest:
    if request.status in FINAL_STATUSES:
        raise AppError(
            code="request_not_actionable",
            message="This request is already closed.",
            status_code=409,
        )
    previous = request.status
    request.status = RequestStatus.PENDING_CUSTOMER_INFO
    request.form_data = {**(request.form_data or {}), "required_fields": required_fields or []}
    _add_history(
        db,
        request,
        from_status=previous,
        to_status=request.status,
        note=message,
        actor=actor,
    )
    notification_service.notify(
        db,
        customer_id=request.customer_id,
        category="request_status",
        title_en="Additional information required",
        title_ar="مطلوب معلومات إضافية",
        body_en=f"We need more information for request {request.reference}.",
        body_ar=f"نحتاج إلى معلومات إضافية للطلب رقم {request.reference}.",
        priority="high",
        related_entity_type="service_request",
        related_entity_id=request.id,
        cta_route=f"/requests/{request.id}",
    )
    record_audit(
        db,
        actor=actor,
        action="request.information_requested",
        entity_type="service_request",
        entity_id=request.id,
        details={"required_fields": required_fields or []},
    )
    db.commit()
    db.refresh(request)
    return request


def add_internal_note(
    db: Session, request: ServiceRequest, *, actor: User, note: str
) -> ServiceRequest:
    entry = RequestStatusHistory(
        request_id=request.id,
        from_status=request.status,
        to_status=request.status,
        note=f"Internal note: {note}",
        actor_id=actor.id,
        actor_label=(
            f"{actor.profile.first_name_en} {actor.profile.last_name_en}".strip()
            if actor.profile
            else actor.login_identifier_masked
        ),
        is_customer_visible=False,
    )
    db.add(entry)
    record_audit(
        db,
        actor=actor,
        action="request.note_added",
        entity_type="service_request",
        entity_id=request.id,
        details={"note_length": len(note)},
    )
    db.commit()
    db.refresh(request)
    return request




