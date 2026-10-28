"""Thin helpers translating card UI actions into tracked service requests."""

from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy.orm import Session

from app.models.service import ServiceRequest
from app.models.user import User
from app.services import request_service


def request_replacement(
    db: Session,
    user: User,
    *,
    card_id: uuid.UUID,
    reason: str,
    delivery_branch: str | None,
    urgent: bool,
) -> ServiceRequest:
    return request_service.create_request(
        db,
        user,
        request_type="card_replacement",
        form_data={
            "card_id": str(card_id),
            "reason": reason,
            "delivery_branch": delivery_branch,
            "urgent": urgent,
        },
        priority="high" if urgent else "normal",
    )


def request_limit_change(
    db: Session,
    user: User,
    *,
    card_id: uuid.UUID,
    limit_type: str,
    requested_amount: Decimal,
    reason: str,
    increase: bool,
) -> ServiceRequest:
    return request_service.create_request(
        db,
        user,
        request_type="card_limit_increase" if increase else "card_limit_decrease",
        form_data={
            "card_id": str(card_id),
            "limit_type": limit_type,
            "requested_amount": str(requested_amount),
            "reason": reason,
        },
    )


def request_supplementary(
    db: Session,
    user: User,
    *,
    primary_card_id: uuid.UUID,
    holder_first_name: str,
    holder_last_name: str,
    holder_relationship: str,
    holder_national_id: str,
    holder_phone: str | None,
    card_product_code: str | None,
    spending_limit: Decimal,
    restrictions: list[str],
) -> ServiceRequest:
    return request_service.create_request(
        db,
        user,
        request_type="supplementary_card",
        form_data={
            "primary_card_id": str(primary_card_id),
            "holder_first_name": holder_first_name,
            "holder_last_name": holder_last_name,
            "holder_relationship": holder_relationship,
            "holder_national_id": holder_national_id,
            "holder_phone": holder_phone,
            "card_product_code": card_product_code,
            "spending_limit": str(spending_limit),
            "restrictions": restrictions,
        },
    )


def request_renewal(db: Session, user: User, *, card_id: uuid.UUID, note: str | None):
    return request_service.create_request(
        db,
        user,
        request_type="card_renewal",
        form_data={"card_id": str(card_id), "notes": note},
    )


def request_cancellation(db: Session, user: User, *, card_id: uuid.UUID, note: str | None):
    return request_service.create_request(
        db,
        user,
        request_type="card_cancellation",
        form_data={"card_id": str(card_id), "notes": note},
        priority="high",
    )


def request_pin_reset(db: Session, user: User, *, card_id: uuid.UUID, note: str | None):
    return request_service.create_request(
        db,
        user,
        request_type="pin_reset",
        form_data={"card_id": str(card_id), "notes": note},
    )
