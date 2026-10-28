"""Bank selection is server-owned; appearance cannot change the compiled identity."""
import pytest
from datetime import timedelta
from sqlalchemy import select
from app.models.bank import Bank
from app.models.security import OtpChallenge
from app.services.common import utcnow
from app.schemas.branding import BrandingConfig, current_policy_config, contrast
from app.services.registration_demo import provision_registration_batch
from tests.test_branding import staff, draft, publish, API
from tests.test_security_flows import enrollment, start, verify
from tests.test_auth_and_ownership import NADA


def test_public_catalogue_conditional_and_accessible(client):
    response=client.get(API+'/banks')
    assert response.status_code==200
    payload=response.json()
    assert len(payload['banks'])==37
    assert len({b['code'] for b in payload['banks']})==37
    assert client.get(API+'/banks',params={'known_version':payload['version']}).json()['unchanged']
    for bank in payload['banks']:
        assert bank['website'].startswith('https://') and bank['name_ar']
        for mode in ('light','dark'):
            colors=bank[mode]
            assert all(contrast(colors[a],colors[b])>=4.5 for a in ('primary','error','text_primary','text_secondary') for b in ('background','surface','card'))


@pytest.mark.parametrize('bank_code',['nbe','cib','banque_misr'])
def test_bank_card_registration_and_session(client,db_session,enrollment,bank_code):
    user,codes=enrollment
    user.profile.bank_code=bank_code
    db_session.flush()
    wrong=client.post(API+'/auth/registration/start',json={'identifier':NADA['card'],'bank_code':'faisal','identifier_type':'card'})
    assert wrong.status_code==200 and not codes
    for challenge in db_session.scalars(select(OtpChallenge)).all():
        challenge.sent_at=utcnow()-timedelta(minutes=2)
    db_session.flush()
    result=client.post(API+'/auth/registration/start',json={'identifier':NADA['card'],'bank_code':bank_code,'identifier_type':'card'})
    assert result.status_code==200 and len(codes)==1
    grant=verify(client,result.json()['challenge'],codes[0]['code']).json()['authorization_token']
    completed=client.post(API+'/auth/registration/complete',json={'authorization_token':grant,'username':'bankcustomer','new_password':'New#Bank2026','confirm_password':'New#Bank2026'})
    assert completed.status_code==200,completed.text
    assert completed.json()['user']['profile']['bank_code']==bank_code
    wrong_login=client.post(API+'/auth/login',json={'identifier':'bankcustomer','password':'New#Bank2026','bank_code':'faisal'})
    assert wrong_login.status_code==401
    logged=client.post(API+'/auth/login',json={'identifier':'bankcustomer','password':'New#Bank2026','bank_code':bank_code})
    assert logged.status_code==200,logged.text
    assert logged.json()['user']['profile']['bank_code']==bank_code
    automatic=client.post(API+'/auth/login',json={'identifier':'bankcustomer','password':'New#Bank2026'})
    assert automatic.status_code==200 and automatic.json()['user']['profile']['bank_code']==bank_code


@pytest.mark.parametrize('code',['unknown','citi','standard_chartered'])
def test_unavailable_bank_rejected(client,code):
    assert client.post(API+'/auth/registration/start',json={'identifier':NADA['card'],'bank_code':code}).status_code==422


def test_card_only_rejects_account_but_legacy_keeps_account_flow(client,enrollment,db_session):
    user,codes=enrollment
    response=client.post(API+'/auth/registration/start',json={'identifier':'5550000000110','bank_code':'faisal','identifier_type':'card'})
    assert response.status_code==200 and not codes
    for challenge in db_session.scalars(select(OtpChallenge)).all():
        challenge.sent_at=utcnow()-timedelta(minutes=2)
    db_session.flush()
    assert start(client,'5550000000110').status_code==200 and len(codes)==1


def test_disabled_bank_and_affiliation_cannot_be_client_assigned(client,db_session):
    bank=db_session.get(Bank,'nbe');bank.is_active=False;db_session.flush()
    metadata=client.get(API+'/banks').json()['banks']
    assert next(row for row in metadata if row['code']=='nbe')['registration_enabled'] is False
    assert client.post(API+'/auth/registration/start',json={'identifier':NADA['card'],'bank_code':'nbe'}).status_code==422
    from tests.test_security_flows import headers
    assert client.patch(API+'/profile',headers=headers(client),json={'bank_code':'nbe'}).status_code == 422


def test_per_bank_draft_publish_restore_isolated(client,staff):
    overrides={'nbe':{'welcome_message':'NBE customers','english_font':'NotoSans'},'cib':{'welcome_message':'CIB customers'}}
    saved=draft(client,staff,bank_overrides=overrides)
    assert saved.status_code==200,saved.text
    assert client.get(API+'/branding').json()['config']['bank_overrides']=={}
    first=publish(client,staff,saved.json()['revision']).json()
    assert first['config']['bank_overrides']['nbe']['welcome_message']=='NBE customers'
    reset=client.post(API+'/admin/branding/defaults',headers=staff,json={'expected_revision':first['revision'],'bank_code':'nbe'})
    assert reset.status_code==200
    current=publish(client,staff,reset.json()['revision']).json()
    assert current['config']['bank_overrides']['nbe']['welcome_message'] is None
    assert current['config']['bank_overrides']['cib']['welcome_message']=='CIB customers'
    old=client.post(API+f"/admin/branding/history/{first['configuration_version']}/restore",headers=staff,json={'expected_revision':current['revision'],'bank_code':'nbe'})
    restored=publish(client,staff,old.json()['revision']).json()
    assert restored['config']['bank_overrides']['nbe']['welcome_message']=='NBE customers'
    assert restored['config']['application_name'] is None


def test_old_publications_cannot_resurrect_old_identity():
    old=BrandingConfig().model_dump();old.update(application_name='Old name',logo_url='/branding/assets/'+'a'*64+'.png',custom_theme=True)
    safe=current_policy_config(old)
    assert safe.application_name is None and safe.logo_url is None and not safe.custom_theme


def test_selected_bank_preserves_mandatory_legacy_first_login(client):
    wrong=client.post(API+'/auth/login',json={'identifier':NADA['card'],'password':NADA['password'],'bank_code':'nbe'})
    assert wrong.status_code==401
    response=client.post(API+'/auth/login',json={'identifier':NADA['card'],'password':NADA['password'],'bank_code':'faisal'})
    assert response.status_code==200
    assert response.json()['status']=='password_setup_required'
    assert response.json()['setup_token'] and not response.json().get('access_token')


def test_bank_fixture_idempotency_and_no_reassignment(db_session):
    first=provision_registration_batch(db_session,'BankNBE',2,bank_code='nbe')
    second=provision_registration_batch(db_session,'BankNBE',2,bank_code='nbe')
    assert first==second and all(r['bank_code']=='nbe' for r in first)
    with pytest.raises(RuntimeError,match='refusing to reassign'):
        provision_registration_batch(db_session,'BankNBE',2,bank_code='cib')


def test_internal_transfer_cannot_cross_bank_boundary(client,db_session):
    from tests.test_security_flows import headers,draft_for,authorize
    from app.models.banking import Account
    from app.models.user import User
    from app.core.security import hash_identifier
    h=headers(client)
    body=draft_for(client,h)
    receiver_account=db_session.scalar(select(Account).where(Account.account_number_hash==hash_identifier('acct:5550000000101')))
    receiver=db_session.get(User,receiver_account.customer_id)
    receiver.profile.bank_code='nbe'
    source=db_session.get(Account,body['source_account_id'])
    before=source.available_balance
    db_session.flush()
    saved=client.post(API+'/beneficiaries',headers=h,json={'name':'Fictional NBE recipient','bank_name':'NBE','account_number':'5550000000101','currency':'EGP'})
    assert saved.status_code==201,saved.text
    body.pop('destination_account_id')
    body.update(transfer_type='internal',beneficiary_id=saved.json()['id'])
    assert client.post(API+'/transfers/quote',headers=h,json=body).status_code==422
    assert authorize(client,h,'transfer',draft=body).status_code==422
    db_session.refresh(source)
    assert source.available_balance==before
