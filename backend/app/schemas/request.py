"""Service request schemas shared by customers and administrators."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from app.models.enums import RequestType


class RequestDocumentResponse(BaseModel):
    id: uuid.UUID
    filename: str
    content_type: str
    size_bytes: int
    created_at: datetime


class RequestStatusHistoryResponse(BaseModel):
    id: uuid.UUID
    from_status: str | None = None
    to_status: str
    note: str | None = None
    actor_label: str | None = None
    created_at: datetime


class ServiceRequestResponse(BaseModel):
    id: uuid.UUID
    reference: str
    request_type: str
    status: str
    priority: str
    submitted_at: datetime | None = None
    created_at: datetime
    updated_at: datetime
    decided_at: datetime | None = None
    assigned_label: str | None = None
    decision_reason: str | None = None
    customer_explanation: str | None = None
    form_data: dict = Field(default_factory=dict)
    history: list[RequestStatusHistoryResponse] = Field(default_factory=list)
    documents: list[RequestDocumentResponse] = Field(default_factory=list)
    available_actions: list[str] = Field(default_factory=list)

    @classmethod
    def from_model(cls, request, *, available_actions: list[str] | None = None):
        return cls(
            id=request.id,
            reference=request.reference,
            request_type=request.request_type,
            status=request.status,
            priority=request.priority,
            submitted_at=request.submitted_at,
            created_at=request.created_at,
            updated_at=request.updated_at,
            decided_at=request.decided_at,
            assigned_label=request.assigned_label,
            decision_reason=request.decision_reason,
            customer_explanation=request.customer_explanation,
            form_data=request.form_data or {},
            history=[
                RequestStatusHistoryResponse(
                    id=item.id,
                    from_status=item.from_status,
                    to_status=item.to_status,
                    note=item.note,
                    actor_label=item.actor_label,
                    created_at=item.created_at,
                )
                for item in request.history
                if item.is_customer_visible
            ],
            documents=[
                RequestDocumentResponse(
                    id=doc.id,
                    filename=doc.filename,
                    content_type=doc.content_type,
                    size_bytes=doc.size_bytes,
                    created_at=doc.created_at,
                )
                for doc in request.documents
            ],
            available_actions=available_actions or [],
        )


class RequestCreate(BaseModel):
    authorization_token: str | None = Field(default=None, max_length=128)
    request_type: RequestType
    form_data: dict = Field(default_factory=dict)
    priority: str | None = Field(default=None, pattern="^(low|normal|high)$")
    submit: bool = True

    @field_validator("form_data")
    @classmethod
    def _limit_size(cls, value: dict) -> dict:
        if len(value) > 40:
            raise ValueError("Too many form fields")
        return value


class AdditionalInformationRequest(BaseModel):
    authorization_token: str | None = Field(default=None, max_length=128)
    message: str = Field(min_length=5, max_length=2000)
    fields: dict = Field(default_factory=dict)


class AdminDecisionRequest(BaseModel):
    reason: str | None = Field(default=None, max_length=1000)
    customer_explanation: str | None = Field(default=None, max_length=2000)


class AdminRejectRequest(BaseModel):
    reason: str = Field(min_length=5, max_length=1000)
    customer_explanation: str | None = Field(default=None, max_length=2000)


class AdminRequestInformationRequest(BaseModel):
    message: str = Field(min_length=5, max_length=2000)
    required_fields: list[str] = Field(default_factory=list)


class AdminAssignRequest(BaseModel):
    reviewer_id: uuid.UUID | None = None


class AdminNoteRequest(BaseModel):
    note: str = Field(min_length=2, max_length=2000)
