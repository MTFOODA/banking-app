"""Credit-card repayment endpoints (simulated service)."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Header, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.exceptions import AppError
from app.dependencies.auth import get_current_customer
from app.models.transactions import Repayment
from app.models.user import User
from app.schemas.common import Page
from app.schemas.transaction import RepaymentCreate, RepaymentQuote, RepaymentResponse
from app.services import repayment_execution, repayment_service, card_service

router = APIRouter(prefix="/repayments", tags=["Repayments"])


def _response(db: Session, repayment: Repayment) -> RepaymentResponse:
    card = card_service.get_card(db, db.get(User, repayment.customer_id), repayment.card_id)
    return RepaymentResponse(
        id=repayment.id,
        reference=repayment.reference,
        card_id=repayment.card_id,
        card_last4=card.card_last4,
        funding_account_id=repayment.funding_account_id,
        amount=repayment.amount,
        mode=repayment.mode,
        status=repayment.status,
        is_simulated=repayment.is_simulated,
        charges=repayment.charges,
        created_at=repayment.created_at,
        completed_at=repayment.completed_at,
        notes=repayment.notes,
    )


@router.post("/quote", response_model=RepaymentQuote, summary="Quote a repayment")
def quote(
    payload: RepaymentCreate,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> RepaymentQuote:
    data = repayment_service.quote(
        db,
        user,
        card_id=payload.card_id,
        funding_account_id=payload.funding_account_id,
        mode=payload.mode,
        amount=payload.amount,
    )
    return RepaymentQuote(**data)


@router.post(
    "", response_model=RepaymentResponse, status_code=201, summary="Submit a simulated repayment"
)
def create_repayment(
    payload: RepaymentCreate,
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> RepaymentResponse:
    repayment, _replayed = repayment_execution.create_repayment(
        db,
        user,
        card_id=payload.card_id,
        funding_account_id=payload.funding_account_id,
        mode=payload.mode,
        amount=payload.amount,
        idempotency_key=idempotency_key,
    )
    return _response(db, repayment)


@router.get("", response_model=Page[RepaymentResponse], summary="Repayment history")
def list_repayments(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> Page[RepaymentResponse]:
    rows, total = repayment_service.list_repayments(db, user, page=page, page_size=page_size)
    return Page.build(
        [_response(db, item) for item in rows], page=page, page_size=page_size, total=total
    )


@router.get("/{repayment_id}", response_model=RepaymentResponse, summary="Repayment details")
def repayment_details(
    repayment_id: uuid.UUID,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> RepaymentResponse:
    repayment = repayment_service.get_repayment(db, user, repayment_id)
    if repayment is None:  # pragma: no cover - defensive
        raise AppError(
            code="repayment_not_found", message="Repayment not found.", status_code=404
        )
    return _response(db, repayment)
