"""Customer support conversations."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.service import SupportMessage, SupportTicket
from app.models.user import User
from app.services.common import generate_reference


def list_tickets(db: Session, user: User) -> list[SupportTicket]:
    return list(
        db.scalars(
            select(SupportTicket)
            .where(SupportTicket.customer_id == user.id)
            .order_by(SupportTicket.created_at.desc())
        ).all()
    )


def get_ticket(db: Session, user: User, ticket_id: uuid.UUID) -> SupportTicket:
    ticket = db.scalar(
        select(SupportTicket).where(
            SupportTicket.id == ticket_id, SupportTicket.customer_id == user.id
        )
    )
    if ticket is None:
        raise AppError(code="ticket_not_found", message="Ticket not found.", status_code=404)
    return ticket


def create_ticket(
    db: Session, user: User, *, subject: str, message: str, priority: str
) -> SupportTicket:
    ticket = SupportTicket(
        reference=generate_reference("SUP"),
        customer_id=user.id,
        subject=subject.strip(),
        priority=priority,
    )
    ticket.messages.append(
        SupportMessage(sender_type="customer", sender_id=user.id, body=message.strip())
    )
    db.add(ticket)
    db.commit()
    db.refresh(ticket)
    return ticket


def add_message(db: Session, user: User, ticket: SupportTicket, body: str) -> SupportTicket:
    if ticket.status == "closed":
        raise AppError(
            code="ticket_closed", message="This conversation is closed.", status_code=409
        )
    ticket.messages.append(
        SupportMessage(sender_type="customer", sender_id=user.id, body=body.strip())
    )
    ticket.status = "open"
    db.commit()
    db.refresh(ticket)
    return ticket
