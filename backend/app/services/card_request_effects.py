"""Approval side effects for card-related service requests."""

from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy.orm import Session

from app.models.banking import Card, SupplementaryCardRelationship
from app.models.enums import CardStatus, RequestStatus, RequestType
from app.models.service import ServiceRequest
from app.models.user import User
from app.services import notification_service
from app.services.card_factory import first_card_product, new_card


def apply_card_effects(
    db: Session, request: ServiceRequest, customer: User, data: dict, *, actor: User | None = None
) -> str:
    if request.request_type == RequestType.CARD_ISSUE:
        from app.services.card_catalogue import validate_issue
        from app.services.common import record_audit
        product, account, canonical = validate_issue(db, customer, data, lock=True)
        profile = customer.profile
        holder = f'{profile.first_name_en} {profile.last_name_en}' if profile else 'CARDHOLDER'
        card = new_card(db, customer_id=customer.id, account_id=account.id,
            product=product, holder_name=holder, is_primary=True, is_supplementary=False)
        db.flush()
        request.form_data = {**canonical, 'issued_card_id': str(card.id)}
        record_audit(db, actor=actor, action='card.issued_on_approval', entity_type='card',
            entity_id=card.id, details={'request_id': str(request.id), 'product_code': product.code})
        notification_service.notify(db, customer_id=customer.id, category='request_status',
            title_en='Card request approved', title_ar='تمت الموافقة على طلب البطاقة',
            body_en=f'Your {product.name_en} ending {card.card_last4} has been issued, pending activation.',
            body_ar=f'تم إصدار {product.name_ar} المنتهية بـ {card.card_last4} وهي بانتظار التفعيل.',
            related_entity_type='card', related_entity_id=card.id, cta_route=f'/cards/{card.id}')
        return RequestStatus.COMPLETED

    if request.request_type == RequestType.SUPPLEMENTARY_CARD:
        primary = db.get(Card, uuid.UUID(str(data.get("primary_card_id"))))
        if primary is None or primary.customer_id != customer.id:
            return RequestStatus.COMPLETED
        product = first_card_product(db, data.get("card_product_code"))
        holder = f"{data.get('holder_first_name', '')} {data.get('holder_last_name', '')}".strip()
        card = new_card(
            db,
            customer_id=customer.id,
            account_id=primary.account_id,
            product=product,
            holder_name=holder or "SUPPLEMENTARY HOLDER",
            is_primary=False,
            is_supplementary=True,
        )
        db.add(
            SupplementaryCardRelationship(
                primary_card_id=primary.id,
                supplementary_card_id=card.id,
                holder_name=holder or "Supplementary holder",
                relationship_type=str(data.get("holder_relationship") or "family"),
            )
        )
        if card.limits and data.get("spending_limit"):
            card.limits.monthly_limit = Decimal(str(data["spending_limit"]))
        notification_service.notify(
            db,
            customer_id=customer.id,
            category="request_status",
            title_en="Supplementary card issued",
            title_ar="تم إصدار بطاقة إضافية",
            body_en=f"A supplementary card ending {card.card_last4} has been issued.",
            body_ar=f"تم إصدار بطاقة إضافية تنتهي بـ {card.card_last4}.",
            related_entity_type="card",
            related_entity_id=card.id,
            cta_route=f"/cards/{card.id}",
        )
        return RequestStatus.PROCESSING

    if request.request_type in {RequestType.CARD_REPLACEMENT, RequestType.CARD_RENEWAL}:
        old_card = db.get(Card, uuid.UUID(str(data.get("card_id"))))
        if old_card is None or old_card.customer_id != customer.id:
            return RequestStatus.COMPLETED
        replacement = new_card(
            db,
            customer_id=customer.id,
            account_id=old_card.account_id,
            product=old_card.product,
            holder_name=old_card.cardholder_name,
            is_primary=old_card.is_primary,
            is_supplementary=old_card.is_supplementary,
        )
        if request.request_type == RequestType.CARD_REPLACEMENT:
            old_card.status = CardStatus.CANCELLED
        notification_service.notify(
            db,
            customer_id=customer.id,
            category="request_status",
            title_en="Replacement card issued",
            title_ar="تم إصدار بطاقة بديلة",
            body_en=f"Your replacement card ending {replacement.card_last4} is being prepared.",
            body_ar=f"جارٍ تجهيز بطاقتك البديلة المنتهية بـ {replacement.card_last4}.",
            related_entity_type="card",
            related_entity_id=replacement.id,
            cta_route=f"/cards/{replacement.id}",
        )
        return RequestStatus.PROCESSING

    if request.request_type == RequestType.CARD_CANCELLATION:
        card = db.get(Card, uuid.UUID(str(data.get("card_id"))))
        if card is not None and card.customer_id == customer.id:
            card.status = CardStatus.CANCELLED
        return RequestStatus.COMPLETED

    return RequestStatus.COMPLETED
