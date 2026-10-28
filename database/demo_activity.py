"""Demo transactions and beneficiaries (table-driven)."""

from __future__ import annotations

from datetime import timedelta
from decimal import Decimal

from sqlalchemy import select

from app.models.banking import Beneficiary
from demo_common import NOW, add_transaction

# (account_key|None, card_key|None, type, direction, amount, description, Arabic,
#  counterparty, merchant, days_ago, balance_after)
ROWS = [
    ("current1", None, "salary", "credit", "18500.00", "Salary transfer", "تحويل الراتب",
     "Nile Digital Solutions", None, 25, "45250.75"),
    ("current1", None, "transfer", "debit", "5000.00", "Transfer to investment account",
     "تحويل إلى حساب الاستثمار", "**** **** 4009", None, 12, "42000.00"),
    ("investment1", None, "transfer", "credit", "5000.00", "Transfer from current account",
     "تحويل من الحساب الجاري", "**** **** 4001", None, 12, "128400.00"),
    ("current1", None, "bill_payment", "debit", "640.00", "Electricity bill", "فاتورة الكهرباء",
     "Egyptian Electricity", None, 18, "43610.75"),
    ("current1", None, "purchase", "debit", "1250.50", "Grocery purchase", "مشتريات بقالة",
     None, "Seoudi Market", 3, "45250.75"),
    ("current1", None, "withdrawal", "debit", "2000.00", "ATM withdrawal", "سحب من الصراف الآلي",
     "Faisal ATM - Nasr City", None, 6, "43250.75"),
    ("current1", None, "transfer", "credit", "2500.00", "Incoming transfer", "تحويل وارد",
     "Omar Ali", None, 15, "44250.75"),
    ("current1", None, "purchase", "debit", "349.99", "Online purchase", "شراء عبر الإنترنت",
     None, "Demo Store", 2, "44000.00"),
    (None, "debit1", "purchase", "debit", "180.00", "Restaurant payment", "دفع في مطعم",
     None, "Cairo Bistro", 1, None),
    (None, "credit1", "purchase", "debit", "3200.00", "Electronics purchase", "شراء إلكترونيات",
     None, "Tech Avenue", 9, None),
    (None, "credit1", "purchase", "debit", "1250.75", "Travel booking", "حجز سفر",
     None, "Fly Demo", 5, None),
    (None, "credit1", "card_repayment", "credit", "2000.00", "Credit card repayment",
     "سداد البطاقة الائتمانية", "**** **** 4001", None, 4, None),
    (None, "supplementary1", "purchase", "debit", "420.00", "Supplementary card purchase",
     "مشتريات البطاقة الإضافية", None, "Family Pharmacy", 7, None),
]


def seed_activity(db, data: dict) -> None:
    user = data["user1"]
    if db.scalar(select(Beneficiary.id).where(Beneficiary.customer_id == user.id).limit(1)):
        return

    for account_key, card_key, tx_type, direction, amount, desc, desc_ar, party, merchant, days, balance in ROWS:
        add_transaction(
            db,
            customer_id=user.id,
            account=data.get(account_key) if account_key else None,
            card=data.get(card_key) if card_key else None,
            tx_type=tx_type,
            direction=direction,
            amount=amount,
            description=desc,
            description_ar=desc_ar,
            counterparty=party,
            merchant=merchant,
            occurred_at=NOW - timedelta(days=days),
            balance_after=Decimal(balance) if balance else None,
        )

    db.add_all(
        [
            Beneficiary(
                customer_id=user.id,
                name="Omar Ali",
                nickname="Omar",
                bank_name="Faisal Islamic Bank (demo)",
                account_number_masked="**** 7788",
                iban="EG3800190005000000000000778",
                currency="EGP",
            ),
            Beneficiary(
                customer_id=user.id,
                name="Nour Trading Co.",
                nickname="Nour",
                bank_name="Demo Commercial Bank",
                account_number_masked="**** 3321",
                currency="EGP",
            ),
        ]
    )
    db.commit()
