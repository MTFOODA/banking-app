"""Demo customers, accounts and cards (fake, clearly labelled data)."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from sqlalchemy import select

from app.core.security import hash_identifier, hash_password
from app.models.banking import Account, Card, CardLimit, CardProduct
from app.models.user import CustomerPreference, CustomerProfile, User
from demo_common import DEMO_CARD_1, DEMO_CARD_2, DEMO_TEMP_1, DEMO_TEMP_2


def _masked_card(identifier: str) -> str:
    return f"**** **** **** {identifier[-4:]}"


def create_user(
    db,
    *,
    card_number: str,
    temp_credential: str,
    customer_number: str,
    first_en: str,
    last_en: str,
    first_ar: str,
    last_ar: str,
    email: str,
    phone: str,
    national_id: str,
) -> User:
    user = User(
        login_identifier_hash=hash_identifier(card_number),
        login_identifier_masked=_masked_card(card_number),
        login_type="customer",
        password_hash=hash_password(temp_credential),
        must_change_password=True,
        is_active=True,
    )
    db.add(user)
    db.flush()
    db.add(
        CustomerProfile(
            user_id=user.id,
            first_name_en=first_en,
            last_name_en=last_en,
            first_name_ar=first_ar,
            last_name_ar=last_ar,
            email=email,
            phone=phone,
            national_id_masked=national_id,
            date_of_birth=date(1988, 4, 12),
            address="Cairo, Egypt (demo address)",
            customer_number=customer_number,
            segment="retail",
            identity_verified=True,
        )
    )
    db.add(CustomerPreference(user_id=user.id, language="en", theme="system"))
    db.flush()
    return user


def create_account(
    db,
    *,
    user: User,
    product,
    digits: str,
    iban: str,
    current: str,
    available: str,
    blocked: str = "0.00",
    status: str = "active",
) -> Account:
    account = Account(
        customer_id=user.id,
        product_id=product.id,
        account_number_hash=hash_identifier(f"acct:{digits}"),
        account_number_masked=f"**** **** {digits[-4:]}",
        iban=iban,
        account_type=product.account_type,
        currency="EGP",
        status=status,
        current_balance=Decimal(current),
        available_balance=Decimal(available),
        blocked_balance=Decimal(blocked),
        opened_at=datetime.now(UTC) - timedelta(days=420),
    )
    db.add(account)
    db.flush()
    return account


def create_card(
    db,
    *,
    user: User,
    product: CardProduct,
    last4: str,
    holder: str,
    kind: str,
    status: str,
    account: Account | None,
    seed: str,
    is_supplementary: bool = False,
    credit: dict | None = None,
) -> Card:
    card = Card(
        customer_id=user.id,
        account_id=account.id if account else None,
        product_id=product.id,
        card_number_hash=hash_identifier(f"seed-pan:{seed}"),
        pan_token=f"tok_seed_{seed}",
        card_last4=last4,
        cardholder_name=holder,
        card_kind=kind,
        network=product.network,
        expiry_month=9,
        expiry_year=datetime.now(UTC).year + 3,
        status=status,
        is_primary=not is_supplementary,
        is_supplementary=is_supplementary,
        credit_limit=Decimal(credit["limit"]) if credit else None,
        available_credit=Decimal(credit["available"]) if credit else None,
        outstanding_balance=Decimal(credit["outstanding"]) if credit else None,
        statement_balance=Decimal(credit["statement"]) if credit else None,
        minimum_payment=Decimal(credit["minimum"]) if credit else None,
        payment_due_date=date.today() + timedelta(days=12) if credit else None,
        issued_at=datetime.now(UTC) - timedelta(days=380),
    )
    db.add(card)
    db.flush()
    db.add(
        CardLimit(
            card_id=card.id,
            daily_purchase_limit=Decimal("25000.00"),
            daily_atm_limit=Decimal("6000.00"),
            monthly_limit=Decimal("120000.00"),
            online_enabled=True,
            international_enabled=False,
            contactless_enabled=True,
        )
    )
    return card


def seed_customers(db, products: dict) -> dict | None:
    existing = db.scalar(
        select(CustomerProfile).where(CustomerProfile.customer_number == "C-100001")
    )
    if existing is not None:
        return None

    user1 = create_user(
        db,
        card_number=DEMO_CARD_1,
        temp_credential=DEMO_TEMP_1,
        customer_number="C-100001",
        first_en="Ahmed",
        last_en="Hassan",
        first_ar="أحمد",
        last_ar="حسن",
        email="ahmed.hassan@example.com",
        phone="+20 100 000 0001",
        national_id="2***********01",
    )
    current1 = create_account(
        db,
        user=user1,
        product=products["AP-CURRENT"],
        digits="1002003004001",
        iban="EG380019000501002003004000001",
        current="45250.75",
        available="44250.75",
        blocked="1000.00",
    )
    investment1 = create_account(
        db,
        user=user1,
        product=products["AP-INVESTMENT"],
        digits="1002003004009",
        iban="EG380019000501002003004000009",
        current="128400.00",
        available="128400.00",
    )

    debit1 = create_card(
        db,
        user=user1,
        product=products["CP-CLASSIC-DEBIT"],
        last4=DEMO_CARD_1[-4:],
        holder="AHMED HASSAN",
        kind="debit",
        status="active",
        account=current1,
        seed="debit-1",
    )
    credit1 = create_card(
        db,
        user=user1,
        product=products["CP-PLATINUM-CREDIT"],
        last4="4417",
        holder="AHMED HASSAN",
        kind="credit",
        status="active",
        account=None,
        seed="credit-1",
        credit={
            "limit": "50000.00",
            "available": "37500.00",
            "outstanding": "12500.00",
            "statement": "8000.00",
            "minimum": "800.00",
        },
    )
    supplementary1 = create_card(
        db,
        user=user1,
        product=products["CP-CLASSIC-DEBIT"],
        last4="8821",
        holder="SARA HASSAN",
        kind="debit",
        status="active",
        account=current1,
        seed="supp-1",
        is_supplementary=True,
    )
    from app.models.banking import SupplementaryCardRelationship

    db.add(
        SupplementaryCardRelationship(
            primary_card_id=credit1.id,
            supplementary_card_id=supplementary1.id,
            holder_name="Sara Hassan",
            relationship_type="family",
        )
    )

    from app.models.transactions import CreditCardStatement

    db.add(
        CreditCardStatement(
            card_id=credit1.id,
            period_start=date.today() - timedelta(days=45),
            period_end=date.today() - timedelta(days=15),
            statement_balance=Decimal("8000.00"),
            minimum_payment=Decimal("800.00"),
            due_date=date.today() + timedelta(days=12),
            status="open",
        )
    )

    user2 = create_user(
        db,
        card_number=DEMO_CARD_2,
        temp_credential=DEMO_TEMP_2,
        customer_number="C-100002",
        first_en="Mariam",
        last_en="Adel",
        first_ar="مريم",
        last_ar="عادل",
        email="mariam.adel@example.com",
        phone="+20 100 000 0002",
        national_id="2***********02",
    )
    current2 = create_account(
        db,
        user=user2,
        product=products["AP-CURRENT"],
        digits="1002003004002",
        iban="EG380019000501002003004000002",
        current="18750.20",
        available="18750.20",
    )
    savings2 = create_account(
        db,
        user=user2,
        product=products["AP-SAVINGS"],
        digits="1002003004003",
        iban="EG380019000501002003004000003",
        current="32000.00",
        available="32000.00",
    )
    debit2 = create_card(
        db,
        user=user2,
        product=products["CP-CLASSIC-DEBIT"],
        last4=DEMO_CARD_2[-4:],
        holder="MARIAM ADEL",
        kind="debit",
        status="frozen",
        account=current2,
        seed="debit-2",
    )

    db.commit()
    return {
        "user1": user1,
        "current1": current1,
        "investment1": investment1,
        "debit1": debit1,
        "credit1": credit1,
        "supplementary1": supplementary1,
        "user2": user2,
        "current2": current2,
        "savings2": savings2,
        "debit2": debit2,
    }

