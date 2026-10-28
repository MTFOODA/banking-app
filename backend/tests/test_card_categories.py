from datetime import date
from decimal import Decimal
import uuid

import pytest
from sqlalchemy import select, func

from app.models.banking import Account, AccountProduct, Card, CardProduct, CardLimit
from app.models.service import ServiceRequest
from app.models.user import User, AuditLog
from app.services import card_catalogue, notification_service
from app.services.common import utcnow
from app.core.security import hash_identifier
from tests.test_admin_workflow import staff
from tests.test_security_flows import headers

API='/api/v1'

@pytest.fixture
def customer(client, db_session):
    h=headers(client)
    user=db_session.scalar(select(User).where(User.login_identifier_hash==hash_identifier('4000000000000102')))
    user.profile.identity_verified=True
    today=utcnow().date()
    user.profile.date_of_birth=date(today.year-20,today.month,today.day)
    for currency in ['EGP','USD','EUR','SAR','GBP']:
        code='TEST-CARD-'+currency
        product=AccountProduct(code=code,name_en=code,name_ar=code,account_type='investment',currency=currency,
            description_en='Fictional',description_ar='Fictional',minimum_balance=0,is_active=True)
        db_session.add(product);db_session.flush()
        db_session.add(Account(customer_id=user.id,product_id=product.id,account_number_hash=uuid.uuid4().hex*2,
            account_number_masked='**** '+currency,account_type='investment',currency=currency,status='active',
            current_balance=Decimal('2000'),available_balance=Decimal('2000'),blocked_balance=0))
    db_session.commit()
    accounts={a.currency:a for a in db_session.scalars(select(Account).where(Account.customer_id==user.id,Account.account_number_masked.like('**** %')))}
    return h,user,accounts

def issue(client,h,code,account):
    return client.post(API+'/requests',headers=h,json={'request_type':'card_issue',
        'form_data':{'card_product_code':code,'account_id':str(account.id),'customer_id':str(uuid.uuid4()),'cardholder_name':'FORGED'}})

@pytest.mark.parametrize('code,variant,en,ar,network,investment,youth',card_catalogue.CARD_CATEGORIES)
def test_category_request_approval_issues_once(client,db_session,staff,customer,code,variant,en,ar,network,investment,youth):
    h,user,accounts=customer
    account=accounts['USD' if variant=='platinum_fx' else 'EGP']
    count=db_session.scalar(select(func.count()).select_from(Card))
    before=account.available_balance
    r=issue(client,h,code,account);assert r.status_code==201,r.text
    row=r.json();assert 'customer_id' not in row['form_data'] and 'cardholder_name' not in row['form_data']
    assert db_session.scalar(select(func.count()).select_from(Card))==count
    assert issue(client,h,code,account).status_code==409
    endpoint=API+f"/admin/requests/{row['id']}/approve"
    assert client.post(endpoint,headers=h,json={}).status_code==403
    approved=client.post(endpoint,headers=staff,json={});assert approved.status_code==200,approved.text
    assert approved.json()['status']=='completed'
    card=db_session.get(Card,uuid.UUID(approved.json()['form_data']['issued_card_id']))
    assert card.customer_id==user.id and card.account_id==account.id
    assert card.product.code==code and card.network==network
    assert card.status=='pending_activation' and card.cardholder_name!='FORGED'
    assert db_session.scalar(select(func.count()).select_from(CardLimit).where(CardLimit.card_id==card.id))==1
    audit=db_session.scalar(select(AuditLog).where(AuditLog.entity_id==str(card.id),AuditLog.action=='card.issued_on_approval'))
    assert audit and audit.actor_id!=user.id
    assert client.post(endpoint,headers=staff,json={}).status_code==409
    assert db_session.scalar(select(func.count()).select_from(Card))==count+1
    db_session.refresh(account);assert account.available_balance==before
    cards=client.get(API+'/cards',headers=h).json()['cards']
    assert any(c['product_code']==code and c['currency']==account.currency for c in cards)

def test_catalogue_accounts_privacy_and_supported_fx(client,db_session,customer):
    h,user,accounts=customer
    assert client.get(API+'/cards/products').status_code==401
    rows=client.get(API+'/cards/products',headers=h).json();assert len(rows)==6
    fx=next(r for r in rows if r['variant']=='platinum_fx')
    assert {a['currency'] for a in fx['accounts']}=={'USD','EUR','SAR'}
    owned={str(a.id) for a in db_session.scalars(select(Account).where(Account.customer_id==user.id))}
    assert all(a['id'] in owned for p in rows for a in p['accounts'])
    for r in rows:
        if r['investment_only']:assert all(a['account_type']=='investment' and a['currency']=='EGP' for a in r['accounts'])
    assert issue(client,h,'CP-PLATINUM-FX',accounts['GBP']).status_code==409
    assert issue(client,h,'CP-GOLD-DEBIT',accounts['USD']).status_code==409
    assert issue(client,h,'bad-product',accounts['EGP']).status_code==422
    other=db_session.scalar(select(Account).where(Account.customer_id!=user.id))
    assert issue(client,h,'CP-GOLD-DEBIT',other).status_code==404

@pytest.mark.parametrize('case',['21','unverified','missing','future','current','frozen','disabled'])
def test_youth_and_account_rules_are_server_enforced(client,db_session,customer,case):
    h,user,accounts=customer;account=accounts['EGP']
    today=utcnow().date()
    if case=='21':user.profile.date_of_birth=date(today.year-21,today.month,today.day)
    elif case=='unverified':user.profile.identity_verified=False
    elif case=='missing':user.profile.date_of_birth=None
    elif case=='future':user.profile.date_of_birth=date(today.year+1,1,1)
    elif case=='current':account.account_type='current'
    elif case=='frozen':account.status='frozen'
    elif case=='disabled':account.product.is_active=False
    db_session.commit()
    r=issue(client,h,'CP-YOUTH-DEBIT',account)
    assert r.status_code==409
    youth=next(r for r in client.get(API+'/cards/products',headers=h).json() if r['variant']=='youth')
    if case not in ['current','frozen','disabled']:assert not youth['eligible']

@pytest.mark.parametrize('change',['frozen','product','birthday'])
def test_approval_revalidates_and_rejection_never_issues(client,db_session,staff,customer,change):
    h,user,accounts=customer;account=accounts['EGP']
    row=issue(client,h,'CP-YOUTH-DEBIT',account).json()
    count=db_session.scalar(select(func.count()).select_from(Card))
    if change=='frozen':account.status='frozen'
    if change=='product':db_session.scalar(select(CardProduct).where(CardProduct.code=='CP-YOUTH-DEBIT')).is_active=False
    if change=='birthday':user.profile.date_of_birth=date(2000,1,1)
    db_session.commit()
    assert client.post(API+f"/admin/requests/{row['id']}/approve",headers=staff,json={}).status_code==409
    db_session.refresh(db_session.get(ServiceRequest,uuid.UUID(row['id'])))
    assert client.post(API+f"/admin/requests/{row['id']}/reject",headers=staff,json={'reason':'Eligibility changed before issue'}).status_code==200
    assert db_session.scalar(select(func.count()).select_from(Card))==count

def test_approval_rollback_no_partial_card_or_limits(client,db_session,staff,customer,monkeypatch):
    h,user,accounts=customer;row=issue(client,h,'CP-MEEZA-DEBIT',accounts['EGP']).json()
    count=db_session.scalar(select(func.count()).select_from(Card))
    monkeypatch.setattr(notification_service,'notify',lambda *a,**kw: (_ for _ in ()).throw(RuntimeError('Injected QA failure')))
    with pytest.raises(RuntimeError,match='Injected QA failure'):
        client.post(API+f"/admin/requests/{row['id']}/approve",headers=staff,json={})
    assert db_session.scalar(select(func.count()).select_from(Card))==count
    assert db_session.get(ServiceRequest,uuid.UUID(row['id'])).status=='submitted'

def test_catalogue_seed_is_additive_idempotent_and_rollback_safe(db_session,monkeypatch):
    assert card_catalogue.seed_catalogue(db_session)==0
    product=db_session.scalar(select(CardProduct).where(CardProduct.code=='CP-GOLD-DEBIT'))
    product.name_en='Existing bank-configured name';db_session.flush()
    assert card_catalogue.seed_catalogue(db_session)==0 and product.name_en=='Existing bank-configured name'
    extra=('CP-ROLLBACK-QA','gold','Rollback QA','اختبار','Visa',False,False)
    monkeypatch.setattr(card_catalogue,'CARD_CATEGORIES',(*card_catalogue.CARD_CATEGORIES,extra))
    with pytest.raises(RuntimeError,match='Rollback catalogue'):
        with db_session.begin_nested():
            assert card_catalogue.seed_catalogue(db_session)==1
            raise RuntimeError('Rollback catalogue')
    assert db_session.scalar(select(CardProduct).where(CardProduct.code=='CP-ROLLBACK-QA')) is None
