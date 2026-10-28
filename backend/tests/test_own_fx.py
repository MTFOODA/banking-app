from datetime import timedelta
from decimal import Decimal
import uuid
import pytest
from sqlalchemy import select,func
from app.core.config import settings
from app.core.exceptions import AppError
from app.models.banking import Account,AccountProduct
from app.models.user import User
from app.models.fx_transfer import OwnFxQuote
from app.models.transactions import Transaction,TransactionEntry
from app.models.security import AuthorizationGrant
from app.services import fx_service,notification_service,security_service,transfer_execution
from app.services.common import utcnow
from app.schemas.transaction import TransferCreate
from tests.test_security_flows import headers

API='/api/v1'

@pytest.fixture
def fx_data(client,db_session,monkeypatch):
    h=headers(client);user_id=uuid.UUID(client.get(API+'/auth/me',headers=h).json()['id'])
    accounts={}
    for currency in ['EGP','USD','SAR']:
        product=db_session.scalar(select(AccountProduct).where(AccountProduct.code=='AP-CURRENT'+('' if currency=='EGP' else '-'+currency)))
        account=Account(customer_id=user_id,product_id=product.id,account_number_hash=uuid.uuid4().hex*2,
            account_number_masked='**** FX '+currency,account_type='current',currency=currency,status='active',
            current_balance=1000,available_balance=1000,blocked_balance=0)
        db_session.add(account);db_session.flush();accounts[currency]=account
    db_session.commit()
    feed={'source':'fictional-test-feed','stale':False,'upstream_unavailable':False,
        'quotes':[{'currency':c,'buy':buy,'sell':sell,'stale':False,'updated_at':utcnow().isoformat()}
            for c,buy,sell in [('USD','50','50.5'),('SAR','13','13.1')]]}
    monkeypatch.setattr(fx_service,'latest',lambda:feed)
    return h,accounts,feed

def draft(accounts,source='USD',destination='EGP'):
    return {'transfer_type':'own_accounts','source_account_id':str(accounts[source].id),
        'destination_account_id':str(accounts[destination].id),'currency':source,'amount':'10.00','purpose':'Fictional own FX QA'}

def review(client,h,body):
    r=client.post(API+'/transfers/quote',headers=h,json=body);assert r.status_code==200
    return r.json()

def authorize(client,h,body):
    r=client.post(API+'/auth/authorize',headers=h,json={'scope':'transfer','current_password':'Salma#2026','transfer':body})
    assert r.status_code==200
    return r.json()['authorization_token']

def execute(client,h,body,key=None):
    return client.post(API+'/transfers',headers={**h,'Idempotency-Key':key or uuid.uuid4().hex},json=body)

@pytest.mark.parametrize('source,destination,received',[('USD','EGP','500.00'),('EGP','USD','0.19'),('USD','SAR','38.16')])
def test_frozen_own_fx_and_balanced_per_currency(client,db_session,fx_data,monkeypatch,source,destination,received):
    h,accounts,feed=fx_data;body=draft(accounts,source,destination)
    quote=review(client,h,body);assert quote['received_amount']==received and quote['received_currency']==destination
    assert quote['rate_is_simulated'] is True and quote['rate_provider']=='fictional-test-feed'
    db_session.refresh(accounts[source]);assert accounts[source].available_balance==1000
    body['fx_quote_id']=quote['fx_quote_id']
    # Changing/live market failure cannot change the already reviewed snapshot.
    monkeypatch.setattr(fx_service,'latest',lambda:(_ for _ in ()).throw(AssertionError('Market must not be fetched during authorization or execution')))
    body['authorization_token']=authorize(client,h,body)
    key=uuid.uuid4().hex;r=execute(client,h,body,key);assert r.status_code==201
    result=r.json();assert Decimal(str(result['received_amount']))==Decimal(received)
    assert result['currency']==source and result['received_currency']==destination
    db_session.refresh(accounts[source]);db_session.refresh(accounts[destination])
    assert accounts[source].available_balance==990 and accounts[destination].available_balance==1000+Decimal(received)
    transactions=db_session.scalars(select(Transaction).where(Transaction.journal_id==uuid.UUID(result['journal_id']))).all()
    assert len(transactions)==2 and {t.currency for t in transactions}=={source,destination}
    for currency in [source,destination]:
        tx=next(t for t in transactions if t.currency==currency)
        entries=db_session.scalars(select(TransactionEntry).where(TransactionEntry.transaction_id==tx.id)).all()
        assert len(entries)==2 and sum(e.amount if e.entry_type=='debit' else -e.amount for e in entries)==0
    snapshot=db_session.get(OwnFxQuote,uuid.UUID(quote['fx_quote_id']));assert snapshot.consumed_at is not None
    assert execute(client,h,body,key).json()['reference']==result['reference']
    db_session.refresh(accounts[source]);assert accounts[source].available_balance==990
    assert execute(client,h,body).status_code==409

@pytest.mark.parametrize('change',['amount','destination','purpose','other_user','rate_tamper','expired'])
def test_fx_quote_and_grant_binding(client,db_session,fx_data,change):
    h,accounts,feed=fx_data;body=draft(accounts);quote=review(client,h,body);body['fx_quote_id']=quote['fx_quote_id']
    body['authorization_token']=authorize(client,h,body)
    snapshot=db_session.get(OwnFxQuote,uuid.UUID(quote['fx_quote_id']))
    if change=='amount':body['amount']='11.00'
    if change=='destination':body['destination_account_id']=str(accounts['SAR'].id)
    if change=='purpose':body['purpose']='Altered purpose'
    if change=='other_user':snapshot.customer_id=db_session.scalar(select(User.id).where(User.id!=accounts['USD'].customer_id,User.login_type=='customer'))
    if change=='rate_tamper':snapshot.exchange_rate=Decimal('500')
    if change=='expired':snapshot.expires_at=utcnow()-timedelta(seconds=1)
    db_session.commit()
    assert execute(client,h,body).status_code in {403,409}
    db_session.refresh(accounts['USD']);assert accounts['USD'].available_balance==1000

@pytest.mark.parametrize('case',['stale','unavailable','tiny','missing_quote','recipient_not_owned','legacy_cross','internal_cross'])
def test_fx_fail_closed_and_only_own_accounts(client,db_session,fx_data,monkeypatch,case):
    h,accounts,feed=fx_data;body=draft(accounts)
    if case=='stale':feed['stale']=True
    if case=='unavailable':monkeypatch.setattr(fx_service,'latest',lambda:(_ for _ in ()).throw(AppError(code='fx_unavailable',message='Unavailable',status_code=503)))
    if case=='tiny':body=draft(accounts,'EGP','USD');body['amount']='0.01'
    if case=='recipient_not_owned':body['destination_account_id']=str(db_session.scalar(select(Account.id).where(Account.customer_id!=accounts['USD'].customer_id)))
    if case=='legacy_cross':body.pop('transfer_type')
    if case=='internal_cross':body['transfer_type']='internal'
    if case=='missing_quote':
        r=client.post(API+'/auth/authorize',headers=h,json={'scope':'transfer','current_password':'Salma#2026','transfer':body})
    else:r=client.post(API+'/transfers/quote',headers=h,json=body)
    assert r.status_code in {403,409,422,503}
    db_session.refresh(accounts['USD']);assert accounts['USD'].available_balance==1000

def test_fx_failure_rolls_back_snapshot_grant_and_both_accounts(client,db_session,fx_data,monkeypatch):
    h,accounts,_=fx_data;body=draft(accounts);q=review(client,h,body);body['fx_quote_id']=q['fx_quote_id'];body['authorization_token']=authorize(client,h,body)
    count=db_session.scalar(select(func.count()).select_from(Transaction))
    monkeypatch.setattr(notification_service,'notify',lambda *a,**kw:(_ for _ in ()).throw(RuntimeError('Injected FX rollback')))
    with pytest.raises(RuntimeError,match='Injected FX rollback'):execute(client,h,body)
    db_session.refresh(accounts['USD']);db_session.refresh(accounts['EGP'])
    assert accounts['USD'].available_balance==1000 and accounts['EGP'].available_balance==1000
    assert db_session.get(OwnFxQuote,uuid.UUID(q['fx_quote_id'])).consumed_at is None
    grant=db_session.scalar(select(AuthorizationGrant).where(AuthorizationGrant.token_hash==security_service.hash_token(body['authorization_token'])))
    assert grant.consumed_at is None and db_session.scalar(select(func.count()).select_from(Transaction))==count

def test_actual_time_expiry_rejects_without_changing_grant_binding(client,db_session,fx_data,monkeypatch):
    from app.services import own_fx_service
    h,accounts,_=fx_data;body=draft(accounts);q=review(client,h,body);body['fx_quote_id']=q['fx_quote_id'];body['authorization_token']=authorize(client,h,body)
    snapshot=db_session.get(OwnFxQuote,uuid.UUID(q['fx_quote_id']))
    monkeypatch.setattr(own_fx_service,'utcnow',lambda:snapshot.expires_at+timedelta(seconds=1))
    result=execute(client,h,body);assert result.status_code==409 and result.json()['error']['code']=='fx_quote_expired'
    db_session.refresh(accounts['USD']);assert accounts['USD'].available_balance==1000

def test_same_currency_own_transfer_does_not_require_market_data(client,db_session,fx_data,monkeypatch):
    h,accounts,_=fx_data
    destination=db_session.scalar(select(Account).where(Account.customer_id==accounts['EGP'].customer_id,Account.currency=='EGP',Account.id!=accounts['EGP'].id,Account.status=='active'))
    body=draft(accounts,'EGP','USD');body['destination_account_id']=str(destination.id)
    monkeypatch.setattr(fx_service,'latest',lambda:(_ for _ in ()).throw(AssertionError('Same currency does not need FX')))
    q=review(client,h,body);assert 'fx_quote_id' not in q
    body['authorization_token']=authorize(client,h,body);assert execute(client,h,body).status_code==201

def test_genuine_own_fx_quote_cannot_be_attached_to_other_routes(client,db_session,fx_data):
    h,accounts,_=fx_data;body=draft(accounts,'EGP','USD');q=review(client,h,body)
    beneficiary=client.post(API+'/beneficiaries',headers=h,json={'name':'Fictional other customer','bank_name':'Same bank','account_number':'5550000000101','currency':'EGP'}).json()
    for kind in ['internal','external_domestic','international','wallet','instapay']:
        forged={'source_account_id':str(accounts['EGP'].id),'currency':'EGP','amount':'10.00','transfer_type':kind,'fx_quote_id':q['fx_quote_id']}
        if kind=='internal':forged['beneficiary_id']=beneficiary['id']
        else:
            forged['recipient']={'name':'Fictional recipient','destination':'01012345678' if kind in {'wallet','instapay'} else '001234567890'}
            if kind in {'external_domestic','international'}:forged['recipient']['bank_name']='Fictional bank'
            if kind=='international':forged['recipient'].update(country_code='US',swift_code='FAKEUS33XXX')
        assert client.post(API+'/transfers/quote',headers=h,json=forged).status_code==422
    assert db_session.get(OwnFxQuote,uuid.UUID(q['fx_quote_id'])).consumed_at is None

@pytest.mark.parametrize('same_key',[False,True])
def test_concurrent_fx_execution_and_single_use_snapshot(seeded_dataset,monkeypatch,same_key):
    from concurrent.futures import ThreadPoolExecutor
    from sqlalchemy.orm import Session
    from app.core.database import engine
    from tests.test_security_concurrency import _funded_test_customer
    ids,_,_=_funded_test_customer()
    now=utcnow().isoformat()
    monkeypatch.setattr(fx_service,'latest',lambda:{'source':'fictional-concurrency','stale':False,'quotes':[{'currency':'USD','buy':'50','sell':'50.5','stale':False,'updated_at':now}]})
    with Session(engine) as db:
        source,destination=db.get(Account,ids[1]),db.get(Account,ids[2]);source.current_balance=1000;source.available_balance=1000
        product=db.scalar(select(AccountProduct).where(AccountProduct.code=='AP-CURRENT-USD'))
        destination.currency='USD';destination.product_id=product.id;db.commit()
        user=db.get(User,ids[0]);body=TransferCreate(transfer_type='own_accounts',source_account_id=source.id,destination_account_id=destination.id,amount='10.00',currency='EGP')
        quote=transfer_execution.quote_transfer(db,user,body);body.fx_quote_id=uuid.UUID(quote['fx_quote_id'])
        binding=transfer_execution.authorization_binding(db,body)
        tokens=[security_service.issue_grant(db,user,'transfer',binding) for _ in range(2)];db.commit()
    def run(index):
        with Session(engine) as db:
            try:return transfer_execution.execute_transfer(db,db.get(User,ids[0]),draft=body.model_copy(update={'authorization_token':tokens[0] if same_key else tokens[index]}),idempotency_key='fx-race-same' if same_key else f'fx-race-{index}')
            except AppError as error:db.rollback();return error.code
    with ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(run,range(2)))
    if same_key:assert sorted(result[1] for result in results)==[False,True]
    else:assert sum(isinstance(result,tuple) for result in results)==1 and 'fx_quote_used' in results
    with Session(engine) as db:
        assert db.get(Account,ids[1]).available_balance==990 and db.get(Account,ids[2]).available_balance==Decimal('100.19')
