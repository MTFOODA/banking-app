"""Service request endpoints including document upload."""

from __future__ import annotations

import re
import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, Query, UploadFile
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.exceptions import AppError
from app.dependencies.auth import get_current_customer
from app.models.user import User
from app.schemas.common import Page
from app.schemas.profile import DocumentUploadResponse
from app.schemas.request import (
    AdditionalInformationRequest,
    RequestCreate,
    ServiceRequestResponse,
)
from app.services import request_service

router = APIRouter(prefix="/requests", tags=["Requests"])


def _response(request) -> ServiceRequestResponse:
    return ServiceRequestResponse.from_model(
        request, available_actions=request_service.customer_actions(request)
    )


@router.get("", response_model=Page[ServiceRequestResponse], summary="List my requests")
def list_requests(
    status: str | None = None,
    request_type: str | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> Page[ServiceRequestResponse]:
    rows, total = request_service.list_requests(
        db,
        user,
        status=status,
        request_type=request_type,
        page=page,
        page_size=page_size,
    )
    return Page.build(
        [_response(item) for item in rows], page=page, page_size=page_size, total=total
    )


@router.post("", response_model=ServiceRequestResponse, status_code=201, summary="Create a request")
def create_request(
    payload: RequestCreate,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    request = request_service.create_request(
        db,
        user,
        request_type=payload.request_type.value,
        form_data=payload.form_data,
        priority=payload.priority,
        submit=payload.submit,
        authorization_token=payload.authorization_token,
    )
    return _response(request)


@router.get("/{request_id}", response_model=ServiceRequestResponse, summary="Request details")
def get_request(
    request_id: uuid.UUID,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    return _response(request_service.get_request(db, user, request_id))


@router.post(
    "/{request_id}/additional-information",
    response_model=ServiceRequestResponse,
    summary="Provide requested information",
)
def provide_information(
    request_id: uuid.UUID,
    payload: AdditionalInformationRequest,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    request = request_service.add_information(
        db, user, request_id, message=payload.message, fields=payload.fields,
        authorization_token=payload.authorization_token
    )
    return _response(request)


@router.post(
    "/{request_id}/cancel",
    response_model=ServiceRequestResponse,
    summary="Cancel a pending request",
)
def cancel_request(
    request_id: uuid.UUID,
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> ServiceRequestResponse:
    return _response(request_service.cancel_request(db, user, request_id))


@router.post(
    "/{request_id}/documents",
    response_model=DocumentUploadResponse,
    status_code=201,
    summary="Upload a supporting document",
)
async def upload_document(
    request_id: uuid.UUID,
    file: UploadFile = File(...),
    user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> DocumentUploadResponse:
    request_service.get_request(db, user, request_id)  # ownership check

    content_type = (file.content_type or "").lower()
    if content_type not in settings.allowed_upload_content_types:
        raise AppError(
            code="unsupported_document_type",
            message="Only PDF, PNG and JPEG documents are accepted.",
            status_code=415,
        )

    safe_name = re.sub(r"[^A-Za-z0-9._-]", "_", Path(file.filename or "document").name)[:120]
    target_dir = Path(settings.upload_dir) / str(request_id)
    target_dir.mkdir(parents=True, exist_ok=True)
    target_path = target_dir / f"{uuid.uuid4().hex}_{safe_name}"

    size = 0
    with target_path.open("wb") as handle:
        while chunk := await file.read(64 * 1024):
            size += len(chunk)
            if size > settings.max_upload_bytes:
                handle.close()
                target_path.unlink(missing_ok=True)
                raise AppError(
                    code="document_too_large",
                    message="The document exceeds the 5 MB limit.",
                    status_code=413,
                )
            handle.write(chunk)
    await file.close()

    document = request_service.attach_document(
        db,
        user,
        request_id,
        filename=safe_name,
        content_type=content_type,
        size_bytes=size,
        storage_path=str(target_path),
    )
    return DocumentUploadResponse(
        id=document.id,
        filename=document.filename,
        content_type=document.content_type,
        size_bytes=document.size_bytes,
        created_at=document.created_at,
    )
