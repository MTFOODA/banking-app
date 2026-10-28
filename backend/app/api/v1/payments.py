"""Bill payment endpoints (simulated)."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Header, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_customer
from app.models.user import User
from app.schemas.common import Page
from app.schemas.payment import BillerResponse, PaymentCreate, PaymentResponse
from app.schemas.transaction import TransactionResponse
from app.services import payment_service, transaction_service

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.get("/billers", response_model=list[BillerResponse], summary="Demo biller catalogue")
def billers(user: User = Depends(get_current_customer)) -> list[BillerResponse]:
    return [BillerResponse(**biller) for biller in payment_service.list_billers()]


@router.post(
    "",
    response_model=PaymentResponse,
    status_code=201,
    summary="Pay a bill (simulated payment service)",
)
def pay(
    payload: PaymentCreate,
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> PaymentResponse:
    result, _replayed = payment_service.pay_bill(
        db,
        user,
        biller_code=payload.biller_code,
        amount=payload.amount,
        funding_account_id=payload.funding_account_id,
        reference_note=payload.note,
        idempotency_key=idempotency_key,
    )
    return PaymentResponse(**result)


@router.get("", response_model=Page[TransactionResponse], summary="Payment history")
def history(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> Page[TransactionResponse]:
    items, total = transaction_service.list_transactions(
        db,
        user,
        transaction_type="bill_payment",
        page=page,
        page_size=page_size,
    )
    return Page.build(items, page=page, page_size=page_size, total=total)
