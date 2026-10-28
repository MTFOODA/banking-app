"""Card categories and server-owned eligibility for the fictional bank.

Product rows remain the source of names, availability and configured fees.
This module supplies the category rules; neither DOB nor ownership comes from
the application. No real card network provisioning or PIN is simulated here.
"""
from __future__ import annotations

from datetime import date
import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.banking import Account, AccountProduct, CardProduct
from app.models.user import User, CustomerProfile
from app.services.common import utcnow

CARD_CATEGORIES = (
    ('CP-GOLD-DEBIT', 'gold', 'Faisal Gold', 'فيصل جولد', 'Visa', False, False),
    ('CP-PLATINUM-DEBIT', 'platinum', 'Faisal Platinum', 'فيصل بلاتينيوم', 'Visa', False, False),
    ('CP-PLATINUM-FX', 'platinum_fx', 'Faisal Platinum FX', 'فيصل بلاتينيوم عملات', 'Visa', False, False),
    ('CP-YOUTH-DEBIT', 'youth', 'Faisal Youth', 'فيصل يوث', 'Visa', True, True),
    ('CP-MEEZA-DEBIT', 'meeza', 'Faisal Meeza', 'فيصل ميزة', 'Meeza', True, False),
    ('CP-MEEZA-BAB-REZQ', 'meeza_bab_rezq', 'Meeza Bab Rezq', 'ميزة باب رزق', 'Meeza', True, False),
)
RULES = {row[0]: row for row in CARD_CATEGORIES}
FOREIGN_CURRENCIES = ('USD', 'EUR', 'SAR')


def seed_catalogue(db: Session) -> int:
    """Add missing catalogue rows only. Caller owns commit/rollback."""
    added = 0
    existing = set(db.scalars(select(CardProduct.code)).all())
    for code, variant, en, ar, network, investment, youth in CARD_CATEGORIES:
        if code in existing:
            continue
        db.add(CardProduct(code=code, name_en=en, name_ar=ar, card_kind='debit', network=network,
            description_en='Development debit card. Bank approval required.',
            description_ar='بطاقة خصم للتجربة، تتطلب موافقة البنك.', annual_fee=0, is_active=True))
        added += 1
    # Make eligible currencies requestable through the existing account workflow.
    account_codes = set(db.scalars(select(AccountProduct.code)).all())
    for currency in FOREIGN_CURRENCIES:
        code = 'AP-CURRENT-' + currency
        if code not in account_codes:
            db.add(AccountProduct(code=code, name_en=f'{currency} Current Account',
                name_ar=f'حساب جارٍ {currency}', account_type='current', currency=currency,
                description_en='Foreign currency account for the development bank.',
                description_ar='حساب عملة أجنبية للبنك التجريبي.', minimum_balance=0, is_active=True))
            added += 1
    db.flush()
    return added


def age_on(born: date, today: date) -> int:
    return today.year - born.year - ((today.month, today.day) < (born.month, born.day))


def eligibility_reason(user: User, rule: tuple, accounts: list[Account]) -> str | None:
    if not user.is_active or user.is_locked or not user.enrollment_completed:
        return 'card_customer_ineligible'
    if rule[6]:
        profile = user.profile
        born = profile.date_of_birth if profile else None
        if not profile or not profile.identity_verified or not born or born > utcnow().date():
            return 'card_age_unverified'
        if age_on(born, utcnow().date()) >= 21:
            return 'card_youth_age'
    if not accounts:
        return 'card_fx_account_required' if rule[1] == 'platinum_fx' else (
            'card_investment_required' if rule[5] else 'card_eligible_account_required')
    return None


def account_eligible(account: Account, rule: tuple) -> bool:
    currencies = FOREIGN_CURRENCIES if rule[1] == 'platinum_fx' else ('EGP',)
    return (account.status == 'active' and account.currency in currencies
        and (not rule[5] or account.account_type == 'investment')
        and account.product is not None and account.product.is_active)


def catalogue(db: Session, user: User) -> list[dict]:
    products = {p.code: p for p in db.scalars(select(CardProduct).where(CardProduct.is_active.is_(True)))}
    owned = list(db.scalars(select(Account).where(Account.customer_id == user.id).order_by(Account.opened_at)))
    items = []
    for rule in CARD_CATEGORIES:
        product = products.get(rule[0])
        if not product:
            continue
        accounts = [a for a in owned if account_eligible(a, rule)]
        reason = eligibility_reason(user, rule, accounts)
        items.append(dict(code=product.code, variant=rule[1], name_en=product.name_en,
            name_ar=product.name_ar, network=product.network, annual_fee=product.annual_fee,
            fee_currency='EGP', investment_only=rule[5], under_21_only=rule[6],
            currencies=list(FOREIGN_CURRENCIES if rule[1] == 'platinum_fx' else ('EGP',)),
            eligible=reason is None, ineligibility_reason=reason,
            accounts=[dict(id=a.id, account_number_masked=a.account_number_masked,
                currency=a.currency, account_type=a.account_type) for a in accounts]))
    return items


def validate_issue(db: Session, user: User, data: dict, *, lock: bool = False) -> tuple[CardProduct, Account, dict]:
    rule = RULES.get(str(data.get('card_product_code', '')))
    if rule is None:
        raise AppError(code='card_product_unavailable', message='Select an available card category.', status_code=422)
    if lock:
        user = db.scalar(select(User).where(User.id == user.id).with_for_update().execution_options(populate_existing=True))
        # Reload DOB from its server-owned profile even if previously cached.
        db.scalar(select(CustomerProfile).where(CustomerProfile.user_id == user.id)
            .with_for_update().execution_options(populate_existing=True))
    stmt = select(CardProduct).where(CardProduct.code == rule[0], CardProduct.is_active.is_(True))
    product = db.scalar(stmt.with_for_update().execution_options(populate_existing=True) if lock else stmt)
    if product is None:
        raise AppError(code='card_product_unavailable', message='This card category is unavailable.', status_code=409)
    try:
        identity = uuid.UUID(str(data.get('account_id')))
    except (ValueError, TypeError):
        raise AppError(code='invalid_request_data', message='Select an eligible account.', status_code=422)
    stmt = select(Account).where(Account.id == identity, Account.customer_id == user.id)
    account = db.scalar(stmt.with_for_update().execution_options(populate_existing=True) if lock else stmt)
    if account is None:
        raise AppError(code='account_not_found', message='Account not found.', status_code=404)
    reason = eligibility_reason(user, rule, [account] if account_eligible(account, rule) else [])
    if reason:
        raise AppError(code=reason, message='The customer or selected account is not eligible for this card.', status_code=409)
    canonical = dict(card_product_code=product.code, product_name_en=product.name_en,
        product_name_ar=product.name_ar, account_id=str(account.id),
        account_number_masked=account.account_number_masked, currency=account.currency,
        account_type=account.account_type)
    return product, account, canonical
