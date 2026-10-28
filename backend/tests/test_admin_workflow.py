from datetime import timedelta
import uuid
import pytest
from sqlalchemy import select, func
from app.core.security import hash_identifier, hash_password
from app.models.user import User, Role, AuditLog
from app.models.content import Announcement
from app.models.banking import Account
from app.models.service import ServiceRequest, Notification
from app.services.common import utcnow
from tests.test_security_flows import headers

API='/api/v1'

@pytest.fixture
def staff(client,db_session):
    from app.services.rbac import sync_roles
    sync_roles(db_session)
    role=db_session.scalar(select(Role).where(Role.code=='super_admin'))
    user=User(login_identifier_hash=hash_identifier('EMP-CONTENT-QA'),login_identifier_masked='EMP-***QA',
        login_type='staff',password_hash=hash_password('Fictional#ContentAdmin26'),must_change_password=False,
        enrollment_completed=True,is_active=True,roles=[role])
    db_session.add(user);db_session.commit()
    response=client.post(API+'/auth/login',json={'identifier':'EMP-CONTENT-QA','password':'Fictional#ContentAdmin26'})
    assert response.status_code==200
    return {'Authorization':'Bearer '+response.json()['access_token']}

def payload(**extra):
    return {'title_en':'Fictional bank update','title_ar':'تنبيه تجريبي من البنك','body_en':'Fictional service information for testing.',
        'body_ar':'معلومات خيالية لاختبار التنبيهات.','priority':'high','status':'published',**extra}

@pytest.mark.parametrize('location',['home','pre_login','both'])
def test_announcement_locations_and_public_payload(client,staff,location):
    created=client.post(API+'/admin/announcements',headers=staff,json=payload(display_location=location))
    assert created.status_code==201
    key=created.json()['id']
    public=client.get(API+'/public/announcements')
    assert public.status_code==200
    assert (key in [r['id'] for r in public.json()])==(location!='home')
    for row in public.json():
        assert not {'audiences','created_by','customer_id','cta_route'} & row.keys()
    home=client.get(API+'/announcements',headers=headers(client)).json()
    assert (key in [r['id'] for r in home])==(location!='pre_login')

@pytest.mark.parametrize('case',['draft','future','expired','scheduled_without_date','archived'])
def test_hidden_notices_are_not_public(client,staff,case):
    extra={'display_location':'pre_login'}
    if case=='draft':extra['status']='draft'
    if case=='future':extra['publish_at']=(utcnow()+timedelta(days=2)).isoformat()
    if case=='expired':extra['expires_at']=(utcnow()-timedelta(seconds=1)).isoformat()
    if case=='scheduled_without_date':extra['status']='scheduled'
    r=client.post(API+'/admin/announcements',headers=staff,json=payload(**extra));assert r.status_code==201
    if case=='archived':assert client.post(API+f"/admin/announcements/{r.json()['id']}/archive",headers=staff).status_code==200
    assert r.json()['id'] not in [row['id'] for row in client.get(API+'/public/announcements').json()]

def test_targeted_notices_never_leak_and_permissions_apply(client,staff):
    customer=headers(client)
    assert client.post(API+'/admin/announcements',headers=customer,json=payload()).status_code==403
    assert client.get(API+'/admin/requests',headers=customer).status_code==403
    assert client.post(API+'/admin/announcements',headers=staff,json=payload(display_location='pre_login',audience_type='customer_segment',audience_value='private')).status_code==422
    row=client.post(API+'/admin/announcements',headers=staff,json=payload(display_location='home',audience_type='customer_segment',audience_value='private')).json()
    endpoint=API+f"/admin/announcements/{row['id']}"
    assert client.patch(endpoint,headers=staff,json={'display_location':'both'}).status_code==422
    assert row['id'] not in [r['id'] for r in client.get(API+'/public/announcements').json()]
    assert client.patch(endpoint,headers=staff,json={'display_location':'both','audience_type':'all'}).status_code==200
    assert row['id'] in [r['id'] for r in client.get(API+'/public/announcements').json()]
    assert client.patch(endpoint,headers=staff,json={'display_location':None}).status_code==422

@pytest.fixture
def pending(db_session):
    user=db_session.scalar(select(User).where(User.login_identifier_hash==hash_identifier('4000000000000102')))
    row=ServiceRequest(customer_id=user.id,reference='REQ-ADMIN-'+uuid.uuid4().hex[:10],request_type='account_open',status='submitted',form_data={'product_code':'AP-CURRENT'})
    db_session.add(row);db_session.commit();return row

@pytest.mark.parametrize('reason',['','    ','abc','     x'])
def test_reject_requires_a_real_reason(client,staff,db_session,pending,reason):
    response=client.post(API+f'/admin/requests/{pending.id}/reject',headers=staff,json={'reason':reason})
    assert response.status_code==422
    db_session.refresh(pending);assert pending.status=='submitted'

def test_approval_applies_once_and_customer_cannot_decide(client,staff,db_session,pending):
    endpoint=API+f'/admin/requests/{pending.id}/approve'
    assert client.post(endpoint,headers=headers(client),json={}).status_code==403
    count=db_session.scalar(select(func.count()).select_from(Account))
    assert client.post(endpoint,headers=staff,json={}).status_code==200
    db_session.refresh(pending);assert pending.status=='completed'
    assert db_session.scalar(select(func.count()).select_from(Account))==count+1
    assert client.post(endpoint,headers=staff,json={}).status_code==409
    assert db_session.scalar(select(func.count()).select_from(Account))==count+1

def test_rejection_notifies_customer_and_audits(client,staff,db_session,pending):
    reason='Fictional documents are incomplete'
    response=client.post(API+f'/admin/requests/{pending.id}/reject',headers=staff,json={'reason':reason})
    assert response.status_code==200 and response.json()['status']=='rejected'
    db_session.refresh(pending)
    assert pending.decision_reason==pending.customer_explanation==reason
    assert db_session.scalar(select(Notification.id).where(Notification.customer_id==pending.customer_id,Notification.body_en.contains(reason)))
    assert db_session.scalar(select(AuditLog.id).where(AuditLog.action=='request.rejected',AuditLog.entity_id==str(pending.id)))
    assert client.post(API+f'/admin/requests/{pending.id}/approve',headers=staff,json={}).status_code==409
