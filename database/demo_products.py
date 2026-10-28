"""Account and card product catalogue for the demo seed."""

from __future__ import annotations

from sqlalchemy import select

from app.models.banking import AccountProduct, CardProduct
from demo_common import money


def seed_products(db) -> dict:
    account_products = {
        "AP-CURRENT": dict(
            name_en="Current Account",
            name_ar="الحساب الجاري",
            account_type="current",
            description_en="Everyday banking with instant access to your money.",
            description_ar="حساب يومي مع إمكانية الوصول الفوري إلى أموالك.",
            minimum_balance=money("0.00"),
        ),
        "AP-INVESTMENT": dict(
            name_en="Investment Account",
            name_ar="حساب الاستثمار",
            account_type="investment",
            description_en="Sharia-compliant investment account with profit sharing.",
            description_ar="حساب استثماري متوافق مع الشريعة الإسلامية بالمشاركة في الأرباح.",
            minimum_balance=money("1000.00"),
        ),
        "AP-SAVINGS": dict(
            name_en="Savings Account",
            name_ar="حساب التوفير",
            account_type="savings",
            description_en="Build your savings steadily with flexible access.",
            description_ar="نمِّ مدخراتك بثبات مع مرونة في السحب.",
            minimum_balance=money("500.00"),
        ),
    }
    resolved = {}
    for code, fields in account_products.items():
        existing = db.scalar(select(AccountProduct).where(AccountProduct.code == code))
        if existing is None:
            existing = AccountProduct(code=code, **fields)
            db.add(existing)
            db.flush()
        resolved[code] = existing

    card_products = {
        "CP-CLASSIC-DEBIT": dict(
            name_en="Faisal Classic Debit",
            name_ar="بطاقة فيصل الكلاسيكية",
            card_kind="debit",
            network="DemoPay",
            description_en="Demo debit card product placeholder.",
            description_ar="منتج بطاقة خصم تجريبي (نموذج توضيحي).",
        ),
        "CP-PLATINUM-CREDIT": dict(
            name_en="Faisal Platinum Credit",
            name_ar="بطاقة فيصل بلاتينية الائتمانية",
            card_kind="credit",
            network="DemoPay",
            description_en="Demo credit card product placeholder.",
            description_ar="منتج بطاقة ائتمانية تجريبي (نموذج توضيحي).",
        ),
    }
    for code, fields in card_products.items():
        existing = db.scalar(select(CardProduct).where(CardProduct.code == code))
        if existing is None:
            existing = CardProduct(code=code, **fields)
            db.add(existing)
            db.flush()
        resolved[code] = existing

    from app.services.card_catalogue import seed_catalogue
    seed_catalogue(db)
    db.commit()
    return resolved
