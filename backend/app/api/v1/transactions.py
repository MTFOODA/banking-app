"""Transaction history endpoints."""

from __future__ import annotations

import uuid
from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_customer
from app.models.user import User
from app.schemas.common import Page
from app.schemas.transaction import (
    TransactionDetailResponse,
    TransactionFilterOptions,
    TransactionResponse,
)
from app.services import transaction_service

router = APIRouter(prefix="/transactions", tags=["Transactions"])


@router.get("/filters", response_model=TransactionFilterOptions, summary="Available filters")
def filters(user: User = Depends(get_current_customer)) -> TransactionFilterOptions:
    return TransactionFilterOptions(**transaction_service.filter_options())


@router.get("", response_model=Page[TransactionResponse], summary="All customer transactions")
def list_transactions(
    account_id: uuid.UUID | None = None,
    card_id: uuid.UUID | None = None,
    transaction_type: str | None = None,
    direction: str | None = Query(None, pattern="^(debit|credit)$"),
    status: str | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
    min_amount: Decimal | None = Query(None, ge=0),
    max_amount: Decimal | None = Query(None, ge=0),
    search: str | None = Query(None, max_length=80),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> Page[TransactionResponse]:
    if date_from and date_to and date_from > date_to:
        date_from, date_to = date_to, date_from
    items, total = transaction_service.list_transactions(
        db,
        user,
        account_id=account_id,
        card_id=card_id,
        transaction_type=transaction_type,
        direction=direction,
        status=status,
        date_from=date_from,
        date_to=date_to,
        min_amount=min_amount,
        max_amount=max_amount,
        search=search,
        page=page,
        page_size=page_size,
    )
    return Page.build(items, page=page, page_size=page_size, total=total)


@router.get(
    "/{transaction_id}", response_model=TransactionDetailResponse, summary="Transaction details"
)
def transaction_details(
    transaction_id: uuid.UUID,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> TransactionDetailResponse:
    return transaction_service.get_transaction(db, user, transaction_id)
