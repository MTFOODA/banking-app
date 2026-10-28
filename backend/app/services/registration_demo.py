"""Optional fictional bank provisioning fixture; never resets existing identities."""
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import generate_opaque_token, hash_identifier, hash_password
from app.models.banking import Account, AccountProduct, Card, CardProduct
from app.models.user import CustomerPreference, CustomerProfile, User

CARD = "4000000000000901"
ACCOUNTS = ("0000000000901", "0000000000902")


def seed_registration_demo(db: Session, *, suffix: str = '0901', customer_number: str | None = None,
                           balanced_funding: bool = False, commit: bool = True) -> bool:
    if settings.environment not in {"development", "test"}:
        raise RuntimeError("Registration fixtures are restricted to development/test")
    if len(suffix) != 4 or not suffix.isascii() or not suffix.isdigit():
        raise ValueError('A four-digit fictional suffix is required')
    card_number = '400000000000' + suffix
    account_numbers = ACCOUNTS if suffix == '0901' else ('000000000' + suffix, '100000000' + suffix)
    if db.scalar(select(User.id).where(User.login_identifier_hash == hash_identifier(card_number))):
        return False
    product = db.scalar(select(AccountProduct).where(AccountProduct.code == "AP-CURRENT"))
    card_product = db.scalar(select(CardProduct).where(CardProduct.code == "CP-CLASSIC-DEBIT"))
    if not product or not card_product:
        raise RuntimeError("Initialize the existing demo product catalog first")
    try:
        user = User(login_identifier_hash=hash_identifier(card_number), login_identifier_masked="**** **** **** " + suffix,
            login_type="customer", password_hash=hash_password(generate_opaque_token()), enrollment_completed=False,
            must_change_password=True, is_active=True)
        db.add(user)
        db.flush()
        db.add(CustomerProfile(user_id=user.id, first_name_en="Registration", last_name_en="Example",
            first_name_ar="عميل", last_name_ar="تسجيل تجريبي", customer_number=customer_number or 'REG-DEMO-' + suffix,
            email="registration.customer@example.com" if suffix == '0901' else f"registration.{suffix}@example.invalid",
            phone="+201000000901" if suffix == '0901' else "+20100000" + suffix, identity_verified=True))
        db.add(CustomerPreference(user_id=user.id, language="en", theme="system"))
        accounts = []
        for number in account_numbers:
            account = Account(customer_id=user.id, product_id=product.id, account_number_hash=hash_identifier(f"acct:{number}"),
                account_number_masked=f"**** **** {number[-4:]}", account_type="current", currency="EGP", status="active",
                current_balance=Decimal("500.00"), available_balance=Decimal("500.00"), blocked_balance=0)
            db.add(account)
            accounts.append(account)
        db.flush()
        db.add(Card(customer_id=user.id, account_id=accounts[0].id, product_id=card_product.id, card_number_hash=hash_identifier(card_number),
            pan_token=f"registration-demo-{user.id}", card_last4=suffix, cardholder_name="REGISTRATION EXAMPLE",
            card_kind="debit", network="visa", expiry_month=12, expiry_year=2035, status="active", is_primary=True, is_supplementary=False))
        if balanced_funding:
            from app.models.transactions import Transaction, TransactionEntry
            from app.services.common import generate_reference
            for account in accounts:
                movement = Transaction(customer_id=user.id, account_id=account.id, reference=generate_reference('DEMO'),
                    transaction_type='demo_funding', direction='credit', amount=Decimal('500'), currency='EGP',
                    description='Fictional self-registration opening funding', status='posted', is_simulated=True,
                    balance_after=Decimal('500'))
                db.add(movement)
                db.flush()
                db.add_all([TransactionEntry(transaction_id=movement.id, account_id=account.id, entry_type='credit',
                    amount=Decimal('500'), ledger_bucket='customer_cash'),
                    TransactionEntry(transaction_id=movement.id, entry_type='debit', amount=Decimal('500'), ledger_bucket='demo_funding')])
        if commit:
            db.commit()
        else:
            db.flush()
        return True
    except Exception:
        db.rollback()
        raise


def provision_registration_batch(db: Session, batch: str, count: int = 4) -> list[dict]:
    """Caller commits once; existing/enrolled identities are never reset."""
    import re
    from sqlalchemy import text
    if settings.environment not in {'development', 'test'}:
        raise RuntimeError('Registration fixtures are development/test only')
    if not re.fullmatch(r'[a-zA-Z0-9]{1,24}', batch) or not 1 <= count <= 10:
        raise ValueError('Use an alphanumeric batch and 1..10 customers')
    db.execute(text('SELECT pg_advisory_xact_lock(192201, 11121)'))
    results = []
    for index in range(1, count + 1):
        customer_number = f'SELF-REG-{batch}-{index}'
        profile = db.scalar(select(CustomerProfile).where(CustomerProfile.customer_number == customer_number))
        if profile:
            user = db.get(User, profile.user_id)
            card = db.scalar(select(Card).where(Card.customer_id == user.id, Card.pan_token == f'registration-demo-{user.id}'))
            if card is None or card.card_number_hash != hash_identifier('400000000000' + card.card_last4):
                raise RuntimeError('Existing fixture differs; refusing to overwrite it')
            suffix = card.card_last4
        else:
            for number in range(920, 10000):
                suffix = f'{number:04}'
                if db.scalar(select(User.id).where(User.login_identifier_hash == hash_identifier('400000000000' + suffix))):
                    continue
                if db.scalar(select(Card.id).where(Card.card_number_hash == hash_identifier('400000000000' + suffix))):
                    continue
                hashes = [hash_identifier('acct:' + prefix + suffix) for prefix in ('000000000', '100000000')]
                if not db.scalar(select(Account.id).where(Account.account_number_hash.in_(hashes))):
                    break
            else:
                raise RuntimeError('Fictional registration identifier range exhausted')
            seed_registration_demo(db, suffix=suffix, customer_number=customer_number, balanced_funding=True, commit=False)
            user = db.scalar(select(User).where(User.login_identifier_hash == hash_identifier('400000000000' + suffix)))
        results.append({'id': str(user.id), 'card': '400000000000' + suffix,
                        'enrollment_completed': user.enrollment_completed})
    return results
