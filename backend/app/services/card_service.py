"""Card queries and freeze/unfreeze controls."""

from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.banking import Card
from app.models.enums import CardKind, CardStatus
from app.models.user import User
from app.services import notification_service
from app.services.common import record_audit


def list_cards(
    db: Session, user: User, *, kind: str | None = None, status: str | None = None
) -> list[Card]:
    stmt = select(Card).where(Card.customer_id == user.id)
    if kind:
        stmt = stmt.where(Card.card_kind == kind)
    if status:
        stmt = stmt.where(Card.status == status)
    stmt = stmt.where(Card.status != CardStatus.CANCELLED)
    return list(db.scalars(stmt.order_by(Card.is_primary.desc(), Card.issued_at.desc())).all())


def get_card(db: Session, user: User, card_id: uuid.UUID) -> Card:
    card = db.scalar(select(Card).where(Card.id == card_id, Card.customer_id == user.id))
    if card is None:
        raise AppError(code="card_not_found", message="Card not found.", status_code=404)
    return card


def overview(db: Session, user: User) -> dict:
    cards = list_cards(db, user)
    credit_cards = [c for c in cards if c.card_kind == CardKind.CREDIT]
    return {
        "cards": cards,
        "active_count": sum(1 for c in cards if c.status == CardStatus.ACTIVE),
        "frozen_count": sum(1 for c in cards if c.status == CardStatus.FROZEN),
        "credit_outstanding_total": sum(
            (c.outstanding_balance or Decimal("0.00") for c in credit_cards), Decimal("0.00")
        ),
    }


def notify_card(
    db: Session,
    user: User,
    card: Card,
    *,
    title_en: str,
    title_ar: str,
    body_en: str,
    body_ar: str,
    priority: str = "normal",
) -> None:
    notification_service.notify(
        db,
        customer_id=user.id,
        category="security" if priority == "high" else "transaction",
        title_en=title_en,
        title_ar=title_ar,
        body_en=body_en,
        body_ar=body_ar,
        priority=priority,
        related_entity_type="card",
        related_entity_id=card.id,
        cta_route=f"/cards/{card.id}",
    )


def freeze_card(db: Session, user: User, card_id: uuid.UUID, reason: str | None) -> Card:
    card = get_card(db, user, card_id)
    if card.status == CardStatus.FROZEN:
        return card
    if card.status != CardStatus.ACTIVE:
        raise AppError(
            code="card_not_freezable",
            message="Only active cards can be frozen.",
            status_code=409,
            details={"status": card.status},
        )
    card.status = CardStatus.FROZEN
    card.version = (card.version or 1) + 1
    notify_card(
        db,
        user,
        card,
        title_en="Card frozen",
        title_ar="تم تجميد البطاقة",
        body_en=f"Card ending {card.card_last4} is temporarily frozen.",
        body_ar=f"تم تجميد البطاقة المنتهية بـ {card.card_last4} مؤقتاً.",
    )
    record_audit(
        db,
        actor=user,
        action="card.frozen",
        entity_type="card",
        entity_id=card.id,
        details={"reason": reason},
    )
    db.commit()
    db.refresh(card)
    return card


def unfreeze_card(db: Session, user: User, card_id: uuid.UUID) -> Card:
    card = get_card(db, user, card_id)
    if card.status == CardStatus.ACTIVE:
        return card
    if card.status != CardStatus.FROZEN:
        raise AppError(
            code="card_not_unfreezable",
            message="This card cannot be reactivated online. Please contact the bank.",
            status_code=409,
            details={"status": card.status},
        )
    card.status = CardStatus.ACTIVE
    card.version = (card.version or 1) + 1
    notify_card(
        db,
        user,
        card,
        title_en="Card unfrozen",
        title_ar="تم إلغاء تجميد البطاقة",
        body_en=f"Card ending {card.card_last4} is active again.",
        body_ar=f"بطاقتك المنتهية بـ {card.card_last4} أصبحت نشطة مرة أخرى.",
    )
    record_audit(db, actor=user, action="card.unfrozen", entity_type="card", entity_id=card.id)
    db.commit()
    db.refresh(card)
    return card
