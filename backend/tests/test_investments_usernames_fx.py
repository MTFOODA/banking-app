from datetime import datetime, timedelta, timezone
from decimal import Decimal
from types import SimpleNamespace
import uuid
import pytest
from sqlalchemy import select, func
from app.core.security import hash_token
from app.models.investment import InvestmentHolding, InvestmentTerms
from app.models.transactions import TransactionEntry
from app.models.banking import Account
from app.models.user import User
from app.models.security import AuthorizationGrant
from app.services import investment_service, username_service, fx_service
from tests.test_security_flows import enrollment, start, verify, headers
from tests.test_auth_and_ownership import READY_USERS, login

API='/api/v1'


@pytest.fixture
def investment_data(client, db_session):
    investment_service.seed_products(db_session)
    h=headers(client, READY_USERS[2])
    account=client.get(API+'/accounts', headers=h).json()['accounts'][0]['id']
    products=client.get(API+'/investments/products', headers=h).json()
    return h,account,products


def authorize(client,h,action,password='Omar#2026'):
    response=client.post(API+'/auth/authorize',headers=h,json={'scope':'investment_'+action['action'],
        'current_password':password,'investment':action})
    assert response.status_code==200,response.text
    return response.json()['authorization_token']


def execute(client,h,action,token,key=None):
    return client.post(API+'/investments/execute',headers={**h,'Idempotency-Key':key or str(uuid.uuid4())},
        json={**action,'authorization_token':token})


@pytest.mark.parametrize('suffix',['3Y','4Y','5Y','7Y','INCOME','GROWTH'])
def test_actual_subscription_redemption_balanced_ledger_and_retry(client,db_session,investment_data,suffix):
    h,account,products=investment_data
    product=next(p for p in products if p['code'].endswith('-'+suffix))
    amount=product['minimum_amount']
    action={'action':'subscribe','account_id':account,'product_id':product['id'],'amount':amount}
    initial=db_session.get(Account,uuid.UUID(account)).current_balance
    token=authorize(client,h,action)
    key=str(uuid.uuid4())
    response=execute(client,h,action,token,key)
    assert response.status_code==200,response.text
    receipt=response.json()
    db_session.expire_all()
    assert db_session.get(Account,uuid.UUID(account)).current_balance==initial-Decimal(amount)
    assert execute(client,h,action,token,key).json()==receipt
    assert execute(client,h,action,token).status_code==409
    holding=db_session.get(InvestmentHolding,uuid.UUID(receipt['holding_id']))
    assert holding.status=='active'
    redeem={'action':'redeem','holding_id':receipt['holding_id']}
    quote=client.post(API+'/investments/quote',headers=h,json=redeem).json()
    expected_penalty=Decimal(amount)*Decimal('0.05') if product['term_months'] else Decimal(0)
    assert Decimal(quote['penalty'])==expected_penalty
    redemption_token=authorize(client,h,redeem)
    redeemed=execute(client,h,redeem,redemption_token)
    assert redeemed.status_code==200,redeemed.text
    db_session.expire_all()
    assert db_session.get(Account,uuid.UUID(account)).current_balance==initial-expected_penalty
    assert db_session.get(InvestmentHolding,holding.id).status=='redeemed'
    assert execute(client,h,redeem,redemption_token).status_code==409
    grouped=db_session.execute(select(TransactionEntry.transaction_id, TransactionEntry.entry_type,
        func.sum(TransactionEntry.amount)).where(TransactionEntry.investment_holding_id==holding.id)
        .group_by(TransactionEntry.transaction_id,TransactionEntry.entry_type)).all()
    totals={}
    for tx,direction,value in grouped:totals.setdefault(tx,{})[direction]=value
    assert len(totals)==2 and all(v['debit']==v['credit'] for v in totals.values())


def test_penalty_decreases_with_remaining_term_and_zero_at_maturity():
    opened=datetime(2024,1,1,tzinfo=timezone.utc)
    due=datetime(2027,1,1,tzinfo=timezone.utc)
    holding=SimpleNamespace(opened_at=opened,matures_at=due,principal=Decimal('1000'),max_penalty_percent=Decimal('5'))
    assert investment_service.redemption(holding,opened)['penalty']=='50.00'
    assert investment_service.redemption(holding,opened+(due-opened)/2)['penalty']=='25.00'
    assert investment_service.redemption(holding,due)['penalty']=='0.00'
    assert investment_service.redemption(holding,due+timedelta(days=50))['net_credit']=='1000.00'
    assert investment_service.maturity(datetime(2024,2,29,tzinfo=timezone.utc),36).day==28


def test_investment_validation_scope_alteration_and_ownership(client,db_session,investment_data):
    h,account,products=investment_data
    p=next(p for p in products if p['code'].endswith('-3Y'))
    action={'action':'subscribe','product_id':p['id'],'account_id':account,'amount':'1000.00'}
    assert client.get(API+'/investments/holdings').status_code==401
    assert client.post(API+'/investments/quote',headers=h,json={**action,'amount':'-1'}).status_code==422
    assert client.post(API+'/investments/quote',headers=h,json={**action,'amount':'999'}).status_code==422
    assert client.post(API+'/investments/quote',headers=h,json={**action,'amount':'999999000'}).status_code==409
    assert client.post(API+'/investments/quote',headers=headers(client),json=action).status_code==404
    token=authorize(client,h,action)
    assert execute(client,h,{**action,'amount':'2000.00'},token).status_code==403
    grant=db_session.scalar(select(AuthorizationGrant).where(AuthorizationGrant.token_hash==hash_token(token)))
    grant.expires_at=datetime.now(timezone.utc)-timedelta(seconds=1)
    db_session.commit()
    assert execute(client,h,action,token).status_code==403
    bad=client.post(API+'/auth/authorize',headers=h,json={'scope':'investment_subscribe','current_password':'wrong','investment':action})
    assert bad.status_code==400
    other=client.post(API+'/auth/authorize',headers=h,json={'scope':'password_change','current_password':'Omar#2026'}).json()['authorization_token']
    assert execute(client,h,action,other).status_code==403
    assert investment_service.seed_products(db_session)==0


def test_investment_rolls_back_balance_grant_and_holding_on_failure(client,db_session,investment_data,monkeypatch):
    h,account,products=investment_data
    action={'action':'subscribe','product_id':products[0]['id'],'account_id':account,'amount':products[0]['minimum_amount']}
    token=authorize(client,h,action)
    initial=db_session.get(Account,uuid.UUID(account)).current_balance
    monkeypatch.setattr(investment_service.notification_service,'notify',lambda *a,**k: (_ for _ in ()).throw(RuntimeError('injected failure')))
    with pytest.raises(RuntimeError):execute(client,h,action,token)
    db_session.expire_all()
    assert db_session.get(Account,uuid.UUID(account)).current_balance==initial
    grant=db_session.scalar(select(AuthorizationGrant).where(AuthorizationGrant.token_hash==hash_token(token)))
    assert grant.consumed_at is None
    assert db_session.scalar(select(func.count()).select_from(InvestmentHolding))==0


def test_unique_username_suggestions_enrollment_and_login(client,db_session,enrollment):
    user,codes=enrollment
    other=db_session.scalar(select(User).where(User.id!=user.id))
    other.username='ahmed'
    other.username_key=username_service.username_key('ahmed')
    db_session.commit()
    challenge=start(client).json()['challenge']
    grant=verify(client,challenge,codes[-1]['code']).json()['authorization_token']
    def check(name,token=grant):return client.post(API+'/auth/registration/username',json={'authorization_token':token,'username':name})
    assert check('ahmed','x'*32).status_code==403
    occupied=check('AHMED').json()
    assert not occupied['available'] and len(set(occupied['suggestions']))==3
    assert all(name.startswith('ahmed') for name in occupied['suggestions'])
    chosen=occupied['suggestions'][0]
    assert check(chosen).json()['available']
    body={'authorization_token':grant,'username':'ahmed','new_password':'Fresh#Username26','confirm_password':'Fresh#Username26'}
    conflict=client.post(API+'/auth/registration/complete',json=body)
    assert conflict.status_code==409 and len(conflict.json()['error']['details']['suggestions'])==3
    assert client.post(API+'/auth/registration/complete',json={**body,'username':chosen}).status_code==200
    assert login(client,chosen.upper(),'Fresh#Username26').status_code==200
    assert not check(chosen).status_code==200


@pytest.mark.parametrize('name',['12user','ab','a'*31,'admin','user name','اسم','bad@name','user.name','user_name','user-name'])
def test_username_format(name):
    from app.core.exceptions import AppError
    with pytest.raises(AppError):username_service.normalize_username(name)


def test_fx_parse_inversion_delay_no_invented_bank_prices_and_bad_input():
    now=datetime.now(timezone.utc).isoformat()
    data={'result':'success','base':'EGP','source':'live','market_session':'open','data_updated_at':now,
        'rates':{symbol:0.02 for symbol in fx_service.SYMBOLS}}
    parsed=fx_service.parse(data,900)
    assert parsed['delay_seconds']==900 and parsed['spread_is_simulated'] and not parsed['is_executable']
    row=parsed['quotes'][0]
    assert Decimal(row['mid'])==50 and Decimal(row['buy'])<50<Decimal(row['sell'])
    data['rates']['USD']=0
    with pytest.raises(ValueError):fx_service.parse(data,900)


def test_fx_cache_rate_limit_failure_and_recovery(monkeypatch):
    import httpx
    calls = []
    broken = [False]
    clock = [100.0]
    now = datetime.now(timezone.utc).isoformat()
    data = {'result': 'success', 'base': 'EGP', 'source': 'live', 'data_updated_at': now,
            'rates': {symbol: 0.02 for symbol in fx_service.SYMBOLS}}
    class Client:
        def __init__(self, **kwargs): pass
        def __enter__(self): return self
        def __exit__(self, *args): pass
        def get(self, url, **kwargs):
            calls.append(url)
            if broken[0]: raise httpx.ConnectError('unavailable')
            return httpx.Response(200, json=data, headers={'X-Price-Delay-Seconds': '900'}, request=httpx.Request('GET', url))
    monkeypatch.setattr(fx_service.httpx, 'Client', Client)
    monkeypatch.setattr(fx_service.time, 'monotonic', lambda: clock[0])
    monkeypatch.setattr(fx_service, '_cache', None)
    monkeypatch.setattr(fx_service, '_retry_at', 0)
    monkeypatch.setattr(fx_service, '_failure', False)
    first = fx_service.latest()
    assert first['delay_seconds'] == 900 and len(calls) == 1
    fx_service.latest()
    assert len(calls) == 1
    clock[0] += 10000
    broken[0] = True
    cached = fx_service.latest()
    assert cached['stale'] and cached['upstream_unavailable']
    assert cached['quotes'] == first['quotes']
    monkeypatch.setattr(fx_service, '_cache', None)
    from app.core.exceptions import AppError
    with pytest.raises(AppError) as error: fx_service.latest()
    assert error.value.code == 'fx_unavailable'
    broken[0] = False
    clock[0] += 10000
    assert not fx_service.latest()['upstream_unavailable']


def test_investment_seed_failure_rolls_back_partial_catalogue(db_session, monkeypatch):
    from app.models.content import BankingProduct
    original = investment_service.InvestmentTerms
    calls = [0]
    def fail_second(**kwargs):
        calls[0] += 1
        if calls[0] == 2:
            raise RuntimeError('injected catalogue failure')
        return original(**kwargs)
    monkeypatch.setattr(investment_service, 'InvestmentTerms', fail_second)
    with pytest.raises(RuntimeError):
        investment_service.seed_products(db_session)
    db_session.rollback()
    assert db_session.scalar(select(func.count()).select_from(BankingProduct).where(
        BankingProduct.code.like('INV-DEMO-%'))) == 0
