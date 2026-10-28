"""Simulated credit-card repayment execution (demo only)."""

from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import AppError
from app.models.banking import Account, Card
from app.models.enums import (
    RepaymentStatus,
    TransactionDirection,
    TransactionStatus,
    TransactionType,
)
from app.models.transactions import Repayment, Transaction, TransactionEntry
from app.models.user import User
from app.services import notification_service
from app.services.common import generate_reference, quantize_money, record_audit, utcnow
from app.services.rate_limit import check_rate_limit
from app.services.repayment_service import ZERO, quote


def create_repayment(
    db: Session,
    user: User,
    *,
    card_id: uuid.UUID,
    funding_account_id: uuid.UUID,
    mode: str,
    amount: Decimal | None,
    idempotency_key: str | None,
) -> tuple[Repayment, bool]:
    check_rate_limit(f"repayment:{user.id}", limit=settings.sensitive_rate_limit_attempts)
    stored_key = f"{user.id}:{idempotency_key}" if idempotency_key else None
    if stored_key:
        existing = db.scalar(
            select(Repayment).where(
                Repayment.idempotency_key == stored_key, Repayment.customer_id == user.id
            )
        )
        if existing is not None:
            return existing, True

    quote_data = quote(
        db,
        user,
        card_id=card_id,
        funding_account_id=funding_account_id,
        mode=mode,
        amount=amount,
    )
    if not quote_data["eligible"]:
        raise AppError(
            code="repayment_not_eligible",
            message="This repayment cannot be processed.",
            status_code=409,
            details={"reason": quote_data["ineligibility_reason"]},
        )

    payable = quote_data["payable"]
    card = db.scalar(select(Card).where(Card.id == card_id).with_for_update())
    account = db.scalar(select(Account).where(Account.id == funding_account_id).with_for_update())
    if card is None or account is None:
        raise AppError(code="repayment_failed", message="Repayment failed.", status_code=409)
    if account.available_balance < payable:
        raise AppError(
            code="insufficient_funds",
            message="The funding account balance changed. Please refresh and try again.",
            status_code=409,
        )

    reference = generate_reference("REP")
    account.available_balance = quantize_money(account.available_balance - payable)
    account.current_balance = quantize_money(account.current_balance - payable)
    account.version = (account.version or 1) + 1

    card.outstanding_balance = quantize_money((card.outstanding_balance or ZERO) - payable)
    card.available_credit = min(
        card.credit_limit or ZERO, quantize_money((card.available_credit or ZERO) + payable)
    )
    card.version = (card.version or 1) + 1

    repayment = Repayment(
        customer_id=user.id,
        card_id=card.id,
        funding_account_id=account.id,
        amount=payable,
        mode=mode,
        status=RepaymentStatus.SIMULATED_COMPLETED,
        reference=reference,
        idempotency_key=stored_key,
        is_simulated=True,
        charges=quote_data["charges"],
        notes="Simulated repayment created by the Faisal App demo. No real funds moved.",
        completed_at=utcnow(),
    )
    db.add(repayment)
    db.flush()

    funding_txn = Transaction(
        customer_id=user.id,
        account_id=account.id,
        journal_id=repayment.id,
        reference=reference,
        transaction_type=TransactionType.CARD_REPAYMENT,
        direction=TransactionDirection.DEBIT,
        amount=payable,
        currency=account.currency,
        description=f"Credit card repayment • {card.card_last4}",
        description_ar=f"سداد بطاقة ائتمانية • {card.card_last4}",
        counterparty=f"Card ending {card.card_last4}",
        status=TransactionStatus.POSTED,
        is_simulated=True,
        balance_after=account.available_balance,
    )
    card_txn = Transaction(
        customer_id=user.id,
        card_id=card.id,
        journal_id=repayment.id,
        reference=generate_reference("REP"),
        transaction_type=TransactionType.CARD_REPAYMENT,
        direction=TransactionDirection.CREDIT,
        amount=payable,
        currency="EGP",
        description="Repayment received",
        description_ar="تم استلام السداد",
        counterparty=account.account_number_masked,
        status=TransactionStatus.POSTED,
        is_simulated=True,
    )
    db.add_all([funding_txn, card_txn])
    db.flush()
    db.add_all(
        [
            TransactionEntry(
                transaction_id=funding_txn.id,
                account_id=account.id,
                entry_type=TransactionDirection.DEBIT,
                amount=payable,
            ),
            TransactionEntry(
                transaction_id=card_txn.id,
                account_id=None,
                entry_type=TransactionDirection.CREDIT,
                amount=payable,
            ),
        ]
    )


    notification_service.notify(
        db,
        customer_id=user.id,
        category="transaction",
        title_en="Repayment completed (simulated)",
        title_ar="تم السداد (محاكاة)",
        body_en=f"{payable} EGP repaid to card ending {card.card_last4}.",
        body_ar=f"تم سداد {payable} جنيه مصري للبطاقة المنتهية بـ {card.card_last4}.",
        related_entity_type="repayment",
        related_entity_id=repayment.id,
        cta_route=f"/cards/{card.id}",
    )
    record_audit(
        db,
        actor=user,
        action="repayment.simulated_completed",
        entity_type="repayment",
        entity_id=repayment.id,
        details={
            "amount": str(payable),
            "mode": mode,
            "simulated": True,
            "idempotency_key_used": bool(idempotency_key),
        },
    )

    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        if stored_key:
            existing = db.scalar(
                select(Repayment).where(
                    Repayment.idempotency_key == stored_key, Repayment.customer_id == user.id
                )
            )
            if existing is not None:
                return existing, True
        raise AppError(
            code="repayment_conflict",
            message="The repayment could not be completed.",
            status_code=409,
        ) from exc

    db.refresh(repayment)
    return repayment, False

