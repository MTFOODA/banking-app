"""Bilingual announcements for the demo seed."""

from __future__ import annotations

from datetime import timedelta

from sqlalchemy import select

from app.models.content import Announcement, AnnouncementAudience
from demo_common import NOW


def seed_announcements(db) -> None:
    if db.scalar(select(Announcement.id).limit(1)):
        return
    items = [
        Announcement(
            title_en="Scheduled maintenance this weekend",
            title_ar="صيانة مجدولة نهاية هذا الأسبوع",
            body_en=(
                "Digital services will be unavailable on Friday from 02:00 to 04:00 for "
                "scheduled maintenance. Card payments will continue normally."
            ),
            body_ar=(
                "ستتوقف الخدمات الرقمية يوم الجمعة من الساعة 2:00 حتى 4:00 صباحاً لأعمال "
                "الصيانة المجدولة، وستستمر مدفوعات البطاقات بشكل طبيعي."
            ),
            summary_en="Planned maintenance window: Friday 02:00-04:00.",
            summary_ar="نافذة صيانة مجدولة: الجمعة من 2:00 إلى 4:00.",
            category="maintenance",
            priority="high",
            status="published",
            publish_at=NOW - timedelta(days=1),
            expires_at=NOW + timedelta(days=6),
            cta_label_en="View details",
            cta_label_ar="عرض التفاصيل",
            cta_route="/notifications",
        ),
        Announcement(
            title_en="Investment certificates now available",
            title_ar="شهادات الاستثمار متاحة الآن",
            body_en=(
                "Explore Sharia-compliant investment certificates through the Faisal App. "
                "Product terms shown in this demo are illustrative only."
            ),
            body_ar=(
                "اكتشف شهادات الاستثمار المتوافقة مع الشريعة الإسلامية عبر تطبيق فيصل. "
                "الشروط المعروضة في هذا النموذج توضيحية فقط."
            ),
            summary_en="Grow your savings with Sharia-compliant certificates.",
            summary_ar="نمِّ مدخراتك من خلال شهادات متوافقة مع الشريعة.",
            category="investment",
            priority="normal",
            status="published",
            publish_at=NOW - timedelta(days=3),
            expires_at=NOW + timedelta(days=30),
            cta_label_en="Explore products",
            cta_label_ar="استكشف المنتجات",
            cta_route="/products",
        ),
        Announcement(
            title_en="Protect yourself from fraud",
            title_ar="احمِ نفسك من الاحتيال",
            body_en=(
                "Faisal Bank will never ask for your password, PIN or card security code by "
                "phone, email or message."
            ),
            body_ar=(
                "لن يطلب بنك فيصل أبداً كلمة المرور أو الرقم السري أو رمز أمان البطاقة عبر "
                "الهاتف أو البريد الإلكتروني أو الرسائل."
            ),
            summary_en="We never ask for your password or PIN.",
            summary_ar="لا نطلب كلمة المرور أو الرقم السري مطلقاً.",
            category="security",
            priority="high",
            status="published",
            publish_at=NOW - timedelta(days=7),
            cta_label_en="Security tips",
            cta_label_ar="نصائح الأمان",
            cta_route="/support",
        ),
        Announcement(
            title_en="New branch opening soon",
            title_ar="افتتاح فرع جديد قريباً",
            body_en="A new branch will open next month. Details will be announced here.",
            body_ar="سيتم افتتاح فرع جديد الشهر القادم، وسيتم الإعلان عن التفاصيل هنا.",
            summary_en="Scheduled for next month.",
            summary_ar="مقرر الشهر القادم.",
            category="announcement",
            priority="low",
            status="scheduled",
            publish_at=NOW + timedelta(days=10),
        ),
    ]
    for item in items:
        item.audiences = [AnnouncementAudience(audience_type="all")]
    db.add_all(items)
    db.commit()
