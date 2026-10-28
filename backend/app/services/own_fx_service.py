"""Freeze indicative bid/ask values for a bounded local FX simulation.

These are not executable bank dealing prices. No new rate is fetched while
password/grant/account locks are held; authorization consumes an existing quote.
"""
from datetime import timedelta,timezone
from decimal import Decimal,localcontext,ROUND_DOWN
from sqlalchemy import select
from app.core.config import settings
from app.core.exceptions import AppError
from app.models.fx_transfer import OwnFxQuote
from app.services import fx_service,security_service
from app.services.common import utcnow

MAX_MONEY=Decimal('9999999999999999.99')

def _error(code,message,status=422):raise AppError(code=code,message=message,status_code=status)

def draft_binding(draft):
    data=draft.model_dump(mode='json',exclude={'authorization_token','fx_quote_id'})
    data['amount']=format(draft.amount.quantize(Decimal('.01')),'f')
    return security_service.fingerprint(data)

def quote_binding(quote):
    return security_service.fingerprint({'id':str(quote.id),'draft':quote.draft_fingerprint,
        'rate':format(quote.exchange_rate.quantize(Decimal('.000000000001')),'f'),
        'received':format(quote.received_amount.quantize(Decimal('.01')),'f'),
        'currency':quote.received_currency,'provider':quote.provider,
        'market_at':quote.market_at.astimezone(timezone.utc).isoformat(),
        'expires_at':quote.expires_at.astimezone(timezone.utc).isoformat()})

def get_quote(db,user,draft,source,destination,*,lock=False):
    stmt=select(OwnFxQuote).where(OwnFxQuote.id==draft.fx_quote_id,OwnFxQuote.customer_id==user.id)
    quote=db.scalar((stmt.with_for_update() if lock else stmt).execution_options(populate_existing=True))
    if not quote or quote.draft_fingerprint!=draft_binding(draft) or quote.source_account_id!=source.id or quote.destination_account_id!=destination.id or quote.source_currency!=source.currency or quote.received_currency!=destination.currency:
        _error('invalid_fx_quote','Review and obtain an FX quote for these own accounts.',403)
    if quote.consumed_at:_error('fx_quote_used','This FX quote has already been consumed.',409)
    if quote.expires_at<=utcnow():_error('fx_quote_expired','The exchange quote expired. Review and authorize again.',409)
    if lock:quote.consumed_at=utcnow()
    return quote

def _price(feed,currency,side):
    if currency=='EGP':return Decimal(1),None
    row=next((row for row in feed['quotes'] if row['currency']==currency),None)
    if row is None or row.get('stale'):_error('fx_unavailable','No fresh indicative price is available for this currency.',503)
    rate=Decimal(str(row[side]))
    if not rate.is_finite() or rate<=0:_error('fx_unavailable','Invalid market price.',503)
    return rate,fx_service._timestamp(row['updated_at'])

def create_quote(db,user,draft,source,destination):
    if draft.transfer_type!='own_accounts' or source.customer_id!=user.id or destination.customer_id!=user.id:
        _error('currency_mismatch','Currency conversion is allowed only between your own accounts.')
    # This commits only the abuse counter before network I/O; no banking changes
    # or operation grants have been created at this stage.
    security_service.throttle(db,f'own_fx_quote:{user.id}',10)
    src_currency,dst_currency=source.currency,destination.currency
    # Release the read transaction/connection before the market-data request.
    db.commit()
    feed=fx_service.latest()
    if feed.get('stale') or feed.get('upstream_unavailable'):
        _error('fx_unavailable','Fresh market data is unavailable. No conversion was performed.',503)
    buy,src_at=_price(feed,src_currency,'buy');sell,dst_at=_price(feed,dst_currency,'sell')
    with localcontext() as context:
        context.prec=38
        rate=(buy/sell).quantize(Decimal('.000000000001'))
        received=(draft.amount*rate).quantize(Decimal('.01'),rounding=ROUND_DOWN)
    if received<=0 or received>MAX_MONEY:_error('fx_amount_invalid','The received amount is outside the supported range.')
    timestamps=[value for value in [src_at,dst_at] if value is not None]
    quote=OwnFxQuote(customer_id=user.id,source_account_id=source.id,destination_account_id=destination.id,
        draft_fingerprint=draft_binding(draft),source_amount=draft.amount,source_currency=src_currency,
        received_amount=received,received_currency=dst_currency,exchange_rate=rate,
        provider=feed['source'],market_at=min(timestamps),expires_at=utcnow()+timedelta(seconds=settings.own_fx_quote_seconds))
    db.add(quote);db.commit();db.refresh(quote)
    return quote

def response(quote):
    return {'fx_quote_id':str(quote.id),'exchange_rate':format(quote.exchange_rate,'f'),
        'received_amount':format(quote.received_amount,'.2f'),'received_currency':quote.received_currency,
        'rate_provider':quote.provider,'rate_as_of':quote.market_at.isoformat(),
        'fx_quote_expires_at':quote.expires_at.isoformat(),'rate_is_simulated':True}
