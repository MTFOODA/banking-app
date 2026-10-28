"""Emergency card blocking and card control toggles."""

from __future__ import annotations

import uuid

from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.banking import CardLimit
from app.models.enums import CardStatus
from app.models.user import User
from app.services.card_service import get_card, notify_card
from app.services.common import record_audit


def report_card_lost(
    db: Session, user: User, card_id: uuid.UUID, *, report_type: str, note: str | None
) -> object:
    card = get_card(db, user, card_id)
    if card.status == CardStatus.CANCELLED:
        raise AppError(
            code="card_not_blockable", message="This card is already cancelled.", status_code=409
        )
    card.status = CardStatus.STOLEN if report_type == "stolen" else CardStatus.LOST
    card.version = (card.version or 1) + 1
    notify_card(
        db,
        user,
        card,
        title_en="Card blocked for your safety",
        title_ar="تم إيقاف البطاقة لحمايتك",
        body_en=(
            f"Card ending {card.card_last4} has been blocked after a {report_type} report. "
            "You can request a replacement at any time."
        ),
        body_ar=(
            f"تم إيقاف البطاقة المنتهية بـ {card.card_last4} بعد الإبلاغ عنها. "
            "يمكنك طلب بطاقة بديلة في أي وقت."
        ),
        priority="high",
    )
    record_audit(
        db,
        actor=user,
        action=f"card.reported_{report_type}",
        entity_type="card",
        entity_id=card.id,
        details={"note": note},
    )
    db.commit()
    db.refresh(card)
    return card


def block_card(db: Session, user: User, card_id: uuid.UUID, reason: str | None) -> object:
    card = get_card(db, user, card_id)
    if card.status == CardStatus.CANCELLED:
        raise AppError(
            code="card_not_blockable", message="This card is already cancelled.", status_code=409
        )
    card.status = CardStatus.BLOCKED
    card.version = (card.version or 1) + 1
    notify_card(
        db,
        user,
        card,
        title_en="Card permanently blocked",
        title_ar="تم إيقاف البطاقة نهائياً",
        body_en=f"Card ending {card.card_last4} is permanently blocked.",
        body_ar=f"تم إيقاف البطاقة المنتهية بـ {card.card_last4} نهائياً.",
        priority="high",
    )
    record_audit(
        db,
        actor=user,
        action="card.blocked",
        entity_type="card",
        entity_id=card.id,
        details={"reason": reason},
    )
    db.commit()
    db.refresh(card)
    return card


def update_control(
    db: Session, user: User, card_id: uuid.UUID, control: str, enabled: bool
) -> object:
    card = get_card(db, user, card_id)
    if card.limits is None:
        card.limits = CardLimit(card_id=card.id)
    field = {
        "online": "online_enabled",
        "international": "international_enabled",
        "contactless": "contactless_enabled",
    }.get(control)
    if field is None:
        raise AppError(
            code="invalid_card_control", message="Unknown card control.", status_code=422
        )
    setattr(card.limits, field, enabled)
    card.limits.version = (card.limits.version or 1) + 1
    record_audit(
        db,
        actor=user,
        action="card.control_updated",
        entity_type="card",
        entity_id=card.id,
        details={"control": control, "enabled": enabled},
    )
    db.commit()
    db.refresh(card)
    return card
