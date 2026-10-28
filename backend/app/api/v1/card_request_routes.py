"""Card request flows (replacement, limits, supplementary, cancellation)."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_customer
from app.models.user import User
from app.schemas.card import (
    CardRequestCreate,
    LimitChangeRequestCreate,
    ReplacementRequestCreate,
    SupplementaryCardRequestCreate,
)
from app.schemas.request import ServiceRequestResponse
from app.services import card_requests, request_service, transaction_service

router = APIRouter(prefix="/cards", tags=["Card requests"])


def _response(request) -> ServiceRequestResponse:
    return ServiceRequestResponse.from_model(
        request, available_actions=request_service.customer_actions(request)
    )


@router.post(
    "/requests",
    response_model=ServiceRequestResponse,
    status_code=201,
    summary="Create a generic card request",
)
def create_card_request(
    payload: CardRequestCreate,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    form_data = dict(payload.form_data)
    if payload.card_id:
        form_data["card_id"] = str(payload.card_id)
    if payload.notes:
        form_data["notes"] = payload.notes
    request = request_service.create_request(
        db, user, request_type=payload.request_type, form_data=form_data
    )
    return _response(request)


@router.post(
    "/{card_id}/replacement-requests",
    response_model=ServiceRequestResponse,
    status_code=201,
    summary="Request a replacement card",
)
def replacement_request(
    card_id: uuid.UUID,
    payload: ReplacementRequestCreate,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    request = card_requests.request_replacement(
        db,
        user,
        card_id=card_id,
        reason=payload.reason,
        delivery_branch=payload.delivery_branch,
        urgent=payload.urgent,
    )
    return _response(request)


@router.post(
    "/{card_id}/limit-requests",
    response_model=ServiceRequestResponse,
    status_code=201,
    summary="Request a card limit change",
)
def limit_request(
    card_id: uuid.UUID,
    payload: LimitChangeRequestCreate,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    request = card_requests.request_limit_change(
        db,
        user,
        card_id=card_id,
        limit_type=payload.limit_type,
        requested_amount=payload.requested_amount,
        reason=payload.reason,
        increase=True,
    )
    return _response(request)


@router.post(
    "/{card_id}/supplementary-requests",
    response_model=ServiceRequestResponse,
    status_code=201,
    summary="Request a supplementary card",
)
def supplementary_request(
    card_id: uuid.UUID,
    payload: SupplementaryCardRequestCreate,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    request = card_requests.request_supplementary(
        db,
        user,
        primary_card_id=card_id,
        holder_first_name=payload.holder_first_name,
        holder_last_name=payload.holder_last_name,
        holder_relationship=payload.holder_relationship,
        holder_national_id=payload.holder_national_id,
        holder_phone=payload.holder_phone,
        card_product_code=payload.card_product_code,
        spending_limit=payload.spending_limit,
        restrictions=payload.restrictions,
    )
    return _response(request)


class CardNoteRequest(BaseModel):
    note: str | None = Field(default=None, max_length=500)


@router.post(
    "/{card_id}/renewal-requests",
    response_model=ServiceRequestResponse,
    status_code=201,
    summary="Request card renewal",
)
def renewal_request(
    card_id: uuid.UUID,
    payload: CardNoteRequest,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    return _response(card_requests.request_renewal(db, user, card_id=card_id, note=payload.note))


@router.post(
    "/{card_id}/cancellation-requests",
    response_model=ServiceRequestResponse,
    status_code=201,
    summary="Request card cancellation",
)
def cancellation_request(
    card_id: uuid.UUID,
    payload: CardNoteRequest,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    return _response(
        card_requests.request_cancellation(db, user, card_id=card_id, note=payload.note)
    )


@router.post(
    "/{card_id}/pin-reset-requests",
    response_model=ServiceRequestResponse,
    status_code=201,
    summary="Request a PIN reset through a bank-approved process",
)
def pin_reset_request(
    card_id: uuid.UUID,
    payload: CardNoteRequest,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    return _response(card_requests.request_pin_reset(db, user, card_id=card_id, note=payload.note))


@router.get("/{card_id}/statements", response_model=list[dict], summary="Card statements")
def statements(
    card_id: uuid.UUID,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> list[dict]:
    return [
        {
            "id": statement.id,
            "period_start": statement.period_start,
            "period_end": statement.period_end,
            "statement_balance": float(statement.statement_balance),
            "minimum_payment": float(statement.minimum_payment),
            "due_date": statement.due_date,
            "status": statement.status,
        }
        for statement in transaction_service.statements(db, user, card_id)
    ]
