"""Atomic, scoped transfers across internal and simulated outbound routes."""
from __future__ import annotations

from decimal import Decimal
import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import AppError
from app.core.security import hash_token
from app.models.banking import Account, Beneficiary
from app.models.transactions import Transaction, TransactionEntry
from app.models.user import User
from app.schemas.transaction import TransferCreate
from app.schemas.transfer_recipient import OUTBOUND_TYPES, TRANSFER_TYPES
from app.core.security import hash_identifier
from app.services import notification_service, security_service
from app.services.common import generate_reference, quantize_money, record_audit
from app.services.common import utcnow


def transfer_fingerprint(draft: TransferCreate) -> str:
    data = draft.model_dump(mode="json", exclude={"authorization_token"})
    if draft.fx_quote_id is None:data.pop('fx_quote_id',None)
    if draft.transfer_type is None:
        # Preserve existing fingerprints/grants/retries from before this feature.
        data.pop('transfer_type',None)
        data.pop('recipient',None)
    data["amount"] = str(quantize_money(draft.amount))
    data["currency"] = draft.currency.upper()
    data["fees"] = "0.00"
    return security_service.fingerprint(data)


def authorization_binding(db: Session, draft: TransferCreate, destination_id=None) -> str:
    if destination_id is None:
        destination_id = draft.destination_account_id
        if draft.beneficiary_id:
            beneficiary = db.get(Beneficiary, draft.beneficiary_id)
            if beneficiary:
                destination_id = beneficiary.destination_account_id
                if not destination_id and beneficiary.iban:
                    destination_id = db.scalar(select(Account.id).where(Account.iban == beneficiary.iban))
    binding={"draft": transfer_fingerprint(draft), "destination": str(destination_id)}
    if draft.fx_quote_id:
        from app.models.fx_transfer import OwnFxQuote
        from app.services.own_fx_service import quote_binding
        snapshot=db.get(OwnFxQuote,draft.fx_quote_id)
        binding['fx_snapshot']=quote_binding(snapshot) if snapshot else None
    return security_service.fingerprint(binding)


def _error(code: str, message: str, status: int = 422):
    raise AppError(code=code, message=message, status_code=status)


def _resolve_accounts(db: Session, user: User, draft: TransferCreate, *, lock: bool = False,allow_fx: bool=False):
    destination_id = draft.destination_account_id
    beneficiary = None
    if draft.beneficiary_id:
        stmt = select(Beneficiary).where(Beneficiary.id == draft.beneficiary_id,
            Beneficiary.customer_id == user.id, Beneficiary.status == "active")
        beneficiary = db.scalar((stmt.with_for_update() if lock else stmt).execution_options(populate_existing=True))
        if not beneficiary:
            _error("beneficiary_not_found", "Beneficiary not found.", 404)
        destination_id = beneficiary.destination_account_id
        if destination_id is None and beneficiary.iban:
            destination_id = db.scalar(select(Account.id).where(Account.iban == beneficiary.iban))
        if not destination_id:
            _error("destination_unsupported", "This beneficiary has no verified internal destination. External transfers are unavailable.")
    ids = {draft.source_account_id, destination_id}
    stmt = select(Account).where(Account.id.in_(ids)).order_by(Account.id)
    accounts = {a.id: a for a in db.scalars((stmt.with_for_update() if lock else stmt)
                .execution_options(populate_existing=True)).all()}
    source, destination = accounts.get(draft.source_account_id), accounts.get(destination_id)
    if not source or source.customer_id != user.id:
        _error("account_not_found", "Account not found.", 404)
    if not destination or (not beneficiary and destination.customer_id != user.id):
        _error("invalid_destination", "The destination is not eligible.")
    if source.id == destination.id:
        _error("invalid_destination", "Choose a different destination account.")
    if draft.transfer_type=='internal' and destination.customer_id==user.id:
        _error('invalid_destination','Use the own-accounts route for your own account.')
    if source.status != "active" or destination.status != "active":
        _error("account_inactive", "Both accounts must be active.", 409)
    receiver = db.get(User, destination.customer_id)
    if not receiver or not receiver.is_active or receiver.is_locked or (receiver.locked_until and receiver.locked_until > utcnow()):
        _error("invalid_destination", "The destination is not eligible.")
    if draft.transfer_type == 'internal' and (not user.profile or not receiver.profile or user.profile.bank_code != receiver.profile.bank_code):
        _error("invalid_destination", "Choose a destination at the same bank or use a domestic bank transfer.")
    conversion_allowed=allow_fx and draft.transfer_type=='own_accounts' and not beneficiary and destination.customer_id==user.id
    if source.currency != draft.currency.upper() or (destination.currency != source.currency and not conversion_allowed) or (beneficiary and beneficiary.currency != source.currency):
        _error("currency_mismatch", "Both accounts must use the selected currency.")
    if draft.amount > Decimal(settings.transfer_limit):
        _error("transfer_limit", "The amount exceeds the configured transfer limit.")
    if source.available_balance < draft.amount or source.current_balance < draft.amount:
        _error("insufficient_funds", "The available balance is not sufficient for this transfer.", 409)
    return source, destination, beneficiary


def quote_transfer(db: Session, user: User, draft: TransferCreate,*,create_fx_quote:bool=True) -> dict:
    if draft.transfer_type in OUTBOUND_TYPES:
        return _outbound_quote(db,user,draft)
    source, destination, beneficiary = _resolve_accounts(db, user, draft,allow_fx=True)
    fx_fields={}
    if source.currency!=destination.currency:
        from app.services import own_fx_service
        if draft.fx_quote_id:
            snapshot=own_fx_service.get_quote(db,user,draft,source,destination)
        elif create_fx_quote:
            snapshot=own_fx_service.create_quote(db,user,draft,source,destination)
        else:_error('fx_quote_required','Review and freeze an exchange quote before authorizing.',409)
        fx_fields=own_fx_service.response(snapshot)
    elif draft.fx_quote_id:
        _error('invalid_fx_quote','This same-currency transfer does not require an FX quote.',409)
    return {**fx_fields,"transfer_type": draft.transfer_type or ('internal' if beneficiary else 'own_accounts'),
        "delivery_mode": 'simulation', "source_account_id": str(source.id), "source_label": source.account_number_masked,
        "destination_label": destination.account_number_masked,
        "beneficiary": beneficiary.name if beneficiary else destination.account_number_masked,
        "amount": str(quantize_money(draft.amount)), "currency": source.currency, "fees": "0.00",
        "total_debit": str(quantize_money(draft.amount)), "available_balance": str(source.available_balance),
        "transfer_limit": str(settings.transfer_limit), "is_simulated": True}


def execute_transfer(db: Session, user: User, *, draft: TransferCreate, idempotency_key: str) -> tuple[dict, bool]:
    if not idempotency_key or not 8 <= len(idempotency_key) <= 40:
        _error("idempotency_required", "An idempotency key of 8 to 40 characters is required.")
    if not draft.authorization_token:
        _error("authorization_required", "Authorize and enter the transfer token first.", 403)
    security_service.throttle(db, f"transfer:{user.id}", settings.sensitive_rate_limit_attempts)
    user = security_service.lock_user(db, user)
    stored_key = f"{user.id}:{idempotency_key}"
    binding = transfer_fingerprint(draft)
    existing = db.scalar(select(Transaction).where(Transaction.idempotency_key == stored_key))
    if existing:
        if existing.request_fingerprint != binding or existing.authorization_hash != hash_token(draft.authorization_token):
            _error("idempotency_conflict", "This retry key was used for different transfer details.", 409)
        return _transfer_result(existing), True
    operation_binding = authorization_binding(db, draft)
    security_service.consume_grant(db, user, draft.authorization_token, "transfer", operation_binding)
    if draft.transfer_type in OUTBOUND_TYPES:
        return _execute_outbound(db,user,draft,stored_key,binding),False
    source, destination, beneficiary = _resolve_accounts(db, user, draft, lock=True,allow_fx=True)
    fx_snapshot=None
    if source.currency!=destination.currency:
        from app.services import own_fx_service
        fx_snapshot=own_fx_service.get_quote(db,user,draft,source,destination,lock=True)
    elif draft.fx_quote_id:
        _error('invalid_fx_quote','Review this same-currency transfer again.',409)
    if authorization_binding(db, draft, destination.id) != operation_binding:
        _error("invalid_authorization", "The destination changed. Review and authorize again.", 403)
    amount = quantize_money(draft.amount)
    received=fx_snapshot.received_amount if fx_snapshot else amount
    if fx_snapshot:
        from app.services.own_fx_service import MAX_MONEY
        if max(destination.current_balance,destination.available_balance)+received>MAX_MONEY:
            _error('fx_amount_invalid','The destination balance would exceed the supported range.',409)
    journal_id = uuid.uuid4()
    source.available_balance = quantize_money(source.available_balance - amount)
    source.current_balance = quantize_money(source.current_balance - amount)
    destination.available_balance = quantize_money(destination.available_balance + received)
    destination.current_balance = quantize_money(destination.current_balance + received)
    source.version += 1
    destination.version += 1
    debit = Transaction(customer_id=user.id, account_id=source.id, journal_id=journal_id,
        transfer_metadata={'transfer_type':draft.transfer_type,'delivery_status':'posted',
            'recipient_name':beneficiary.name if beneficiary else destination.account_number_masked,
            'purpose':draft.purpose,'note':draft.note,**(own_fx_service.response(fx_snapshot) if fx_snapshot else {})} if draft.transfer_type else None,
        reference=generate_reference("TRF"), idempotency_key=stored_key, request_fingerprint=binding,
        authorization_hash=hash_token(draft.authorization_token), transaction_type="transfer", direction="debit",
        amount=amount, currency=source.currency, description=f"Transfer to {destination.account_number_masked}",
        counterparty=destination.account_number_masked, status="posted", is_simulated=True, balance_after=source.available_balance)
    credit = Transaction(customer_id=destination.customer_id, account_id=destination.id, journal_id=journal_id,
        reference=generate_reference("TRF"), transaction_type="transfer", direction="credit", amount=received,
        currency=destination.currency, description=f"Transfer from {source.account_number_masked}",
        counterparty=source.account_number_masked, status="posted", is_simulated=True, balance_after=destination.available_balance)
    db.add_all([debit, credit])
    db.flush()
    db.add_all([TransactionEntry(transaction_id=debit.id, account_id=source.id, entry_type="debit", amount=amount),
                TransactionEntry(transaction_id=credit.id, account_id=destination.id, entry_type="credit", amount=received)])
    if fx_snapshot:
        db.add_all([TransactionEntry(transaction_id=debit.id,account_id=None,entry_type='credit',amount=amount,ledger_bucket='fx_clearing'),
            TransactionEntry(transaction_id=credit.id,account_id=None,entry_type='debit',amount=received,ledger_bucket='fx_clearing')])
    notification_service.notify(db, customer_id=user.id, category="transaction",
        title_en="Transfer completed (simulated)", title_ar="تم التحويل (محاكاة)",
        body_en=f"{amount} {source.currency} sent to {destination.account_number_masked}.",
        body_ar=f"تم تحويل {amount} {source.currency} إلى {destination.account_number_masked}.",
        related_entity_type="transaction", related_entity_id=debit.id, cta_route="/transactions")
    record_audit(db, actor=user, action="transfer.executed", entity_type="transaction", entity_id=debit.id,
        details={"amount": str(amount), "journal_id": str(journal_id), "simulated": True,
                 "purpose": draft.purpose, "note": draft.note})
    try:
        db.commit()
    except Exception:
        db.rollback()
        raise
    db.refresh(debit)
    return _transfer_result(debit), False


def _transfer_result(transaction: Transaction) -> dict:
    metadata=transaction.transfer_metadata or {}
    return {"transfer_type":metadata.get('transfer_type'), 'delivery_status':metadata.get('delivery_status'),
        'provider_reference':metadata.get('provider_reference'),'recipient_name':metadata.get('recipient_name'),
        'bank_name':metadata.get('bank_name'),'country_code':metadata.get('country_code'),
        'purpose':metadata.get('purpose'),'note':metadata.get('note'),
        **{field:metadata.get(field) for field in ['exchange_rate','received_amount','received_currency','rate_provider','rate_as_of']},
        "reference": transaction.reference, "status": metadata.get('delivery_status') if metadata.get('delivery_status')=='simulated_completed' else transaction.status, "amount": transaction.amount,
        "fees": Decimal("0.00"), "total_debit": transaction.amount, "currency": transaction.currency,
        "source_account_id": transaction.account_id, "destination_label": transaction.counterparty or "",
        "is_simulated": transaction.is_simulated, "created_at": transaction.occurred_at, "journal_id": transaction.journal_id}


def transfer_options():
    from app.services.transfer_delivery import available
    return [{'transfer_type':kind,'available':kind not in OUTBOUND_TYPES or available(),
        'delivery_mode':'simulation' if kind not in OUTBOUND_TYPES or available() else 'not_configured',
        'same_currency_only':kind!='own_accounts','fees':'0.00','transfer_limit':str(settings.transfer_limit),
        'currencies':['EGP'] if kind in {'external_domestic','wallet','instapay'} else None} for kind in TRANSFER_TYPES]


def _outbound_source(db,user,draft,lock=False):
    from app.services.transfer_delivery import provider
    provider()  # Fail before a debit or a success receipt if delivery is disabled.
    stmt=select(Account).where(Account.id==draft.source_account_id,Account.customer_id==user.id)
    source=db.scalar((stmt.with_for_update() if lock else stmt).execution_options(populate_existing=True))
    if not source:_error('account_not_found','Account not found.',404)
    if source.status!='active' or not source.product or not source.product.is_active:
        _error('account_inactive','The source account is not eligible.',409)
    if source.currency!=draft.currency:_error('currency_mismatch','Use the source account currency; FX conversion is unavailable.')
    if draft.amount>Decimal(settings.transfer_limit):_error('transfer_limit','The amount exceeds the configured transfer limit.')
    if min(source.available_balance,source.current_balance)<draft.amount:_error('insufficient_funds','Insufficient available balance.',409)
    return source


def _outbound_quote(db,user,draft):
    source=_outbound_source(db,user,draft)
    recipient=draft.recipient
    return {'transfer_type':draft.transfer_type,'source_account_id':str(source.id),
        'source_label':source.account_number_masked,'destination_label':_masked_recipient(recipient.destination),
        'beneficiary':recipient.name,'bank_name':recipient.bank_name,'country_code':recipient.country_code,
        'swift_code':recipient.swift_code,'amount':str(quantize_money(draft.amount)),'currency':source.currency,
        'fees':'0.00','total_debit':str(quantize_money(draft.amount)),
        'available_balance':str(source.available_balance),'transfer_limit':str(settings.transfer_limit),
        'is_simulated':True,'delivery_mode':'simulation','recipient_network_verified':False}


def _execute_outbound(db,user,draft,stored_key,binding):
    from app.services.transfer_delivery import provider
    source=_outbound_source(db,user,draft,lock=True)
    receipt=provider().simulate(draft.transfer_type)
    if receipt.status!='simulated_completed':
        _error('transfer_delivery_failed','Transfer simulation did not complete.',503)
    amount=quantize_money(draft.amount);recipient=draft.recipient
    masked=_masked_recipient(recipient.destination)
    title_en,title_ar={
        'external_domestic':('Domestic bank transfer','تحويل إلى بنك داخل مصر'),
        'international':('International transfer','تحويل دولي'),
        'wallet':('Mobile wallet transfer','تحويل إلى محفظة'),
        'instapay':('InstaPay transfer','تحويل إنستاباي'),
    }[draft.transfer_type]
    source.available_balance=quantize_money(source.available_balance-amount)
    source.current_balance=quantize_money(source.current_balance-amount);source.version+=1
    metadata={'transfer_type':draft.transfer_type,'delivery_status':receipt.status,
        'purpose':draft.purpose,'note':draft.note,
        'provider_reference':receipt.reference,'recipient_name':recipient.name,
        'bank_name':recipient.bank_name,'country_code':recipient.country_code,'swift_code':recipient.swift_code,
        'destination_hash':hash_identifier(f'route:{draft.transfer_type}:{recipient.destination}')}
    debit=Transaction(customer_id=user.id,account_id=source.id,journal_id=uuid.uuid4(),
        reference=generate_reference('TRF'),idempotency_key=stored_key,request_fingerprint=binding,
        authorization_hash=hash_token(draft.authorization_token),transaction_type='transfer',direction='debit',
        amount=amount,currency=source.currency,description=f'{title_en} (simulation) to {masked}',
        description_ar=f'{title_ar} (محاكاة) إلى {masked}',
        counterparty=masked,status='posted',is_simulated=True,balance_after=source.available_balance,
        transfer_metadata=metadata)
    db.add(debit);db.flush()
    db.add_all([TransactionEntry(transaction_id=debit.id,account_id=source.id,entry_type='debit',amount=amount),
        TransactionEntry(transaction_id=debit.id,account_id=None,entry_type='credit',amount=amount,
            ledger_bucket=draft.transfer_type+'_clearing')])
    notification_service.notify(db,customer_id=user.id,category='transaction',
        title_en='Transfer simulation completed',title_ar='اكتملت محاكاة التحويل',
        body_en=f'{amount} {source.currency} debited in the local simulation. No external network payment was sent.',
        body_ar=f'تم خصم {amount} {source.currency} في المحاكاة المحلية. لم يتم إرسال دفعة لشبكة خارجية.',
        related_entity_type='transaction',related_entity_id=debit.id,cta_route='/transactions')
    record_audit(db,actor=user,action='transfer.executed',entity_type='transaction',entity_id=debit.id,
        details={'transfer_type':draft.transfer_type,'amount':str(amount),'simulated':True,'journal_id':str(debit.journal_id)})
    try:db.commit()
    except Exception:db.rollback();raise
    db.refresh(debit)
    return _transfer_result(debit)


def _masked_recipient(value):
    return value[:2]+'***@instapay' if '@' in value else '**** '+value[-4:]
