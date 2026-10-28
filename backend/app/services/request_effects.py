"""Approval side effects for account-related service requests."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from decimal import Decimal

from sqlalchemy.orm import Session

from app.models.banking import Account, Card
from app.models.enums import AccountStatus, RequestStatus, RequestType
from app.models.service import ServiceRequest
from app.models.user import User
from app.services import notification_service
from app.services.account_service import get_product_by_code
from app.services.card_factory import new_account_number


def apply_approval_effects(db: Session, request: ServiceRequest, *, actor: User) -> str:
    data = request.form_data or {}
    customer = db.get(User, request.customer_id)
    if customer is None:  # pragma: no cover - defensive
        return RequestStatus.COMPLETED

    if request.request_type == RequestType.ACCOUNT_OPEN:
        product = get_product_by_code(db, str(data.get("product_code")))
        hashed, masked, iban = new_account_number(db)
        account = Account(
            customer_id=customer.id,
            product_id=product.id,
            account_number_hash=hashed,
            account_number_masked=masked,
            iban=iban,
            account_type=product.account_type,
            currency=product.currency,
            status=AccountStatus.ACTIVE,
            current_balance=Decimal("0.00"),
            available_balance=Decimal("0.00"),
            blocked_balance=Decimal("0.00"),
        )
        db.add(account)
        db.flush()
        notification_service.notify(
            db,
            customer_id=customer.id,
            category="request_status",
            title_en="Account opened",
            title_ar="تم فتح الحساب",
            body_en=f"Your new {product.name_en} ({masked}) is ready.",
            body_ar=f"تم فتح {product.name_ar} الجديد ({masked}) بنجاح.",
            related_entity_type="account",
            related_entity_id=account.id,
            cta_route=f"/accounts/{account.id}",
        )
        return RequestStatus.COMPLETED

    if request.request_type == RequestType.CUSTOMER_INFO_UPDATE:
        from app.schemas.profile import ProfileUpdate
        from app.services.common import record_audit
        changes = ProfileUpdate(authorization_token="validation-placeholder", **{
            key: value for key, value in data.items() if key in {"email", "phone", "address"}
        }).model_dump(exclude={"authorization_token"}, exclude_none=True)
        for key, value in changes.items():
            setattr(customer.profile, key, value)
        record_audit(db, actor=actor, action="profile.update_approved", entity_type="customer_profile",
                     entity_id=customer.profile.id, details={"fields": sorted(changes), "request": request.reference})
        return RequestStatus.COMPLETED

    if request.request_type == RequestType.ACCOUNT_CLOSE:
        account = db.get(Account, uuid.UUID(str(data.get("account_id"))))
        if account is not None and account.customer_id == customer.id:
            if account.current_balance > 0:
                return RequestStatus.PENDING_APPROVAL
            account.status = AccountStatus.CLOSED
            account.closed_at = datetime.now(UTC)
        return RequestStatus.COMPLETED

    if request.request_type in {
        RequestType.CARD_LIMIT_INCREASE,
        RequestType.CARD_LIMIT_DECREASE,
    }:
        card = db.get(Card, uuid.UUID(str(data.get("card_id"))))
        if card is None or card.customer_id != customer.id or card.limits is None:
            return RequestStatus.COMPLETED
        amount = Decimal(str(data.get("requested_amount") or "0"))
        field = {
            "daily_purchase": "daily_purchase_limit",
            "daily_atm": "daily_atm_limit",
            "monthly": "monthly_limit",
        }.get(str(data.get("limit_type")))
        if field and amount > 0:
            setattr(card.limits, field, amount)
            card.limits.version = (card.limits.version or 1) + 1
        return RequestStatus.COMPLETED

    from app.services.card_request_effects import apply_card_effects

    return apply_card_effects(db, request, customer, data, actor=actor)
