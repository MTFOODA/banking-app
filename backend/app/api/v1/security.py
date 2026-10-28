"""Registration and reusable password re-authentication endpoints."""
from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.dependencies.auth import client_meta, get_current_user
from app.models.user import User
from app.schemas.security import AuthorizationConsume, AuthorizationRequest, ChallengeRequest, OtpVerify, RegistrationComplete, RegistrationStart, UsernameCheck
from app.services import registration_service, security_service

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/registration/start")
def start(payload: RegistrationStart, request: Request, db: Session = Depends(get_db)):
    return registration_service.start(db, payload.identifier, client_meta(request)["ip_address"] or "unknown", bank_code=payload.bank_code, card_only=payload.identifier_type == 'card')


@router.post("/registration/resend")
def resend(payload: ChallengeRequest, request: Request, db: Session = Depends(get_db)):
    return registration_service.resend(db, payload.challenge, client_meta(request)["ip_address"] or "unknown")


@router.post("/registration/verify")
def verify(payload: OtpVerify, request: Request, db: Session = Depends(get_db)):
    token = registration_service.verify(db, payload.challenge, payload.code, client_meta(request)["ip_address"] or "unknown")
    return {"authorization_token": token, "expires_in": settings.authorization_ttl_seconds}


@router.post("/registration/complete")
def complete(payload: RegistrationComplete, request: Request, db: Session = Depends(get_db)):
    user, issued = registration_service.complete(db, payload.authorization_token, payload.new_password,
                                                 payload.confirm_password, client_meta(request), username=payload.username)
    from app.api.v1.auth import _login_response
    return _login_response("authenticated", issued, None, None, user)


@router.post("/registration/username")
def username_check(payload: UsernameCheck, request: Request, db: Session = Depends(get_db)):
    from app.services import username_service
    return username_service.check(db, payload.authorization_token, payload.username, client_meta(request)["ip_address"] or "unknown")


@router.post("/authorize")
def authorize(payload: AuthorizationRequest, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    token = security_service.authorize_operation(db, user, payload.scope, payload.current_password, payload.transfer, payload.investment)
    return {"authorization_token": token, "expires_in": settings.authorization_ttl_seconds, "scope": payload.scope}


@router.post("/biometric/confirm")
def confirm_biometric(payload: AuthorizationConsume, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    security_service.confirm_biometric_configuration(db, user, payload.authorization_token)
    return {"status": "authorized"}
