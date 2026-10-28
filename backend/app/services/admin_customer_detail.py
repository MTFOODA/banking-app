"""Administrative customer detail view (masked sensitive fields)."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.banking import Account, Card
from app.models.enums import LoginType
from app.models.service import ServiceRequest
from app.models.transactions import Repayment
from app.models.user import User
from app.services.admin_service import counts, customer_item
from app.services.request_service import customer_actions


def customer_detail(db: Session, customer_id: uuid.UUID) -> dict:
    user = db.get(User, customer_id)
    if user is None or user.profile is None or user.login_type != LoginType.CUSTOMER:
        raise AppError(code="customer_not_found", message="Customer not found.", status_code=404)

    aggregates = counts(db)
    base = customer_item(user, user.profile, aggregates)
    accounts = db.scalars(
        select(Account).where(Account.customer_id == user.id).order_by(Account.opened_at)
    ).all()
    cards = db.scalars(
        select(Card).where(Card.customer_id == user.id).order_by(Card.issued_at.desc())
    ).all()
    requests = db.scalars(
        select(ServiceRequest)
        .where(ServiceRequest.customer_id == user.id)
        .order_by(ServiceRequest.created_at.desc())
        .limit(20)
    ).all()
    repayments = db.scalars(
        select(Repayment)
        .where(Repayment.customer_id == user.id)
        .order_by(Repayment.created_at.desc())
        .limit(10)
    ).all()

    return {
        **base,
        "national_id_masked": user.profile.national_id_masked,
        "date_of_birth": (
            user.profile.date_of_birth.isoformat() if user.profile.date_of_birth else None
        ),
        "accounts": [
            {
                "id": account.id,
                "account_type": account.account_type,
                "account_number_masked": account.account_number_masked,
                "status": account.status,
                "current_balance": float(account.current_balance),
                "available_balance": float(account.available_balance),
                "currency": account.currency,
            }
            for account in accounts
        ],
        "cards": [
            {
                "id": card.id,
                "card_last4": card.card_last4,
                "card_kind": card.card_kind,
                "status": card.status,
                "is_supplementary": card.is_supplementary,
            }
            for card in cards
        ],
        "requests": [
            {
                "id": item.id,
                "reference": item.reference,
                "request_type": item.request_type,
                "status": item.status,
                "priority": item.priority,
                "submitted_at": item.submitted_at,
                "created_at": item.created_at,
                "updated_at": item.updated_at,
                "decided_at": item.decided_at,
                "assigned_label": item.assigned_label,
                "decision_reason": item.decision_reason,
                "customer_explanation": item.customer_explanation,
                "form_data": item.form_data or {},
                "history": [
                    {
                        "id": entry.id,
                        "from_status": entry.from_status,
                        "to_status": entry.to_status,
                        "note": entry.note,
                        "actor_label": entry.actor_label,
                        "created_at": entry.created_at,
                    }
                    for entry in item.history
                    if entry.is_customer_visible
                ],
                "documents": [
                    {
                        "id": document.id,
                        "filename": document.filename,
                        "content_type": document.content_type,
                        "size_bytes": document.size_bytes,
                        "created_at": document.created_at,
                    }
                    for document in item.documents
                ],
                "available_actions": customer_actions(item),
            }
            for item in requests
        ],
        "repayments": [
            {
                "reference": item.reference,
                "amount": float(item.amount),
                "status": item.status,
                "created_at": item.created_at,
                "mode": item.mode,
            }
            for item in repayments
        ],
    }
