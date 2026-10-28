"""Explicit, idempotent local fixtures. Never change existing credentials/balances."""
import re
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import assess_password, hash_identifier, hash_password, verify_password
from app.models.banking import Account, AccountProduct, Card, CardProduct
from app.models.content import BankingProduct
from app.models.investment import InvestmentOperation
from app.models.transactions import Transaction, TransactionEntry
from app.models.user import CustomerPreference, CustomerProfile, User
from app.schemas.investment import InvestmentAction, InvestmentExecute
from app.services import investment_service, security_service, username_service
from app.services.common import generate_reference, record_audit, utcnow

INVESTORS = (
    ('0910', 'Mariam', 'Investor', 'مريم', 'استثمار', ('3Y', '4Y', 'INCOME')),
    ('0911', 'Tarek', 'Investor', 'طارق', 'استثمار', ('5Y', '7Y', 'GROWTH')),
)


def _guard():
    if settings.environment not in {'development', 'test'}:
        raise RuntimeError('Fictional customer fixtures are development/test only')


def assign_enrolled_usernames(db: Session) -> int:
    """Caller commits. Unenrolled customers still choose their own username."""
    _guard()
    changed = 0
    users = db.scalars(select(User).where(User.enrollment_completed.is_(True), User.username.is_(None))
                       .order_by(User.id).with_for_update()).all()
    for user in users:
        if user.profile:
            base = re.sub(r'[^a-z0-9]', '',
                          f'{user.profile.first_name_en}{user.profile.last_name_en}'.lower())[:24]
        else:
            base = 'devadmin' if 'super_admin' in user.role_codes or 'admin' in user.role_codes else 'devstaff'
        if not base or not base[0].isalpha():
            base = 'customer' + user.id.hex[:12]
        candidate = base
        suffix = 1
        while not username_service.available(db, candidate):
            candidate = f'{base[:23]}{suffix}'
            suffix += 1
        user.username = username_service.normalize_username(candidate)
        user.username_key = username_service.username_key(candidate)
        db.flush()
        record_audit(db, actor=user, action='development.username_assigned', entity_type='user', entity_id=user.id,
                     details={'changed_fields': ['username'], 'existing_credentials_preserved': True})
        changed += 1
    return changed


def normalize_existing_usernames(db: Session) -> list[dict]:
    """Caller commits. Change names only, reserving existing identities first."""
    _guard()
    users = db.scalars(select(User).order_by(User.id).with_for_update()).all()
    owners = {}
    def reserve(key, owner):
        if key:
            owners.setdefault(key, set()).add(owner)
    for user in users:
        reserve(user.username_key, user.id)
        reserve(user.login_identifier_hash, user.id)
        if user.username and re.fullmatch(r'[a-z][a-z0-9]{2,29}', user.username):
            reserve(username_service.username_key(user.username), user.id)
    changes = []
    for user in users:
        if user.username is None:
            continue  # New customers still choose their own name after OTP.
        if (re.fullmatch(r'[a-z][a-z0-9]{2,29}', user.username)
                and user.username_key == username_service.username_key(user.username)):
            continue
        base = re.sub(r'[^a-z0-9]', '', user.username.lower())[:30]
        if not base or not base[0].isalpha():
            base = 'user' + base[:26]
        if len(base) < 3:
            base += 'user'
        if base in {'admin', 'administrator', 'support', 'faisalbank', 'root', 'system'}:
            base = 'user' + base[:26]
        candidate, suffix = base, 0
        while any(owners.get(key, set()) - {user.id} for key in
                  (username_service.username_key(candidate), hash_identifier(candidate))):
            suffix += 1
            digits = str(suffix)
            candidate = base[:30-len(digits)] + digits
        candidate = username_service.normalize_username(candidate)
        key = username_service.username_key(candidate)
        if user.username == candidate and user.username_key == key:
            continue
        previous = user.username
        user.username, user.username_key = candidate, key
        reserve(key, user.id)
        db.flush()
        record_audit(db, actor=user, action='development.username_normalized', entity_type='user', entity_id=user.id,
            details={'changed_fields': ['username', 'username_key'], 'previous_username': previous,
                     'username': candidate, 'existing_credentials_preserved': True})
        changes.append({'id': str(user.id), 'previous': previous, 'username': candidate})
    return changes


def _seed_investors(db: Session, passwords: dict[str, str]) -> list[dict]:
    _guard()
    investment_service.seed_products(db)
    account_product = db.scalar(select(AccountProduct).where(AccountProduct.code == 'AP-CURRENT'))
    card_product = db.scalar(select(CardProduct).where(CardProduct.code == 'CP-CLASSIC-DEBIT'))
    if not account_product or not card_product:
        raise RuntimeError('Initialize the existing banking catalogue first')
    result = []
    for suffix, first, last, first_ar, last_ar, products in INVESTORS:
        card_number = '400000000000' + suffix
        account_number = '000000000' + suffix
        customer_number = 'INV-DEMO-' + suffix
        password = passwords.get(suffix, '')
        if len(password) < 12 or not assess_password(password).valid:
            raise RuntimeError('A private policy-compliant fixture password is required')
        user = db.scalar(select(User).where(User.login_identifier_hash == hash_identifier(card_number)))
        if user is not None:
            if (not user.profile or user.profile.customer_number != customer_number
                    or not verify_password(password, user.password_hash)):
                raise RuntimeError('Existing identity or credentials differ; no overwrite is allowed')
        else:
            user = User(login_identifier_hash=hash_identifier(card_number), login_identifier_masked=f'**** **** **** {suffix}',
                        password_hash=hash_password(password), login_type='customer', enrollment_completed=True,
                        must_change_password=False, password_updated_at=utcnow(), is_active=True)
            db.add(user)
            db.flush()
            profile = CustomerProfile(user_id=user.id, first_name_en=first, last_name_en=last,
                first_name_ar=first_ar, last_name_ar=last_ar, customer_number=customer_number,
                email=f'{first.lower()}.investor@example.com', phone=f'+20100000{suffix}', identity_verified=True)
            db.add(profile)
            db.add(CustomerPreference(user_id=user.id, language='en', theme='system'))
            db.flush()
            db.refresh(user, ['profile'])
            account = Account(customer_id=user.id, product_id=account_product.id,
                account_number_hash=hash_identifier(f'acct:{account_number}'), account_number_masked=f'**** **** {suffix}',
                account_type='current', currency='EGP', status='active', current_balance=Decimal('50000'),
                available_balance=Decimal('50000'), blocked_balance=0)
            db.add(account)
            db.flush()
            db.add(Card(customer_id=user.id, account_id=account.id, product_id=card_product.id,
                card_number_hash=hash_identifier(card_number), pan_token=f'investor-demo-{user.id}', card_last4=suffix,
                cardholder_name=f'{first} {last}'.upper(), card_kind='debit', network='visa', expiry_month=12,
                expiry_year=2035, status='active', is_primary=True, is_supplementary=False))
            opening = Transaction(customer_id=user.id, account_id=account.id, reference=generate_reference('DEMO'),
                transaction_type='demo_funding', direction='credit', amount=Decimal('50000'), currency='EGP',
                description='Fictional initial investment fixture funding', description_ar='تمويل تجريبي لعميل استثمار',
                status='posted', is_simulated=True, balance_after=Decimal('50000'), occurred_at=utcnow())
            db.add(opening)
            db.flush()
            db.add_all([
                TransactionEntry(transaction_id=opening.id, account_id=None, entry_type='debit', amount=Decimal('50000'), ledger_bucket='demo_funding'),
                TransactionEntry(transaction_id=opening.id, account_id=account.id, entry_type='credit', amount=Decimal('50000'), ledger_bucket='customer_cash'),
            ])
            record_audit(db, actor=user, action='development.investor_provisioned', entity_type='user', entity_id=user.id)
        db.flush()
        assign_enrolled_usernames(db)
        db.commit()
        account = db.scalar(select(Account).where(Account.customer_id == user.id,
            Account.account_number_hash == hash_identifier(f'acct:{account_number}')))
        if account is None:
            raise RuntimeError('Fixture account is missing; refusing to replace existing banking records')
        for product_suffix in products:
            key = f'seed-investor-{suffix}-{product_suffix}'
            existing = db.scalar(select(InvestmentOperation.id).where(
                InvestmentOperation.customer_id == user.id, InvestmentOperation.idempotency_key == key))
            if existing:
                continue
            product = db.scalar(select(BankingProduct).where(BankingProduct.code == 'INV-DEMO-' + product_suffix))
            action = InvestmentAction(action='subscribe', account_id=account.id, product_id=product.id,
                amount=Decimal('10000') if product_suffix == '4Y' else Decimal('1000'))
            token = security_service.authorize_operation(db, user, 'investment_subscribe', password, investment=action)
            investment_service.execute(db, user, InvestmentExecute(**action.model_dump(), authorization_token=token), key)
        result.append({'suffix': suffix, 'username': user.username, 'card': card_number, 'account': account_number})
    return result


def provision_investor_fixtures(bind, passwords: dict[str, str]) -> list[dict]:
    """Outer transaction keeps all service-owned commits atomic as savepoints."""
    _guard()
    with bind.connect() as connection:
        transaction = connection.begin()
        try:
            with Session(bind=connection, join_transaction_mode='create_savepoint', expire_on_commit=False, autoflush=False) as db:
                result = _seed_investors(db, passwords)
            transaction.commit()
            return result
        except Exception:
            transaction.rollback()
            raise
