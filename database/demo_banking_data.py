"""Fictional demo banking dataset (LOCAL/DEVELOPMENT ONLY).

All names, card numbers, account numbers and credentials below are synthetic.
Card numbers use the public test range ``4000 0000 0000 01xx``; no real personal
or banking data is present. Nothing here is imported by the API at runtime.

Every record receives a deterministic UUID derived from ``demo_id(key)`` so the
seeder can be rerun safely without creating duplicates.
"""

from __future__ import annotations

import uuid

_NAMESPACE = uuid.uuid5(uuid.NAMESPACE_URL, "faisal-demo-banking-v1")

#: Demo passwords are documented in `backend/DEMO_CREDENTIALS.md`.
CUSTOMERS: list[dict] = [
    dict(
        key="youssef",
        first_en="Youssef",
        last_en="Kamal",
        first_ar="يوسف",
        last_ar="كمال",
        customer_number="DEMO-C-1001",
        email="youssef.kamal@demo.faisalbank.local",
        phone="+20 100 000 0101",
        national_id="2***********101",
        date_of_birth="1990-02-14",
        address="12 Fictional Nile Street, Cairo (demo)",
        segment="retail",
        pan="4000000000000101",
        password="Youssef#2026",
        must_change_password=False,
        scenario="One current account and one active debit card with incoming and outgoing activity.",
    ),
    dict(
        key="salma",
        first_en="Salma",
        last_en="Nabil",
        first_ar="سلمى",
        last_ar="نبيل",
        customer_number="DEMO-C-1002",
        email="salma.nabil@demo.faisalbank.local",
        phone="+20 100 000 0102",
        national_id="2***********102",
        date_of_birth="1993-07-03",
        address="8 Fictional Garden Street, Giza (demo)",
        segment="retail",
        pan="4000000000000102",
        password="Salma#2026",
        must_change_password=False,
        scenario="Multiple accounts (current + savings) and two cards (debit + credit).",
    ),
    dict(
        key="omar",
        first_en="Omar",
        last_en="Sherif",
        first_ar="عمر",
        last_ar="شريف",
        customer_number="DEMO-C-1003",
        email="omar.sherif@demo.faisalbank.local",
        phone="+20 100 000 0103",
        national_id="2***********103",
        date_of_birth="1986-11-21",
        address="44 Fictional Corniche Road, Alexandria (demo)",
        segment="premium",
        pan="4000000000000104",
        password="Omar#2026",
        must_change_password=False,
        scenario="Long transaction history across current, savings and investment accounts.",
    ),
    dict(
        key="hana",
        first_en="Hana",
        last_en="Mostafa",
        first_ar="هنا",
        last_ar="مصطفى",
        customer_number="DEMO-C-1004",
        email="hana.mostafa@demo.faisalbank.local",
        phone="+20 100 000 0104",
        national_id="2***********104",
        date_of_birth="1997-01-09",
        address="3 Fictional Market Lane, Cairo (demo)",
        segment="retail",
        pan="4000000000000106",
        password="Hana#2026",
        must_change_password=False,
        scenario="Low balance account with a few recent transactions.",
    ),
    dict(
        key="karim",
        first_en="Karim",
        last_en="Fouad",
        first_ar="كريم",
        last_ar="فؤاد",
        customer_number="DEMO-C-1005",
        email="karim.fouad@demo.faisalbank.local",
        phone="+20 100 000 0105",
        national_id="2***********105",
        date_of_birth="1988-05-30",
        address="21 Fictional Delta Street, Mansoura (demo)",
        segment="retail",
        pan="4000000000000107",
        password="Karim#2026",
        must_change_password=False,
        scenario="Completed, pending and failed operations plus a credit card.",
    ),
    dict(
        key="nada",
        first_en="Nada",
        last_en="Hassan",
        first_ar="ندى",
        last_ar="حسن",
        customer_number="DEMO-C-1006",
        email="nada.hassan@demo.faisalbank.local",
        phone="+20 100 000 0106",
        national_id="2***********106",
        date_of_birth="1995-09-12",
        address="5 Fictional Temple Avenue, Luxor (demo)",
        segment="retail",
        pan="4000000000000109",
        password="Temp#Nada2026",
        must_change_password=True,
        scenario="Mandatory first-login password setup fixture.",
    ),
]

#: (key, customer_key, product_code, account_number, opening_balance, blocked, status)
ACCOUNTS: list[dict] = [
    dict(key="youssef-current", customer="youssef", product="AP-CURRENT", number="5550000000101",
         opening="12000.00", blocked="0.00", status="active", opened_days=430),
    dict(key="salma-current", customer="salma", product="AP-CURRENT", number="5550000000102",
         opening="9000.00", blocked="0.00", status="active", opened_days=390),
    dict(key="salma-savings", customer="salma", product="AP-SAVINGS", number="5550000000103",
         opening="40000.00", blocked="0.00", status="active", opened_days=330),
    dict(key="omar-current", customer="omar", product="AP-CURRENT", number="5550000000104",
         opening="25000.00", blocked="0.00", status="active", opened_days=520),
    dict(key="omar-savings", customer="omar", product="AP-SAVINGS", number="5550000000105",
         opening="60000.00", blocked="0.00", status="active", opened_days=460),
    dict(key="omar-investment", customer="omar", product="AP-INVESTMENT", number="5550000000106",
         opening="100000.00", blocked="10000.00", status="active", opened_days=300),
    dict(key="hana-current", customer="hana", product="AP-CURRENT", number="5550000000107",
         opening="150.00", blocked="0.00", status="active", opened_days=150),
    dict(key="karim-current", customer="karim", product="AP-CURRENT", number="5550000000108",
         opening="6000.00", blocked="0.00", status="active", opened_days=280),
    dict(key="karim-savings", customer="karim", product="AP-SAVINGS", number="5550000000109",
         opening="15000.00", blocked="0.00", status="active", opened_days=260),
    dict(key="nada-current", customer="nada", product="AP-CURRENT", number="5550000000110",
         opening="4000.00", blocked="0.00", status="active", opened_days=90),
]

#: Credit cards store an opening outstanding balance, a limit and statement data.
CARDS: list[dict] = [
    dict(key="youssef-debit", customer="youssef", pan="4000000000000101",
         product="CP-CLASSIC-DEBIT", kind="debit", account="youssef-current",
         status="active", holder="YOUSSEF KAMAL"),
    dict(key="salma-debit", customer="salma", pan="4000000000000102",
         product="CP-CLASSIC-DEBIT", kind="debit", account="salma-current",
         status="active", holder="SALMA NABIL"),
    dict(key="salma-credit", customer="salma", pan="4000000000000103",
         product="CP-PLATINUM-CREDIT", kind="credit", account=None,
         status="active", holder="SALMA NABIL", credit_opening="6000.00",
         credit_limit="60000.00", statement="5000.00", minimum="500.00", due_days=14),
    dict(key="omar-debit", customer="omar", pan="4000000000000104",
         product="CP-CLASSIC-DEBIT", kind="debit", account="omar-current",
         status="active", holder="OMAR SHERIF"),
    dict(key="omar-savings-debit", customer="omar", pan="4000000000000105",
         product="CP-CLASSIC-DEBIT", kind="debit", account="omar-savings",
         status="frozen", holder="OMAR SHERIF"),
    dict(key="hana-debit", customer="hana", pan="4000000000000106",
         product="CP-CLASSIC-DEBIT", kind="debit", account="hana-current",
         status="active", holder="HANA MOSTAFA"),
    dict(key="karim-debit", customer="karim", pan="4000000000000107",
         product="CP-CLASSIC-DEBIT", kind="debit", account="karim-current",
         status="active", holder="KARIM FOUAD"),
    dict(key="karim-credit", customer="karim", pan="4000000000000108",
         product="CP-PLATINUM-CREDIT", kind="credit", account=None,
         status="active", holder="KARIM FOUAD", credit_opening="9300.00",
         credit_limit="30000.00", statement="9000.00", minimum="900.00", due_days=9),
    dict(key="nada-debit", customer="nada", pan="4000000000000109",
         product="CP-CLASSIC-DEBIT", kind="debit", account="nada-current",
         status="active", holder="NADA HASSAN"),
]

#: (from_customer, from_account, to_customer, to_account, amount, days_ago, purpose_en, purpose_ar)
TRANSFERS: list[tuple] = [
    ("youssef", "5550000000101", "omar", "5550000000104", "2500.00", 12,
     "Family support", "دعم عائلي"),
    ("salma", "5550000000102", "youssef", "5550000000101", "1500.00", 8,
     "Shared household expenses", "مصاريف منزلية مشتركة"),
    ("omar", "5550000000104", "salma", "5550000000103", "5000.00", 18,
     "Monthly savings", "مدخرات شهرية"),
    ("karim", "5550000000108", "hana", "5550000000107", "400.00", 5,
     "Birthday gift", "هدية عيد ميلاد"),
    ("hana", "5550000000107", "omar", "5550000000104", "200.00", 21,
     "Book club subscription", "اشتراك نادي الكتاب"),
    ("omar", "5550000000104", "omar", "5550000000106", "5000.00", 6,
     "Investment contribution", "مساهمة استثمارية"),
]

#: (customer, account, biller_en, biller_ar, amount, days_ago, status)
PAYMENTS: list[tuple] = [
    ("youssef", "5550000000101", "Cairo Electricity", "كهرباء القاهرة", "640.00", 10, "posted"),
    ("youssef", "5550000000101", "Cairo Water", "مياه القاهرة", "185.50", 3, "posted"),
    ("salma", "5550000000102", "Home internet", "الإنترنت المنزلي", "450.00", 9, "posted"),
    ("salma", "5550000000102", "Cairo Electricity", "كهرباء القاهرة", "610.00", 20, "posted"),
    ("omar", "5550000000104", "Mobile top-up", "شحن رصيد الهاتف", "100.00", 2, "failed"),
    ("omar", "5550000000104", "Cairo Water", "مياه القاهرة", "210.00", 14, "posted"),
    ("hana", "5550000000107", "Cairo Water", "مياه القاهرة", "185.50", 4, "posted"),
    ("karim", "5550000000108", "Home internet", "الإنترنت المنزلي", "450.00", 6, "posted"),
    ("karim", "5550000000108", "Cairo Electricity", "كهرباء القاهرة", "640.00", 25, "posted"),
    ("karim", "5550000000108", "Mobile top-up", "شحن رصيد الهاتف", "150.00", 1, "pending"),
]

#: (customer, account|None, card|None, type, direction, amount, description_en,
#:  description_ar, counterparty, merchant, days_ago, status)
ACTIVITY: list[tuple] = [
    ("youssef", "5550000000101", None, "salary", "credit", "12000.00", "Monthly salary",
     "الراتب الشهري", "Nile Digital Solutions (demo)", None, 26, "posted"),
    ("youssef", "5550000000101", None, "purchase", "debit", "850.00", "Grocery purchase",
     "مشتريات بقالة", None, "Demo Market", 15, "posted"),
    ("youssef", "5550000000101", None, "withdrawal", "debit", "1500.00", "ATM withdrawal",
     "سحب من الصراف الآلي", "Faisal ATM - Demo Branch", None, 11, "posted"),
    ("youssef", "5550000000101", None, "deposit", "credit", "3000.00", "Cash deposit",
     "إيداع نقدي", "Demo Branch", None, 22, "posted"),
    ("youssef", "5550000000101", None, "fee", "debit", "25.00", "Account maintenance fee",
     "رسوم إدارة الحساب", "Faisal Bank (demo)", None, 30, "posted"),
    ("youssef", "5550000000101", None, "purchase", "debit", "420.00", "Pharmacy purchase",
     "مشتريات صيدلية", None, "Demo Pharmacy", 6, "posted"),
    ("youssef", None, "4000000000000101", "purchase", "debit", "260.00", "Coffee shop",
     "مقهى", None, "Demo Cafe", 4, "posted"),

    ("salma", "5550000000102", None, "salary", "credit", "15000.00", "Monthly salary",
     "الراتب الشهري", "Delta Creative Studio (demo)", None, 24, "posted"),
    ("salma", "5550000000103", None, "deposit", "credit", "4000.00", "Savings deposit",
     "إيداع مدخرات", "Demo Branch", None, 19, "posted"),
    ("salma", "5550000000103", None, "withdrawal", "debit", "2000.00", "Savings withdrawal",
     "سحب من المدخرات", "Faisal ATM - Demo Branch", None, 13, "posted"),
    ("salma", "5550000000102", None, "purchase", "debit", "600.00", "Fashion purchase",
     "مشتريات أزياء", None, "Demo Boutique", 7, "posted"),
    ("salma", "5550000000102", None, "withdrawal", "debit", "1000.00", "ATM withdrawal",
     "سحب من الصراف الآلي", "Faisal ATM - Demo Branch", None, 16, "posted"),
    ("salma", "5550000000102", None, "purchase", "debit", "380.00", "Home supplies",
     "مستلزمات منزلية", None, "Demo Home Store", 2, "posted"),
    ("salma", None, "4000000000000103", "purchase", "debit", "1200.00", "Electronics purchase",
     "شراء إلكترونيات", None, "Demo Electronics", 9, "posted"),
    ("salma", None, "4000000000000103", "purchase", "debit", "800.00", "Travel booking",
     "حجز سفر", None, "Demo Travel", 12, "posted"),
    ("salma", None, "4000000000000103", "card_repayment", "credit", "500.00",
     "Credit card repayment", "سداد البطاقة الائتمانية", "**** **** 0102", None, 5, "posted"),
    ("salma", "5550000000102", None, "card_repayment", "debit", "500.00",
     "Credit card repayment", "سداد البطاقة الائتمانية", "**** **** 0103", None, 5, "posted"),

    ("omar", "5550000000104", None, "salary", "credit", "22000.00", "Monthly salary",
     "الراتب الشهري", "Fictional Engineering LLC (demo)", None, 27, "posted"),
    ("omar", "5550000000104", None, "purchase", "debit", "1200.00", "Grocery purchase",
     "مشتريات بقالة", None, "Demo Hypermarket", 17, "posted"),
    ("omar", "5550000000104", None, "purchase", "debit", "3400.00", "Laptop purchase",
     "شراء حاسوب محمول", None, "Demo Electronics", 9, "posted"),
    ("omar", "5550000000104", None, "withdrawal", "debit", "3000.00", "ATM withdrawal",
     "سحب من الصراف الآلي", "Faisal ATM - Demo Branch", None, 12, "posted"),
    ("omar", "5550000000104", None, "deposit", "credit", "10000.00", "Cheque deposit",
     "إيداع شيك", "Demo Branch", None, 23, "posted"),
    ("omar", "5550000000104", None, "fee", "debit", "50.00", "Portfolio service fee",
     "رسوم خدمة المحفظة", "Faisal Bank (demo)", None, 28, "posted"),
    ("omar", "5550000000104", None, "purchase", "debit", "780.00", "Restaurant bill",
     "فاتورة مطعم", None, "Demo Grill House", 5, "posted"),
    ("omar", "5550000000104", None, "withdrawal", "debit", "500.00", "ATM withdrawal",
     "سحب من الصراف الآلي", "Faisal ATM - Demo Branch", None, 3, "posted"),
    ("omar", "5550000000105", None, "deposit", "credit", "5000.00", "Savings deposit",
     "إيداع مدخرات", "Demo Branch", None, 20, "posted"),
    ("omar", None, "4000000000000104", "purchase", "debit", "900.00", "Supermarket payment",
     "دفع في سوبر ماركت", None, "Demo Supermarket", 8, "posted"),

    ("hana", "5550000000107", None, "deposit", "credit", "300.00", "Cash deposit",
     "إيداع نقدي", "Demo Branch", None, 18, "posted"),
    ("hana", "5550000000107", None, "purchase", "debit", "120.00", "Grocery purchase",
     "مشتريات بقالة", None, "Demo Mini Market", 8, "posted"),
    ("hana", "5550000000107", None, "purchase", "debit", "75.00", "Pharmacy purchase",
     "مشتريات صيدلية", None, "Demo Pharmacy", 3, "posted"),
    ("hana", "5550000000107", None, "withdrawal", "debit", "100.00", "ATM withdrawal",
     "سحب من الصراف الآلي", "Faisal ATM - Demo Branch", None, 6, "posted"),
    ("hana", "5550000000107", None, "fee", "debit", "15.00", "SMS alerts fee",
     "رسوم رسائل التنبيه", "Faisal Bank (demo)", None, 30, "posted"),
    ("hana", None, "4000000000000106", "purchase", "debit", "60.00", "Bookshop purchase",
     "شراء كتب", None, "Demo Bookshop", 2, "pending"),

    ("karim", "5550000000108", None, "salary", "credit", "9000.00", "Monthly salary",
     "الراتب الشهري", "Fictional Logistics Co. (demo)", None, 25, "posted"),
    ("karim", "5550000000108", None, "purchase", "debit", "700.00", "Grocery purchase",
     "مشتريات بقالة", None, "Demo Market", 10, "posted"),
    ("karim", "5550000000108", None, "withdrawal", "debit", "800.00", "ATM withdrawal",
     "سحب من الصراف الآلي", "Faisal ATM - Demo Branch", None, 14, "posted"),
    ("karim", "5550000000108", None, "fee", "debit", "20.00", "Account maintenance fee",
     "رسوم إدارة الحساب", "Faisal Bank (demo)", None, 29, "posted"),
    ("karim", "5550000000108", None, "purchase", "debit", "250.00", "Online subscription",
     "اشتراك إلكتروني", None, "Demo Streaming", 1, "pending"),
    ("karim", "5550000000109", None, "deposit", "credit", "2000.00", "Savings deposit",
     "إيداع مدخرات", "Demo Branch", None, 21, "posted"),
    ("karim", None, "4000000000000108", "purchase", "debit", "2400.00", "Furniture purchase",
     "شراء أثاث", None, "Demo Furniture", 11, "posted"),
    ("karim", None, "4000000000000108", "purchase", "debit", "1600.00", "Appliance purchase",
     "شراء أجهزة", None, "Demo Appliances", 7, "posted"),
    ("karim", None, "4000000000000108", "card_repayment", "credit", "900.00",
     "Credit card repayment", "سداد البطاقة الائتمانية", "**** **** 0108", None, 4, "posted"),
    ("karim", "5550000000108", None, "card_repayment", "debit", "900.00",
     "Credit card repayment", "سداد البطاقة الائتمانية", "**** **** 0108", None, 4, "posted"),

    ("nada", "5550000000110", None, "salary", "credit", "7000.00", "Monthly salary",
     "الراتب الشهري", "Fictional Design House (demo)", None, 24, "posted"),
    ("nada", "5550000000110", None, "purchase", "debit", "300.00", "Grocery purchase",
     "مشتريات بقالة", None, "Demo Market", 6, "posted"),
    ("nada", "5550000000110", None, "deposit", "credit", "1000.00", "Cash deposit",
     "إيداع نقدي", "Demo Branch", None, 15, "posted"),
]

#: (customer, name, nickname, bank, masked_account, iban)
BENEFICIARIES: list[tuple] = [
    ("youssef", "Mona Fictional", "Mona", "Faisal Islamic Bank (demo)", "**** 7788",
     "EG3800190005000000000007788"),
    ("salma", "Nour Demo Trading", "Nour", "Demo Commercial Bank", "**** 3321", None),
    ("omar", "Hassan Fictional", "Hassan", "Faisal Islamic Bank (demo)", "**** 4455",
     "EG3800190005000000000004455"),
    ("hana", "Layla Fictional", "Layla", "Demo Commercial Bank", "**** 6612", None),
    ("karim", "Demo Charity Foundation", "Charity", "Demo Commercial Bank", "**** 9900", None),
]

#: (customer, category, title_en, title_ar, body_en, body_ar, priority, route, related_type)
NOTIFICATIONS: list[tuple] = [
    ("youssef", "transaction", "Salary received",
     "تم استلام الراتب", "Your monthly salary was credited to account **** 0101.",
     "تم إيداع راتبك الشهري في الحساب **** 0101.", "normal", "/transactions", "transaction"),
    ("youssef", "security", "New device sign-in",
     "تسجيل دخول من جهاز جديد", "A new device signed in to your account.",
     "تم تسجيل الدخول إلى حسابك من جهاز جديد.", "high", "/settings", None),
    ("salma", "transaction", "Credit card payment due",
     "موعد سداد البطاقة الائتمانية", "Your minimum payment is EGP 500.00.",
     "الحد الأدنى للسداد هو 500.00 جنيه.", "normal", "/repayments", "card"),
    ("salma", "offer", "Savings booster",
     "عرض لتعزيز المدخرات", "Move idle funds to your savings account this month.",
     "حوّل أموالك غير المستخدمة إلى حساب التوفير هذا الشهر.", "low", "/products", None),
    ("omar", "transaction", "Transfer completed",
     "تم تنفيذ التحويل", "Your transfer to savings was completed.",
     "تم تنفيذ التحويل إلى حساب التوفير.", "normal", "/transactions", "transaction"),
    ("omar", "maintenance", "Scheduled maintenance",
     "صيانة مجدولة", "The demo service is unavailable on Friday 02:00-04:00.",
     "الخدمة التجريبية غير متاحة الجمعة 02:00-04:00.", "low", "/support", None),
    ("hana", "transaction", "Low balance warning",
     "تنبيه انخفاض الرصيد", "Your available balance is below EGP 500.00.",
     "رصيدك المتاح أقل من 500.00 جنيه.", "high", "/accounts", "account"),
    ("karim", "transaction", "Payment pending",
     "عملية دفع قيد المعالجة", "Your mobile top-up payment is pending.",
     "عملية شحن الرصيد قيد المعالجة.", "normal", "/transactions", "transaction"),
    ("karim", "transaction", "Card repayment received",
     "تم استلام سداد البطاقة", "EGP 900.00 was applied to your credit card.",
     "تم تطبيق 900.00 جنيه على بطاقتك الائتمانية.", "normal", "/repayments", "card"),
    ("nada", "security", "First sign-in required",
     "مطلوب تسجيل الدخول الأول", "Set a new password to activate your account.",
     "عيّن كلمة مرور جديدة لتفعيل حسابك.", "high", "/first-login/password-setup", None),
]

#: (customer, card_pan, funding_account, amount, mode, status, days_ago)
REPAYMENTS: list[tuple] = [
    ("salma", "4000000000000103", "5550000000102", "500.00", "custom", "simulated_completed", 5),
    ("salma", "4000000000000103", "5550000000102", "750.00", "custom", "pending", 1),
    ("salma", "4000000000000103", "5550000000102", "300.00", "custom", "failed", 2),
    ("karim", "4000000000000108", "5550000000108", "900.00", "minimum", "simulated_completed", 4),
    ("karim", "4000000000000108", "5550000000108", "400.00", "custom", "pending", 1),
]


def demo_id(key: str) -> uuid.UUID:
    """Stable UUID for a demo record, so reruns update instead of duplicating."""
    return uuid.uuid5(_NAMESPACE, key)


def pan_last4(pan: str) -> str:
    return pan[-4:]


def masked_pan(pan: str) -> str:
    return f"**** **** **** {pan[-4:]}"


def masked_account(number: str) -> str:
    return f"**** **** {number[-4:]}"


def iban_for(number: str) -> str:
    return f"EG3800190005{number}"


