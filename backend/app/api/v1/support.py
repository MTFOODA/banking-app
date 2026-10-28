"""Customer support endpoints."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_customer
from app.models.service import SupportTicket
from app.models.user import User
from app.schemas.profile import (
    SupportMessageCreate,
    SupportMessageResponse,
    SupportTicketCreate,
    SupportTicketResponse,
)
from app.services import support_service

router = APIRouter(prefix="/support", tags=["Support"])


def _response(ticket: SupportTicket) -> SupportTicketResponse:
    return SupportTicketResponse(
        id=ticket.id,
        reference=ticket.reference,
        subject=ticket.subject,
        status=ticket.status,
        priority=ticket.priority,
        created_at=ticket.created_at,
        messages=[
            SupportMessageResponse(
                id=message.id,
                sender_type=message.sender_type,
                body=message.body,
                created_at=message.created_at,
            )
            for message in ticket.messages
        ],
    )


@router.get("/tickets", response_model=list[SupportTicketResponse], summary="My support tickets")
def list_tickets(
    user: User = Depends(get_current_customer), db: Session = Depends(get_db)
) -> list[SupportTicketResponse]:
    return [_response(ticket) for ticket in support_service.list_tickets(db, user)]


@router.post(
    "/tickets",
    response_model=SupportTicketResponse,
    status_code=201,
    summary="Start a support conversation",
)
def create_ticket(
    payload: SupportTicketCreate,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> SupportTicketResponse:
    return _response(
        support_service.create_ticket(
            db, user, subject=payload.subject, message=payload.message, priority=payload.priority
        )
    )


@router.get("/tickets/{ticket_id}", response_model=SupportTicketResponse, summary="Ticket detail")
def ticket_detail(
    ticket_id: uuid.UUID,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> SupportTicketResponse:
    return _response(support_service.get_ticket(db, user, ticket_id))


@router.post(
    "/tickets/{ticket_id}/messages",
    response_model=SupportTicketResponse,
    summary="Add a message to a support ticket",
)
def add_message(
    ticket_id: uuid.UUID,
    payload: SupportMessageCreate,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> SupportTicketResponse:
    ticket = support_service.get_ticket(db, user, ticket_id)
    return _response(support_service.add_message(db, user, ticket, payload.message))
