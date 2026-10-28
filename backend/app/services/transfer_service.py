"""Beneficiary management and transfer history."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.banking import Account, Beneficiary
from app.models.user import User
from app.services.common import record_audit
from app.services.transaction_service import list_transactions


def list_beneficiaries(db: Session, user: User) -> list[Beneficiary]:
    return list(
        db.scalars(
            select(Beneficiary)
            .where(Beneficiary.customer_id == user.id, Beneficiary.status == "active")
            .order_by(Beneficiary.name)
        ).all()
    )


def create_beneficiary(
    db: Session,
    user: User,
    *,
    name: str,
    nickname: str | None,
    bank_name: str,
    account_number: str,
    iban: str | None,
    currency: str,
) -> Beneficiary:
    from app.services.registration_service import normalize_registration_identifier
    from app.core.security import hash_identifier
    try:
        digits = normalize_registration_identifier(account_number)
    except ValueError:
        digits = ""
    destination = db.scalar(select(Account).where(Account.account_number_hash == hash_identifier(f"acct:{digits}"))) if digits else None
    if not destination or destination.status != "active" or destination.currency != currency.upper() or not destination.customer.is_active:
        raise AppError(
            code="invalid_beneficiary", message="Enter a valid account number.", status_code=422
        )
    beneficiary = Beneficiary(
        customer_id=user.id,
        destination_account_id=destination.id,
        name=name.strip(),
        nickname=nickname,
        bank_name=bank_name.strip(),
        account_number_masked=f"**** {digits[-4:]}",
        iban=destination.iban,
        currency=currency.upper(),
    )
    db.add(beneficiary)
    db.flush()
    record_audit(
        db,
        actor=user,
        action="beneficiary.created",
        entity_type="beneficiary",
        entity_id=beneficiary.id,
    )
    db.commit()
    db.refresh(beneficiary)
    return beneficiary


def delete_beneficiary(db: Session, user: User, beneficiary_id: uuid.UUID) -> None:
    beneficiary = db.scalar(
        select(Beneficiary).where(
            Beneficiary.id == beneficiary_id, Beneficiary.customer_id == user.id
        )
    )
    if beneficiary is None:
        raise AppError(
            code="beneficiary_not_found", message="Beneficiary not found.", status_code=404
        )
    beneficiary.status = "deleted"
    record_audit(
        db,
        actor=user,
        action="beneficiary.deleted",
        entity_type="beneficiary",
        entity_id=beneficiary.id,
    )
    db.commit()


def list_transfers(db: Session, user: User, *, page: int, page_size: int):
    return list_transactions(
        db, user, transaction_type="transfer", page=page, page_size=page_size
    )
