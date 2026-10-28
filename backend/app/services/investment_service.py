"""Immediate fictional subscriptions/redemptions in one authorized transaction."""
import calendar
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP
import uuid
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.exceptions import AppError
from app.core.security import hash_token
from app.models.banking import Account
from app.models.content import BankingProduct
from app.models.investment import InvestmentHolding, InvestmentOperation, InvestmentTerms
from app.models.transactions import Transaction, TransactionEntry
from app.schemas.investment import InvestmentAction
from app.services import security_service, notification_service
from app.services.common import generate_reference, record_audit, utcnow

CENT = Decimal('0.01')


def money(value):
    return Decimal(value).quantize(CENT, rounding=ROUND_HALF_UP)


def fail(code, message, status=422):
    raise AppError(code=code, message=message, status_code=status)


def seed_products(db: Session) -> int:
    """Only add distinct fictional products. Never change existing catalogue data."""
    if settings.environment not in {'development', 'test'}:
        raise RuntimeError('Fictional investment fixtures are development/test only')
    created = 0
    for suffix, years, name_en, name_ar in [
        ('3Y', 3, 'Three-year certificate', 'الشهادة الثلاثية'),
        ('4Y', 4, 'Four-year certificate', 'الشهادة الرباعية'),
        ('5Y', 5, 'Five-year certificate', 'الشهادة الخماسية'),
        ('7Y', 7, 'Seven-year certificate', 'الشهادة السباعية'),
        ('INCOME', 0, 'Income investment fund', 'صندوق الاستثمار ذو العائد الدوري'),
        ('GROWTH', 0, 'Growth investment fund', 'صندوق الاستثمار التراكمي')]:
        code = f'INV-DEMO-{suffix}'
        product = db.scalar(select(BankingProduct).where(BankingProduct.code == code))
        if product:
            continue
        product = BankingProduct(code=code, name_en=name_en, name_ar=name_ar,
            product_type='certificate' if years else 'fund', summary_en='Fictional banking simulation.',
            summary_ar='محاكاة مصرفية تجريبية.', details_en='No real investment or guaranteed profit. Fund unit prices are simulated.',
            details_ar='استثمار تجريبي دون عائد مضمون. أسعار وثائق الصناديق محاكاة.',
            pricing_note_en='No guaranteed return; early redemption policy shown before confirmation.',
            pricing_note_ar='لا يوجد عائد مضمون؛ تظهر سياسة الكسر قبل التأكيد.', cta_route='/products', is_active=True)
        db.add(product)
        db.flush()
        minimum = Decimal('10000') if years == 4 else Decimal('1000')
        db.add(InvestmentTerms(product_id=product.id, term_months=years * 12,
            minimum_amount=minimum, amount_step=minimum if years else Decimal('100'),
            unit_price=Decimal('1') if years else Decimal('100'),
            max_penalty_percent=Decimal(str(settings.investment_max_penalty_percent)) if years else Decimal('0')))
        created += 1
    db.commit()
    return created


def products(db: Session) -> list[dict]:
    now = utcnow()
    rows = db.execute(select(BankingProduct, InvestmentTerms).join(InvestmentTerms,
        BankingProduct.id == InvestmentTerms.product_id).where(BankingProduct.is_active.is_(True))).all()
    return [{'id': str(p.id), 'code': p.code, 'name_en': p.name_en, 'name_ar': p.name_ar,
        'product_type': p.product_type, 'term_months': t.term_months,
        'minimum_amount': str(t.minimum_amount), 'amount_step': str(t.amount_step),
        'unit_price': str(t.unit_price), 'max_penalty_percent': str(t.max_penalty_percent),
        'currency': 'EGP', 'is_simulated': True}
        for p, t in rows if (p.publish_at is None or p.publish_at <= now) and (p.expires_at is None or p.expires_at > now)]


def maturity(opened: datetime, months: int):
    if not months:
        return None
    year, month = divmod(opened.year * 12 + opened.month - 1 + months, 12)
    month += 1
    return opened.replace(year=year, month=month, day=min(opened.day, calendar.monthrange(year, month)[1]))


def redemption(holding: InvestmentHolding, now: datetime | None = None) -> dict:
    now = now or utcnow()
    total = max(1, (holding.matures_at.date() - holding.opened_at.date()).days) if holding.matures_at else 1
    remaining = max(0, min(total, (holding.matures_at.date() - now.date()).days)) if holding.matures_at else 0
    penalty = money(holding.principal * holding.max_penalty_percent / Decimal('100') * Decimal(remaining) / Decimal(total))
    return {'principal': str(holding.principal), 'penalty': str(penalty),
        'net_credit': str(money(holding.principal - penalty)), 'remaining_days': remaining,
        'total_days': total, 'max_penalty_percent': str(holding.max_penalty_percent)}


def positions(db: Session, user) -> list[dict]:
    rows = db.execute(select(InvestmentHolding, BankingProduct).join(BankingProduct,
        BankingProduct.id == InvestmentHolding.product_id).where(InvestmentHolding.customer_id == user.id)
        .order_by(InvestmentHolding.created_at.desc())).all()
    return [{'id': str(h.id), 'name_en': p.name_en, 'name_ar': p.name_ar, 'product_type': p.product_type,
        'account_id': str(h.account_id), 'status': h.status, 'principal': str(h.principal),
        'units': str(h.units), 'unit_price': str(h.unit_price), 'opened_at': h.opened_at.isoformat(),
        'matures_at': h.matures_at.isoformat() if h.matures_at else None,
        'redemption': redemption(h), 'is_simulated': True} for h, p in rows]


def quote(db: Session, user, action: InvestmentAction, *, lock=False) -> dict:
    holding = None
    if action.action == 'subscribe':
        stmt = select(InvestmentTerms).where(InvestmentTerms.product_id == action.product_id)
        terms = db.scalar(stmt.with_for_update() if lock else stmt)
        product = db.get(BankingProduct, action.product_id)
        now = utcnow()
        if (not product or not terms or not product.is_active or
            (product.publish_at and product.publish_at > now) or (product.expires_at and product.expires_at <= now)):
            fail('investment_unavailable', 'This product is not available.', 404)
        account_id = action.account_id
        amount = money(action.amount)
        if amount < terms.minimum_amount or amount % terms.amount_step or amount % terms.unit_price:
            fail('investment_amount', 'Use the product minimum and allowed amount increments.')
        economic = {'principal': str(amount), 'penalty': '0.00', 'net_credit': '0.00',
            'unit_price': str(terms.unit_price), 'units': str(amount / terms.unit_price),
            'term_months': terms.term_months, 'max_penalty_percent': str(terms.max_penalty_percent),
            'minimum_amount': str(terms.minimum_amount), 'amount_step': str(terms.amount_step)}
    else:
        stmt = select(InvestmentHolding).where(InvestmentHolding.id == action.holding_id, InvestmentHolding.customer_id == user.id)
        holding = db.scalar((stmt.with_for_update() if lock else stmt).execution_options(populate_existing=True))
        if not holding:
            fail('investment_not_found', 'Investment not found.', 404)
        if holding.status != 'active':
            fail('investment_redeemed', 'This investment has already been redeemed.', 409)
        product = db.get(BankingProduct, holding.product_id)
        account_id = holding.account_id
        economic = redemption(holding)
    stmt = select(Account).where(Account.id == account_id, Account.customer_id == user.id)
    account = db.scalar((stmt.with_for_update() if lock else stmt).execution_options(populate_existing=True))
    if not account:
        fail('account_not_found', 'Account not found.', 404)
    if account.status != 'active' or account.currency != 'EGP':
        fail('account_inactive', 'An active EGP account is required.', 409)
    if action.action == 'subscribe' and min(account.available_balance, account.current_balance) < amount:
        fail('insufficient_funds', 'The available balance is not sufficient.', 409)
    result = {'action': action.action, 'account_id': str(account.id), 'account_label': account.account_number_masked,
        'name_en': product.name_en, 'name_ar': product.name_ar, 'currency': 'EGP', 'is_simulated': True, **economic}
    result['binding'] = security_service.fingerprint({'action': action.model_dump(mode='json', exclude={'authorization_token'}), 'terms': result})
    return result


def execute(db: Session, user, action, key: str) -> dict:
    if not key or not 8 <= len(key) <= 40:
        fail('idempotency_required', 'A retry key of 8–40 characters is required.')
    security_service.throttle(db, f'investments:{user.id}', 20)
    user = security_service.lock_user(db, user)
    request = InvestmentAction.model_validate(action.model_dump(exclude={'authorization_token'}))
    fingerprint = security_service.fingerprint(request.model_dump(mode='json'))
    existing = db.scalar(select(InvestmentOperation).where(InvestmentOperation.customer_id == user.id,
        InvestmentOperation.idempotency_key == key))
    if existing:
        if existing.request_fingerprint != fingerprint or existing.authorization_hash != hash_token(action.authorization_token):
            fail('idempotency_conflict', 'The retry key belongs to another operation.', 409)
        return existing.receipt
    review = quote(db, user, request, lock=True)
    security_service.consume_grant(db, user, action.authorization_token, f'investment_{action.action}', review['binding'])
    account = db.get(Account, uuid.UUID(review['account_id']))
    now = utcnow()
    try:
        if action.action == 'subscribe':
            amount = money(action.amount)
            holding = InvestmentHolding(customer_id=user.id, account_id=account.id, product_id=action.product_id,
                principal=amount, units=Decimal(review['units']), unit_price=Decimal(review['unit_price']),
                max_penalty_percent=Decimal(review['max_penalty_percent']), opened_at=now,
                matures_at=maturity(now, review['term_months']), status='active')
            db.add(holding)
            db.flush()
            account.current_balance -= amount
            account.available_balance -= amount
            movement, direction = amount, 'debit'
        else:
            holding = db.get(InvestmentHolding, action.holding_id)
            movement, direction = Decimal(review['net_credit']), 'credit'
            account.current_balance += movement
            account.available_balance += movement
            holding.status, holding.redeemed_at = 'redeemed', now
        account.version += 1
        transaction = Transaction(customer_id=user.id, account_id=account.id, reference=generate_reference('INV'),
            transaction_type=f'investment_{action.action}', direction=direction, amount=movement, currency='EGP',
            description=review['name_en'], description_ar=review['name_ar'], status='posted', is_simulated=True,
            balance_after=account.current_balance, occurred_at=now)
        db.add(transaction)
        db.flush()
        entries = []
        def entry(direction, amount, bucket, cash=False):
            if amount:
                entries.append(TransactionEntry(transaction_id=transaction.id, account_id=account.id if cash else None,
                    investment_holding_id=holding.id, ledger_bucket=bucket, entry_type=direction, amount=amount))
        if action.action == 'subscribe':
            entry('debit', movement, 'customer_cash', True)
            entry('credit', movement, 'investment_principal')
        else:
            entry('debit', holding.principal, 'investment_principal')
            entry('credit', movement, 'customer_cash', True)
            entry('credit', Decimal(review['penalty']), 'redemption_fee')
        assert sum(e.amount for e in entries if e.entry_type == 'debit') == sum(e.amount for e in entries if e.entry_type == 'credit')
        db.add_all(entries)
        receipt = {**review, 'holding_id': str(holding.id), 'reference': transaction.reference, 'status': 'posted',
            'amount': str(movement), 'timestamp': now.isoformat(), 'matures_at': holding.matures_at.isoformat() if holding.matures_at else None}
        db.add(InvestmentOperation(customer_id=user.id, holding_id=holding.id, transaction_id=transaction.id,
            idempotency_key=key, request_fingerprint=fingerprint, authorization_hash=hash_token(action.authorization_token), receipt=receipt))
        record_audit(db, actor=user, action=f'investment.{action.action}', entity_type='investment_holding', entity_id=holding.id,
            details={'reference': transaction.reference, 'principal': str(holding.principal), 'penalty': review['penalty']})
        notification_service.notify(db, customer_id=user.id, category='investment', title_en='Investment operation completed (simulated)',
            title_ar='تم تنفيذ عملية الاستثمار (محاكاة)', body_en=transaction.reference, body_ar=transaction.reference,
            related_entity_type='investment_holding', related_entity_id=holding.id, cta_route='/products')
        db.commit()
        return receipt
    except Exception:
        db.rollback()
        raise
