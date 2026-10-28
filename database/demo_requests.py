"""Demo service requests with status history."""

from __future__ import annotations

from datetime import timedelta

from sqlalchemy import select

from app.models.service import RequestStatusHistory, ServiceRequest
from demo_common import NOW, ref


def _add_history(db, request, to_status: str, note: str, *, days: int, actor: str) -> None:
    db.add(
        RequestStatusHistory(
            request_id=request.id,
            from_status=None,
            to_status=to_status,
            note=note,
            actor_label=actor,
            created_at=NOW - timedelta(days=days),
        )
    )


def seed_requests(db, data: dict) -> None:
    user = data["user1"]
    if db.scalar(select(ServiceRequest.id).where(ServiceRequest.customer_id == user.id).limit(1)):
        return

    limit_request = ServiceRequest(
        reference=ref("REQ"),
        customer_id=user.id,
        request_type="card_limit_increase",
        status="submitted",
        priority="normal",
        form_data={
            "card_id": str(data["debit1"].id),
            "card_last4": data["debit1"].card_last4,
            "limit_type": "daily_purchase",
            "requested_amount": "40000",
            "reason": "Higher daily limit for business travel",
        },
        submitted_at=NOW - timedelta(days=2),
        created_at=NOW - timedelta(days=2),
        updated_at=NOW - timedelta(days=2),
    )
    supplementary_request = ServiceRequest(
        reference=ref("REQ"),
        customer_id=user.id,
        request_type="supplementary_card",
        status="under_review",
        priority="normal",
        assigned_label="Demo Administrator",
        form_data={
            "primary_card_id": str(data["credit1"].id),
            "holder_first_name": "Sara",
            "holder_last_name": "Hassan",
            "holder_relationship": "family",
            "holder_national_id": "2***********88",
            "spending_limit": "15000",
        },
        submitted_at=NOW - timedelta(days=6),
        created_at=NOW - timedelta(days=6),
        updated_at=NOW - timedelta(days=4),
    )
    info_request = ServiceRequest(
        reference=ref("REQ"),
        customer_id=user.id,
        request_type="customer_info_update",
        status="pending_customer_info",
        priority="normal",
        form_data={"phone": "+20 100 000 0001", "required_fields": ["address"]},
        submitted_at=NOW - timedelta(days=9),
        created_at=NOW - timedelta(days=9),
        updated_at=NOW - timedelta(days=7),
    )
    completed_request = ServiceRequest(
        reference=ref("REQ"),
        customer_id=user.id,
        request_type="account_open",
        status="completed",
        priority="normal",
        form_data={"product_code": "AP-INVESTMENT"},
        decision_reason="Eligibility confirmed",
        customer_explanation="Your investment account has been opened.",
        submitted_at=NOW - timedelta(days=40),
        created_at=NOW - timedelta(days=40),
        updated_at=NOW - timedelta(days=36),
        decided_at=NOW - timedelta(days=36),
    )
    db.add_all([limit_request, supplementary_request, info_request, completed_request])
    db.flush()

    _add_history(db, limit_request, "submitted", "Request submitted.", days=2, actor="Customer")
    _add_history(db, supplementary_request, "submitted", "Request submitted.", days=6, actor="Customer")
    _add_history(
        db, supplementary_request, "under_review", "Assigned to card operations.", days=4, actor="Bank"
    )
    _add_history(db, info_request, "submitted", "Request submitted.", days=9, actor="Customer")
    _add_history(
        db,
        info_request,
        "pending_customer_info",
        "Please confirm your current residential address.",
        days=7,
        actor="Bank",
    )
    _add_history(db, completed_request, "submitted", "Request submitted.", days=40, actor="Customer")
    _add_history(db, completed_request, "approved", "Approved by operations.", days=37, actor="Bank")
    _add_history(db, completed_request, "completed", "Account opened.", days=36, actor="Bank")
    db.commit()
