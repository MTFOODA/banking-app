"""Demo notifications and support conversation."""

from __future__ import annotations

from datetime import timedelta

from sqlalchemy import select

from app.models.service import Notification, ServiceRequest, SupportMessage, SupportTicket
from demo_common import NOW, ref


def seed_notifications(db, data: dict) -> None:
    user = data["user1"]
    if db.scalar(select(Notification.id).where(Notification.customer_id == user.id).limit(1)):
        return
    info_request = db.scalar(
        select(ServiceRequest)
        .where(ServiceRequest.customer_id == user.id)
        .order_by(ServiceRequest.created_at.desc())
    )

    db.add_all(
        [
            Notification(
                customer_id=user.id,
                category="transaction",
                title_en="Transfer completed (simulated)",
                title_ar="تم تنفيذ التحويل (محاكاة)",
                body_en="5,000.00 EGP moved to your investment account.",
                body_ar="تم تحويل 5,000.00 جنيه إلى حساب الاستثمار.",
                related_entity_type="transaction",
                cta_route="/transactions",
                created_at=NOW - timedelta(days=12),
            ),
            Notification(
                customer_id=user.id,
                category="security",
                title_en="New device signed in",
                title_ar="تم تسجيل الدخول من جهاز جديد",
                body_en="A new device signed in. If this was not you, contact us.",
                body_ar="تم تسجيل الدخول من جهاز جديد. إذا لم تكن أنت، يُرجى التواصل معنا.",
                priority="high",
                cta_route="/support",
                created_at=NOW - timedelta(days=3),
            ),
            Notification(
                customer_id=user.id,
                category="request_status",
                title_en="Additional information required",
                title_ar="مطلوب معلومات إضافية",
                body_en="We need your current address to complete your request.",
                body_ar="نحتاج إلى عنوانك الحالي لإكمال طلبك.",
                priority="high",
                related_entity_type="service_request",
                related_entity_id=str(info_request.id) if info_request else None,
                cta_route=f"/requests/{info_request.id}" if info_request else "/requests",
                created_at=NOW - timedelta(days=7),
            ),
            Notification(
                customer_id=None,
                category="maintenance",
                title_en="Scheduled maintenance on Friday",
                title_ar="صيانة مجدولة يوم الجمعة",
                body_en="Digital services will be unavailable from 02:00 to 04:00.",
                body_ar="ستتوقف الخدمات الرقمية من الساعة 2:00 حتى 4:00 صباحاً.",
                cta_route="/notifications",
                created_at=NOW - timedelta(days=1),
            ),
        ]
    )
    db.commit()


def seed_support(db, data: dict) -> None:
    user = data["user1"]
    if db.scalar(select(SupportTicket.id).where(SupportTicket.customer_id == user.id).limit(1)):
        return
    ticket = SupportTicket(
        reference=ref("SUP"),
        customer_id=user.id,
        subject="Question about my supplementary card",
        status="open",
        priority="normal",
        created_at=NOW - timedelta(days=4),
    )
    ticket.messages.append(
        SupportMessage(
            sender_type="customer",
            sender_id=user.id,
            body="When will the supplementary card be issued?",
            created_at=NOW - timedelta(days=4),
        )
    )
    ticket.messages.append(
        SupportMessage(
            sender_type="agent",
            body="Thank you for contacting us. This demo request is being reviewed.",
            created_at=NOW - timedelta(days=3),
        )
    )
    db.add(ticket)
    db.commit()
