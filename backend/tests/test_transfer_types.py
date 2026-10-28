from decimal import Decimal
import json,uuid
import pytest
from sqlalchemy import select,func
from app.core.config import settings
from app.models.banking import Account,AccountProduct
from app.models.transactions import Transaction,TransactionEntry
from app.models.security import AuthorizationGrant
from app.models.user import User
from app.services import transfer_execution,transfer_delivery,notification_service,security_service
from app.schemas.transaction import TransferCreate
from tests.test_security_flows import headers,draft_for

API='/api/v1'
CHANNELS=['external_domestic','international','wallet','instapay']

@pytest.fixture
def outbound(client,db_session,monkeypatch):
    monkeypatch.setattr(settings,'outbound_transfer_provider','development')
    monkeypatch.setattr(settings,'environment','test')
    h=headers(client);own=client.get(API+'/auth/me',headers=h).json()['id']
    base=draft_for(client,h)
    source=db_session.get(Account,uuid.UUID(base['source_account_id']))
    source.current_balance=Decimal('1000');source.available_balance=Decimal('1000')
    p=db_session.scalar(select(AccountProduct).where(AccountProduct.code=='AP-CURRENT-USD'))
    usd=Account(customer_id=uuid.UUID(own),product_id=p.id,account_number_hash=uuid.uuid4().hex*2,
        account_number_masked='**** QA USD',account_type='current',currency='USD',status='active',
        current_balance=1000,available_balance=1000,blocked_balance=0)
    db_session.add(usd);db_session.commit()
    return h,source,usd

def draft(channel,source):
    destination='001234567890'
    recipient={'name':'Fictional recipient','destination':destination,'bank_name':'Fictional domestic bank'}
    if channel=='international':recipient.update(bank_name='Fictional foreign bank',country_code='US',swift_code='FAKEUS33XXX')
    if channel=='wallet':recipient={'name':'Fictional wallet owner','destination':'+20 10 1234 5678'}
    if channel=='instapay':recipient={'name':'Fictional IPA owner','destination':'fictional.qa@instapay'}
    return {'transfer_type':channel,'source_account_id':str(source.id),'currency':source.currency,'amount':'10.00',
        'recipient':recipient,'purpose':'Fictional transfer type QA'}

def token(client,h,body):
    r=client.post(API+'/auth/authorize',headers=h,json={'scope':'transfer','current_password':'Salma#2026','transfer':body})
    assert r.status_code==200,r.text
    return r.json()['authorization_token']

def send(client,h,body,key=None):
    return client.post(API+'/transfers',headers={**h,'Idempotency-Key':key or uuid.uuid4().hex},json=body)

@pytest.mark.parametrize('channel',CHANNELS)
def test_outbound_simulation_debits_balances_ledger_receipt_and_safe_retry(client,db_session,outbound,channel):
    h,egp,usd=outbound;source=usd if channel=='international' else egp
    body=draft(channel,source)
    before=source.available_balance
    quote=client.post(API+'/transfers/quote',headers=h,json=body)
    assert quote.status_code==200 and quote.json()['delivery_mode']=='simulation'
    assert quote.json()['recipient_network_verified'] is False
    assert body['recipient']['destination'] not in quote.json()['destination_label']
    body['authorization_token']=token(client,h,body);key=uuid.uuid4().hex
    response=send(client,h,body,key);assert response.status_code==201,response.text
    result=response.json();assert result['status']=='simulated_completed' and result['is_simulated']
    assert result['transfer_type']==channel and result['provider_reference'].startswith('SIM-')
    db_session.refresh(source);assert source.available_balance==before-Decimal('10') and source.current_balance==source.available_balance
    debit=db_session.scalar(select(Transaction).where(Transaction.reference==result['reference']))
    assert debit.status=='posted' and debit.transfer_metadata['transfer_type']==channel
    assert debit.description_ar and 'external_domestic' not in debit.description
    assert debit.transfer_metadata['purpose']==body['purpose'] and result['purpose']==body['purpose']
    assert body['recipient']['destination'] not in json.dumps(debit.transfer_metadata)
    entries=db_session.scalars(select(TransactionEntry).where(TransactionEntry.transaction_id==debit.id)).all()
    assert len(entries)==2
    assert sum(e.amount if e.entry_type=='debit' else -e.amount for e in entries)==0
    assert any(e.account_id is None and e.ledger_bucket==channel+'_clearing' for e in entries)
    replay=send(client,h,body,key);assert replay.status_code==201 and replay.json()['reference']==result['reference']
    db_session.refresh(source);assert source.available_balance==before-Decimal('10')
    code=send(client,h,body).status_code
    assert code==409

def test_transfer_options_production_disabled_and_no_auth(client,outbound,monkeypatch):
    h,source,_=outbound
    assert client.get(API+'/transfers/options').status_code==401
    rows=client.get(API+'/transfers/options',headers=h).json()
    assert len(rows)==6 and all(r['available'] for r in rows)
    monkeypatch.setattr(settings,'environment','production')
    rows=transfer_execution.transfer_options()
    assert sum(r['available'] for r in rows)==2
    code=client.post('https://testserver'+API+'/transfers/quote',headers=h,json=draft('wallet',source)).status_code
    assert code==503
    monkeypatch.setattr(settings,'environment','test');monkeypatch.setattr(settings,'outbound_transfer_provider','disabled')
    assert client.post(API+'/transfers/quote',headers=h,json=draft('wallet',source)).status_code==503

@pytest.mark.parametrize('mutation',['amount','destination','channel','name','bank','purpose'])
def test_grant_binds_all_transfer_parameters(client,db_session,outbound,mutation):
    h,source,_=outbound;body=draft('external_domestic',source);body['authorization_token']=token(client,h,body)
    if mutation=='amount':body['amount']='11.00'
    if mutation=='destination':body['recipient']['destination']='009876543210'
    if mutation=='channel':body['transfer_type']='international';body['recipient'].update(country_code='US',swift_code='FAKEUS33XXX')
    if mutation=='name':body['recipient']['name']='Altered fictional name'
    if mutation=='bank':body['recipient']['bank_name']='Altered fictional bank'
    if mutation=='purpose':body['purpose']='Altered purpose'
    assert send(client,h,body).status_code==403
    db_session.refresh(source);assert source.available_balance==1000

@pytest.mark.parametrize('case',['bad_phone','bad_ipa','no_bank','bad_bic','country_mismatch','egypt_international','usd_wallet','mixed_destination','bad_iban'])
def test_invalid_routing_is_rejected_before_authorization(client,outbound,case):
    h,source,usd=outbound;body=draft('wallet',source)
    if case=='bad_phone':body['recipient']['destination']='01912345678'
    elif case=='bad_ipa':body['transfer_type']='instapay';body['recipient']['destination']='not-an-ipa@example.com'
    elif case=='no_bank':body=draft('external_domestic',source);body['recipient'].pop('bank_name')
    elif case in {'bad_bic','country_mismatch','egypt_international','bad_iban'}:
        body=draft('international',usd)
        if case=='bad_bic':body['recipient']['swift_code']='INVALID'
        if case=='country_mismatch':body['recipient']['country_code']='SA'
        if case=='egypt_international':body['recipient'].update(country_code='EG',swift_code='FAKEEG33XXX')
        if case=='bad_iban':body['recipient']['destination']='US0012345678912345678'
    elif case=='usd_wallet':body=draft('wallet',usd)
    elif case=='mixed_destination':body['destination_account_id']=str(uuid.uuid4())
    assert client.post(API+'/transfers/quote',headers=h,json=body).status_code==422

@pytest.mark.parametrize('case',['ownership','inactive','balance','currency','limit'])
def test_outbound_account_security(client,db_session,outbound,case):
    h,source,_=outbound;body=draft('external_domestic',source)
    if case=='ownership':body['source_account_id']=str(db_session.scalar(select(Account.id).where(Account.customer_id!=source.customer_id)))
    if case=='inactive':source.status='frozen'
    if case=='balance':body['amount']='1001.00'
    if case=='currency':body['currency']='USD';body['transfer_type']='international';body['recipient'].update(country_code='US',swift_code='FAKEUS33XXX')
    if case=='limit':body['amount']=str(settings.transfer_limit+1)
    db_session.commit()
    assert client.post(API+'/transfers/quote',headers=h,json=body).status_code in {404,409,422}

@pytest.mark.parametrize('failure',['provider','notification'])
def test_provider_or_commit_path_failure_rolls_back_grant_ledger_and_balance(client,db_session,outbound,monkeypatch,failure):
    h,source,_=outbound;body=draft('wallet',source);body['authorization_token']=token(client,h,body)
    count=db_session.scalar(select(func.count()).select_from(Transaction))
    if failure=='provider':
        monkeypatch.setattr(transfer_delivery.DevelopmentTransferProvider,'simulate',lambda *a:transfer_delivery.DeliveryReceipt('failed','FAILED-QA'))
        assert send(client,h,body).status_code==503
    else:
        monkeypatch.setattr(notification_service,'notify',lambda *a,**kw:(_ for _ in ()).throw(RuntimeError('Injected QA rollback')))
        with pytest.raises(RuntimeError,match='Injected QA rollback'):send(client,h,body)
    db_session.refresh(source);assert source.available_balance==1000
    assert db_session.scalar(select(func.count()).select_from(Transaction))==count
    grant=db_session.scalar(select(AuthorizationGrant).where(AuthorizationGrant.token_hash==security_service.hash_token(body['authorization_token'])))
    assert grant.consumed_at is None

def test_legacy_fingerprint_and_explicit_own_internal_routes(client,db_session,outbound):
    h,_,_=outbound;body=draft_for(client,h)
    legacy=TransferCreate(**body)
    old=legacy.model_dump(mode='json',exclude={'authorization_token','transfer_type','recipient','fx_quote_id'})
    old.update(amount=str(Decimal(legacy.amount).quantize(Decimal('0.01'))),currency=legacy.currency.upper(),fees='0.00')
    assert transfer_execution.transfer_fingerprint(legacy)==security_service.fingerprint(old)
    own={**body,'transfer_type':'own_accounts'}
    assert client.post(API+'/transfers/quote',headers=h,json=own).status_code==200
    saved=client.post(API+'/beneficiaries',headers=h,json={'name':'Fictional other customer','bank_name':'Same bank',
        'account_number':'5550000000101','currency':'EGP'}).json()
    internal={**body,'transfer_type':'internal','beneficiary_id':saved['id']};internal.pop('destination_account_id')
    assert client.post(API+'/transfers/quote',headers=h,json=internal).status_code==200
    own['beneficiary_id']=saved['id'];assert client.post(API+'/transfers/quote',headers=h,json=own).status_code==422

@pytest.mark.parametrize('case',['expired','wrong_scope','wrong_user'])
def test_outbound_rejects_expired_cross_scope_and_other_user_tokens(client,db_session,outbound,case):
    from datetime import timedelta
    from app.services.common import utcnow
    h,source,_=outbound;body=draft('wallet',source)
    user=db_session.get(User,source.customer_id)
    binding=transfer_execution.authorization_binding(db_session,TransferCreate(**body))
    owner=user
    if case=='wrong_user':owner=db_session.scalar(select(User).where(User.id!=user.id,User.login_type=='customer'))
    body['authorization_token']=security_service.issue_grant(db_session,owner,'password_change' if case=='wrong_scope' else 'transfer',binding)
    grant=db_session.scalar(select(AuthorizationGrant).where(AuthorizationGrant.token_hash==security_service.hash_token(body['authorization_token'])))
    if case=='expired':grant.expires_at=utcnow()-timedelta(seconds=1)
    db_session.commit()
    code=send(client,h,body).status_code;assert code==403
    db_session.refresh(source);assert source.available_balance==1000

def test_normalized_numbers_valid_ibans_and_mobile_ipa_alias(client,outbound):
    h,source,usd=outbound
    body=draft('external_domestic',source);body['recipient']['destination']='00 1234-567890'
    assert TransferCreate(**body).recipient.destination=='001234567890'
    bban='0'*21+'1234';check=98-int(bban+'141600')%97
    body['recipient']['destination']=f'EG{check:02}'+bban
    assert client.post(API+'/transfers/quote',headers=h,json=body).status_code==200
    body=draft('instapay',source);body['recipient']['destination']='01012345678'
    assert client.post(API+'/transfers/quote',headers=h,json=body).status_code==200

@pytest.mark.parametrize('same_key',[True,False])
def test_outbound_concurrency_and_balanced_clearing(seeded_dataset,monkeypatch,same_key):
    from concurrent.futures import ThreadPoolExecutor
    from sqlalchemy.orm import Session
    from app.core.database import engine
    from app.core.exceptions import AppError
    from tests.test_security_concurrency import _funded_test_customer
    monkeypatch.setattr(settings,'outbound_transfer_provider','development');monkeypatch.setattr(settings,'environment','test')
    ids,_,_=_funded_test_customer()
    with Session(engine) as db:
        source=db.get(Account,ids[1]);body=draft('wallet',source);body['amount']='80.00'
        payload=TransferCreate(**body);user=db.get(User,ids[0])
        binding=transfer_execution.authorization_binding(db,payload)
        tokens=[security_service.issue_grant(db,user,'transfer',binding) for _ in range(2)];db.commit()
    def run(index):
        with Session(engine) as db:
            try:return transfer_execution.execute_transfer(db,db.get(User,ids[0]),
                draft=payload.model_copy(update={'authorization_token':tokens[0] if same_key else tokens[index]}),
                idempotency_key='outbound-race-same' if same_key else f'outbound-race-{index}')
            except AppError as error:db.rollback();return error.code
    with ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(run,range(2)))
    if same_key:assert sorted(r[1] for r in results)==[False,True]
    else:assert sum(isinstance(r,tuple) for r in results)==1 and 'insufficient_funds' in results
    with Session(engine) as db:
        assert db.get(Account,ids[1]).available_balance==20
        tx=db.scalar(select(Transaction).where(Transaction.customer_id==ids[0]))
        entries=db.scalars(select(TransactionEntry).where(TransactionEntry.transaction_id==tx.id)).all()
        assert len(entries)==2 and sum(e.amount if e.entry_type=='debit' else -e.amount for e in entries)==0
