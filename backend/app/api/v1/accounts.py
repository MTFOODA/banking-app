"""Account endpoints (customer-scoped)."""

from __future__ import annotations

import uuid
from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_customer
from app.models.user import User
from app.schemas.account import (
    AccountDetailResponse,
    AccountProductResponse,
    AccountRequestCreate,
    AccountSummaryResponse,
    AccountsOverviewResponse,
)
from app.schemas.common import Page
from app.schemas.request import ServiceRequestResponse
from app.schemas.transaction import TransactionResponse
from app.services import account_service, request_service, transaction_service

router = APIRouter(prefix="/accounts", tags=["Accounts"])


@router.get("", response_model=AccountsOverviewResponse, summary="List customer accounts")
def list_accounts(
    user: User = Depends(get_current_customer), db: Session = Depends(get_db)
) -> AccountsOverviewResponse:
    accounts = account_service.list_accounts(db, user)
    return AccountsOverviewResponse(
        totals=account_service.totals(accounts),
        accounts=[AccountSummaryResponse.from_model(account) for account in accounts],
    )


@router.get("/products", response_model=list[AccountProductResponse], summary="Account products")
def products(
    user: User = Depends(get_current_customer), db: Session = Depends(get_db)
) -> list[AccountProductResponse]:
    return [AccountProductResponse.model_validate(item) for item in account_service.list_products(db)]


@router.post(
    "/requests",
    response_model=ServiceRequestResponse,
    status_code=201,
    summary="Request an account to be opened or closed",
)
def create_account_request(
    payload: AccountRequestCreate,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    form_data = {
        "account_type": payload.account_type,
        "account_id": str(payload.account_id) if payload.account_id else None,
        "reason": payload.reason,
        "notes": payload.notes,
    }
    request = request_service.create_request(
        db,
        user,
        request_type=payload.request_type,
        form_data={k: v for k, v in form_data.items() if v is not None},
    )
    return ServiceRequestResponse.from_model(
        request, available_actions=request_service.customer_actions(request)
    )


@router.get(
    "/requests",
    response_model=Page[ServiceRequestResponse],
    summary="Account-related requests",
)
def list_account_requests(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> Page[ServiceRequestResponse]:
    rows, total = request_service.list_requests(db, user, page=page, page_size=page_size)
    items = [
        ServiceRequestResponse.from_model(
            item, available_actions=request_service.customer_actions(item)
        )
        for item in rows
        if item.request_type.startswith("account")
    ]
    return Page.build(items, page=page, page_size=page_size, total=total)


@router.get("/{account_id}", response_model=AccountDetailResponse, summary="Account details")
def account_details(
    account_id: uuid.UUID,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> AccountDetailResponse:
    return account_service.detail(db, user, account_id)


@router.get(
    "/{account_id}/transactions",
    response_model=Page[TransactionResponse],
    summary="Transactions for one account",
)
def account_transactions(
    account_id: uuid.UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    transaction_type: str | None = None,
    direction: str | None = Query(None, pattern="^(debit|credit)$"),
    status: str | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
    min_amount: Decimal | None = Query(None, ge=0),
    max_amount: Decimal | None = Query(None, ge=0),
    search: str | None = Query(None, max_length=80),
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> Page[TransactionResponse]:
    items, total = transaction_service.list_transactions(
        db,
        user,
        account_id=account_id,
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
