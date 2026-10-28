"""Simulated bill payments against the demo ledger."""

from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import AppError
from app.models.banking import Account
from app.models.enums import (
    AccountStatus,
    TransactionDirection,
    TransactionStatus,
    TransactionType,
)
from app.models.transactions import Transaction, TransactionEntry
from app.models.user import User
from app.services import notification_service
from app.services.common import generate_reference, quantize_money, record_audit
from app.services.rate_limit import check_rate_limit

# Demo biller catalogue. Production must use an approved biller directory.
BILLERS: list[dict] = [
    {
        "code": "ELEC-CAIRO",
        "name_en": "Cairo Electricity",
        "name_ar": "كهرباء القاهرة",
        "category": "utilities",
        "amount_due": "640.00",
    },
    {
        "code": "WATER-CAIRO",
        "name_en": "Cairo Water",
        "name_ar": "مياه القاهرة",
        "category": "utilities",
        "amount_due": "185.50",
    },
    {
        "code": "MOBILE-TOPUP",
        "name_en": "Mobile top-up",
        "name_ar": "شحن رصيد الهاتف",
        "category": "telecom",
        "amount_due": None,
    },
    {
        "code": "INTERNET-HOME",
        "name_en": "Home internet",
        "name_ar": "الإنترنت المنزلي",
        "category": "telecom",
        "amount_due": "450.00",
    },
]


def list_billers() -> list[dict]:
    return [dict(item) for item in BILLERS]


def _biller(code: str) -> dict:
    for biller in BILLERS:
        if biller["code"] == code:
            return biller
    raise AppError(code="biller_not_found", message="Biller not found.", status_code=404)



def pay_bill(
    db: Session,
    user: User,
    *,
    biller_code: str,
    amount: Decimal,
    funding_account_id: uuid.UUID,
    reference_note: str | None,
    idempotency_key: str | None,
) -> tuple[dict, bool]:
    check_rate_limit(f"payment:{user.id}", limit=settings.sensitive_rate_limit_attempts)
    biller = _biller(biller_code)
    stored_key = f"{user.id}:{idempotency_key}" if idempotency_key else None
    if stored_key:
        existing = db.scalar(
            select(Transaction).where(
                Transaction.idempotency_key == stored_key,
                Transaction.customer_id == user.id,
            )
        )
        if existing is not None:
            return _result(existing, biller), True

    payment_amount = quantize_money(amount)
    if payment_amount <= 0:
        raise AppError(
            code="invalid_amount",
            message="Enter a payment amount greater than zero.",
            status_code=422,
        )

    account = db.scalar(
        select(Account)
        .where(Account.id == funding_account_id, Account.customer_id == user.id)
        .with_for_update()
    )
    if account is None:
        raise AppError(code="account_not_found", message="Account not found.", status_code=404)
    if account.status != AccountStatus.ACTIVE:
        raise AppError(
            code="account_inactive",
            message="This account cannot make payments.",
            status_code=409,
        )
    if account.available_balance < payment_amount:
        raise AppError(
            code="insufficient_funds",
            message="The available balance is not sufficient.",
            status_code=409,
        )

    reference = generate_reference("PAY")
    account.available_balance = quantize_money(account.available_balance - payment_amount)
    account.current_balance = quantize_money(account.current_balance - payment_amount)
    account.version = (account.version or 1) + 1

    transaction = Transaction(
        customer_id=user.id,
        account_id=account.id,
        journal_id=uuid.uuid4(),
        reference=reference,
        idempotency_key=stored_key,
        transaction_type=TransactionType.BILL_PAYMENT,
        direction=TransactionDirection.DEBIT,
        amount=payment_amount,
        currency=account.currency,
        description=f"Bill payment • {biller['name_en']}",
        description_ar=f"سداد فاتورة • {biller['name_ar']}",
        counterparty=str(biller["name_en"]),
        status=TransactionStatus.POSTED,
        is_simulated=True,
        balance_after=account.available_balance,
    )
    db.add(transaction)
    db.flush()
    db.add(
        TransactionEntry(
            transaction_id=transaction.id,
            account_id=account.id,
            entry_type=TransactionDirection.DEBIT,
            amount=payment_amount,
        )
    )
    notification_service.notify(
        db,
        customer_id=user.id,
        category="transaction",
        title_en="Payment completed (simulated)",
        title_ar="تمت عملية الدفع (محاكاة)",
        body_en=f"{payment_amount} {account.currency} paid to {biller['name_en']}.",
        body_ar=f"تم دفع {payment_amount} {account.currency} إلى {biller['name_ar']}.",
        related_entity_type="transaction",
        related_entity_id=transaction.id,
        cta_route="/payments",
    )
    record_audit(
        db,
        actor=user,
        action="payment.simulated_completed",
        entity_type="transaction",
        entity_id=transaction.id,
        details={"biller": biller_code, "amount": str(payment_amount), "note": reference_note},
    )
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        if stored_key:
            existing = db.scalar(
                select(Transaction).where(
                    Transaction.idempotency_key == stored_key,
                    Transaction.customer_id == user.id,
                )
            )
            if existing is not None:
                return _result(existing, biller), True
        raise AppError(
            code="payment_conflict", message="Payment failed.", status_code=409
        ) from exc

    db.refresh(transaction)
    return _result(transaction, biller), False


def _result(transaction: Transaction, biller: dict) -> dict:
    return {
        "reference": transaction.reference,
        "status": transaction.status,
        "amount": transaction.amount,
        "currency": transaction.currency,
        "biller_code": biller["code"],
        "biller_name_en": biller["name_en"],
        "biller_name_ar": biller["name_ar"],
        "is_simulated": transaction.is_simulated,
        "created_at": transaction.occurred_at,
    }

