"""Card endpoints: listing, details and immediate controls."""

from __future__ import annotations

import uuid
from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_customer
from app.models.user import User
from app.schemas.card import (
    CardActionRequest,
    CardSummaryResponse,
    CardProductOffer,
    CardsOverviewResponse,
    CardToggleRequest,
    ReportLostRequest,
)
from app.schemas.common import Page
from app.schemas.transaction import TransactionResponse
from app.services import card_controls, card_service, transaction_service

router = APIRouter(prefix="/cards", tags=["Cards"])


@router.get("", response_model=CardsOverviewResponse, summary="List customer cards")
def list_cards(
    user: User = Depends(get_current_customer), db: Session = Depends(get_db)
) -> CardsOverviewResponse:
    data = card_service.overview(db, user)
    return CardsOverviewResponse(
        cards=[CardSummaryResponse.from_model(card) for card in data["cards"]],
        active_count=data["active_count"],
        frozen_count=data["frozen_count"],
        credit_outstanding_total=data["credit_outstanding_total"],
    )


@router.get('/products', response_model=list[CardProductOffer], summary='Card categories and my eligible accounts')
def card_products(user: User = Depends(get_current_customer), db: Session = Depends(get_db)):
    from app.services.card_catalogue import catalogue
    return catalogue(db, user)


@router.get("/{card_id}", response_model=CardSummaryResponse, summary="Card details")
def card_details(
    card_id: uuid.UUID,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> CardSummaryResponse:
    return CardSummaryResponse.from_model(card_service.get_card(db, user, card_id))


@router.get(
    "/{card_id}/transactions",
    response_model=Page[TransactionResponse],
    summary="Transactions for one card",
)
def card_transactions(
    card_id: uuid.UUID,
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


@router.post("/{card_id}/freeze", response_model=CardSummaryResponse, summary="Freeze a card")
def freeze(
    card_id: uuid.UUID,
    payload: CardActionRequest,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> CardSummaryResponse:
    card = card_service.freeze_card(db, user, card_id, payload.reason)
    return CardSummaryResponse.from_model(card)


@router.post("/{card_id}/unfreeze", response_model=CardSummaryResponse, summary="Unfreeze a card")
def unfreeze(
    card_id: uuid.UUID,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> CardSummaryResponse:
    return CardSummaryResponse.from_model(card_service.unfreeze_card(db, user, card_id))


@router.post(
    "/{card_id}/report-lost",
    response_model=CardSummaryResponse,
    summary="Report a card lost or stolen and block it immediately",
)
def report_lost(
    card_id: uuid.UUID,
    payload: ReportLostRequest,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> CardSummaryResponse:
    card = card_controls.report_card_lost(
        db, user, card_id, report_type=payload.report_type, note=payload.note
    )
    return CardSummaryResponse.from_model(card)


@router.post(
    "/{card_id}/block", response_model=CardSummaryResponse, summary="Permanently block a card"
)
def block(
    card_id: uuid.UUID,
    payload: CardActionRequest,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> CardSummaryResponse:
    card = card_controls.block_card(db, user, card_id, payload.reason)
    return CardSummaryResponse.from_model(card)


@router.post(
    "/{card_id}/controls/{control}",
    response_model=CardSummaryResponse,
    summary="Toggle online, international or contactless usage",
)
def toggle_control(
    card_id: uuid.UUID,
    control: str,
    payload: CardToggleRequest,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> CardSummaryResponse:
    card = card_controls.update_control(db, user, card_id, control, payload.enabled)
    return CardSummaryResponse.from_model(card)
