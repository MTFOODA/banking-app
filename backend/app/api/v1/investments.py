from fastapi import APIRouter, Depends, Header
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.dependencies.auth import get_current_customer
from app.models.user import User
from app.schemas.investment import InvestmentAction, InvestmentExecute
from app.services import investment_service, fx_service

router = APIRouter(tags=['Investments and market data'])


@router.get('/investments/products')
def products(db: Session = Depends(get_db), user: User = Depends(get_current_customer)):
    return investment_service.products(db)


@router.get('/investments/holdings')
def holdings(db: Session = Depends(get_db), user: User = Depends(get_current_customer)):
    return investment_service.positions(db, user)


@router.post('/investments/quote')
def quote(payload: InvestmentAction, db: Session = Depends(get_db), user: User = Depends(get_current_customer)):
    return investment_service.quote(db, user, payload)


@router.post('/investments/execute')
def execute(payload: InvestmentExecute, idempotency_key: str = Header('', alias='Idempotency-Key'),
    db: Session = Depends(get_db), user: User = Depends(get_current_customer)):
    return investment_service.execute(db, user, payload, idempotency_key)


@router.get('/exchange-rates')
def rates(user: User = Depends(get_current_customer)):
    return fx_service.latest()
