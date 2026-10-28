"""Simulated transfer and beneficiary endpoints."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Header, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_customer
from app.models.user import User
from app.schemas.common import Page
from app.schemas.transaction import (
    BeneficiaryCreate,
    BeneficiaryResponse,
    TransactionResponse,
    TransferCreate,
    TransferResponse,
)
from app.services import transfer_execution, transfer_service

router = APIRouter(prefix="/transfers", tags=["Transfers"])
beneficiaries_router = APIRouter(prefix="/beneficiaries", tags=["Beneficiaries"])


@router.get('/options',summary='Transfer routes and delivery availability')
def transfer_options(user: User=Depends(get_current_customer)):
    return transfer_execution.transfer_options()


@router.post("", response_model=TransferResponse, status_code=201, summary="Send a transfer")
def create_transfer(
    payload: TransferCreate,
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> TransferResponse:
    result, _replayed = transfer_execution.execute_transfer(
        db,
        user,
        draft=payload,
        idempotency_key=idempotency_key or "",
    )
    return TransferResponse(**result)


@router.post("/quote", summary="Review an eligible transfer")
def quote_transfer(payload: TransferCreate, user: User = Depends(get_current_customer), db: Session = Depends(get_db)):
    return transfer_execution.quote_transfer(db, user, payload)


@router.get("", response_model=Page[TransactionResponse], summary="Transfer history")
def list_transfers(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> Page[TransactionResponse]:
    items, total = transfer_service.list_transfers(db, user, page=page, page_size=page_size)
    return Page.build(items, page=page, page_size=page_size, total=total)


@beneficiaries_router.get(
    "", response_model=list[BeneficiaryResponse], summary="Saved beneficiaries"
)
def list_beneficiaries(
    user: User = Depends(get_current_customer), db: Session = Depends(get_db)
) -> list[BeneficiaryResponse]:
    return [
        BeneficiaryResponse.model_validate(item)
        for item in transfer_service.list_beneficiaries(db, user)
    ]


@beneficiaries_router.post(
    "", response_model=BeneficiaryResponse, status_code=201, summary="Add a beneficiary"
)
def create_beneficiary(
    payload: BeneficiaryCreate,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> BeneficiaryResponse:
    beneficiary = transfer_service.create_beneficiary(
        db,
        user,
        name=payload.name,
        nickname=payload.nickname,
        bank_name=payload.bank_name,
        account_number=payload.account_number,
        iban=payload.iban,
        currency=payload.currency,
    )
    return BeneficiaryResponse.model_validate(beneficiary)


@beneficiaries_router.delete("/{beneficiary_id}", status_code=204, summary="Remove a beneficiary")
def delete_beneficiary(
    beneficiary_id: uuid.UUID,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> None:
    transfer_service.delete_beneficiary(db, user, beneficiary_id)
