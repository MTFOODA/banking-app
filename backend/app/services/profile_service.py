"""Customer profile and preference synchronisation."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.user import CustomerPreference, CustomerProfile, RefreshSession, User
from app.services.common import record_audit, utcnow


def get_profile(user: User, db: Session | None = None) -> dict:
    from app.schemas.auth import CustomerProfileResponse
    profile = CustomerProfileResponse.model_validate(user.profile).model_dump()
    email = profile.get("email")
    phone = profile.get("phone")
    profile["email"] = (email[0] + "***@" + email.split("@")[-1]) if email and "@" in email else None
    profile["phone"] = "***" + phone[-4:] if phone else None
    profile["customer_number"] = "***" + profile["customer_number"][-4:]
    pending_reference = None
    if db:
        from app.models.service import ServiceRequest
        pending_reference = db.scalar(select(ServiceRequest.reference).where(
            ServiceRequest.customer_id == user.id, ServiceRequest.request_type == "customer_info_update",
            ServiceRequest.status.notin_(["completed", "cancelled", "rejected"])
        ).order_by(ServiceRequest.created_at.desc()).limit(1))
    return {
        "username": user.username,
        "pending_reference": pending_reference,
        "user_id": user.id,
        "login_identifier_masked": user.login_identifier_masked,
        "must_change_password": user.must_change_password,
        "profile": profile,
        "roles": user.role_codes,
        "permissions": user.permission_codes,
        "preferred_language": user.preferences.language if user.preferences else None,
        "preferred_theme": user.preferences.theme if user.preferences else None,
    }


def update_profile(db: Session, user: User, changes: dict) -> dict:
    from app.services import request_service
    token = changes.pop("authorization_token", "")
    fields = {key: value for key, value in changes.items() if value is not None}
    request = request_service.create_request(db, user, request_type="customer_info_update",
                                             form_data=fields, authorization_token=token)
    return {"status": "pending_review", "reference": request.reference,
            "message": "Submitted for bank review. Verified contact information has not changed."}


def get_or_create_preferences(db: Session, user: User) -> CustomerPreference:
    if user.preferences is None:
        preferences = CustomerPreference(user_id=user.id)
        db.add(preferences)
        db.commit()
        db.refresh(preferences)
        return preferences
    return user.preferences


def update_preferences(db: Session, user: User, changes: dict) -> CustomerPreference:
    preferences = get_or_create_preferences(db, user)
    for field, value in changes.items():
        if value is not None:
            setattr(preferences, field, value)
    record_audit(
        db,
        actor=user,
        action="preferences.updated",
        entity_type="customer_preference",
        entity_id=preferences.id,
        details={"fields": sorted(changes.keys())},
    )
    db.commit()
    db.refresh(preferences)
    return preferences


def active_sessions(db: Session, user: User, current_session_id: str | None) -> list[dict]:
    rows = db.scalars(
        select(RefreshSession)
        .where(RefreshSession.user_id == user.id, RefreshSession.revoked_at.is_(None))
        .order_by(RefreshSession.created_at.desc())
    ).all()
    result = []
    for session in rows:
        if session.expires_at <= utcnow():
            continue
        result.append(
            {
                "id": session.id,
                "user_agent": session.user_agent,
                "ip_address": session.ip_address,
                "created_at": session.created_at,
                "last_used_at": session.last_used_at,
                "expires_at": session.expires_at,
                "current": str(session.id) == str(current_session_id or ""),
            }
        )
    return result
