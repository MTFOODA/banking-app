"""Banking products and offers for the demo seed."""

from __future__ import annotations

from datetime import timedelta

from sqlalchemy import select

from app.models.content import BankingProduct, Offer
from demo_common import NOW


def seed_products_and_offers(db) -> None:
    if not db.scalar(select(BankingProduct.id).limit(1)):
        db.add_all(
            [
                BankingProduct(
                    code="PRD-CERT-3M",
                    name_en="3-Month Investment Certificate",
                    name_ar="شهادة استثمار لمدة 3 أشهر",
                    product_type="certificate",
                    summary_en="A short-term Sharia-compliant certificate.",
                    summary_ar="شهادة قصيرة الأجل متوافقة مع الشريعة.",
                    details_en=(
                        "Illustrative demo product. Actual profit rates, terms and eligibility "
                        "must be confirmed by the bank before any real application."
                    ),
                    details_ar=(
                        "منتج توضيحي. يجب تأكيد نسب الأرباح والشروط والأهلية من البنك قبل "
                        "أي طلب حقيقي."
                    ),
                    pricing_note_en="Profit rate: refer to the bank's published rates.",
                    pricing_note_ar="نسبة الربح: يُرجى الرجوع إلى النسب المعلنة من البنك.",
                    eligibility_en="Subject to bank approval and product terms.",
                    eligibility_ar="تخضع لموافقة البنك وشروط المنتج.",
                    cta_route="/products",
                ),
                BankingProduct(
                    code="PRD-INV-ACCOUNT",
                    name_en="Investment Account",
                    name_ar="حساب الاستثمار",
                    product_type="investment",
                    summary_en="Profit-sharing investment account.",
                    summary_ar="حساب استثماري بالمشاركة في الأرباح.",
                    details_en="Demo description. Real terms are published by the bank.",
                    details_ar="وصف توضيحي. الشروط الحقيقية تُنشر من البنك.",
                    pricing_note_en="Profit sharing is determined by the bank.",
                    pricing_note_ar="تحدد المشاركة في الأرباح بواسطة البنك.",
                    cta_route="/products",
                ),
                BankingProduct(
                    code="PRD-SAVINGS",
                    name_en="Savings Account",
                    name_ar="حساب التوفير",
                    product_type="savings",
                    summary_en="Save with flexible access.",
                    summary_ar="وفّر مع مرونة في السحب.",
                    details_en="Demo description. Real terms are published by the bank.",
                    details_ar="وصف توضيحي. الشروط الحقيقية تُنشر من البنك.",
                    cta_route="/products",
                ),
            ]
        )

    if not db.scalar(select(Offer.id).limit(1)):
        db.add_all(
            [
                Offer(
                    title_en="Zero-fee transfers this month",
                    title_ar="تحويلات بدون رسوم هذا الشهر",
                    description_en="Demo offer: enjoy fee-free transfers within the app.",
                    description_ar="عرض توضيحي: استمتع بتحويلات بدون رسوم داخل التطبيق.",
                    status="published",
                    start_at=NOW - timedelta(days=2),
                    end_at=NOW + timedelta(days=20),
                    is_featured=True,
                    display_order=1,
                    cta_route="/transfers",
                ),
                Offer(
                    title_en="Investment certificate bundle",
                    title_ar="حزمة شهادات الاستثمار",
                    description_en="Illustrative offer for demo purposes only.",
                    description_ar="عرض توضيحي لأغراض العرض فقط.",
                    status="published",
                    start_at=NOW - timedelta(days=5),
                    end_at=NOW + timedelta(days=40),
                    display_order=2,
                    cta_route="/products",
                ),
            ]
        )
    db.commit()
