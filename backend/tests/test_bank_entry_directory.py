"""Bank-aware entry, public directory isolation, and notice audience regressions."""
import hashlib
import re
from pathlib import Path

import pytest
from sqlalchemy import select

from app.core.security import hash_identifier
from app.models.user import User
from app.services.bank_catalogue_data import catalogue
from app.services.bank_directory import public_directory
from app.services.username_service import username_key
from tests.test_admin_workflow import staff, payload
from tests.test_auth_and_ownership import READY_USERS
from tests.test_security_flows import headers

API = '/api/v1'


@pytest.mark.parametrize('code', [b['code'] for b in catalogue()['banks']])
def test_public_directory_isolated_and_conditional(client, code):
    response = client.get(f'{API}/banks/{code}/directory')
    assert response.status_code == 200
    data = response.json()
    assert data['bank_code'] == code
    assert data['version'] and response.headers['etag']
    for kind in ('branches', 'atms'):
        assert len({x['id'] for x in data[kind]}) == len(data[kind])
        if code != 'faisal':
            assert all(x['id'].startswith(code + '-') for x in data[kind])
    same = client.get(f'{API}/banks/{code}/directory', params={'known_version': data['version']}).json()
    assert same == {'bank_code': code, 'version': data['version'], 'unchanged': True}
    assert not {'customer_id', 'account_id', 'balance', 'password'} & data.keys()


def test_directory_unknown_and_faisal_corrections_preserved(client):
    assert client.get(API + '/banks/unknown/directory').status_code == 404
    rows = public_directory('faisal')['branches']
    assert len(rows) == 44
    assert 'الجيزة' in rows[1]['name']
    assert 'التحرير' in rows[1]['address']
    assert len(public_directory('faisal')['atms']) >= 300
    assert len(public_directory('banque_misr')['branches']) >= 700
    assert len(public_directory('banque_misr')['atms']) >= 4000


def test_every_bank_has_reviewed_official_compiled_artwork_and_arabic_name():
    import json
    root = Path(__file__).resolve().parents[2]
    manifest = json.loads((root / 'backend/app/data/bank_public_assets.json').read_text(encoding='utf-8'))
    for bank in catalogue()['banks']:
        item = manifest[bank['code']]
        asset = root / 'frontend/faisal_app' / bank['logo_asset']
        assert asset.is_file() and item['source_url'].startswith('https://')
        assert hashlib.sha256(asset.read_bytes()).hexdigest() == item['sha256']
        assert bank['abbreviation']
        assert not re.search('[A-Za-z]', bank['name_ar'])


def test_official_svg_css_keeps_colors_and_geometry_for_flutter():
    import importlib.util
    from xml.etree import ElementTree as ET
    script = Path(__file__).resolve().parents[2] / 'scripts/sync_bank_public_assets.py'
    spec = importlib.util.spec_from_file_location('bank_artwork_tools', script)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    source = b'<svg xmlns="http://www.w3.org/2000/svg"><style>.bank{fill:#21376b;}.hidden{display:none;}</style><path class="bank" d="M0 0L10 10"/><g class="hidden"/></svg>'
    result = module.inline_svg_styles(source)
    root = ET.fromstring(result)
    path, group = list(root)
    assert path.attrib['fill'] == '#21376b' and path.attrib['d'] == 'M0 0L10 10'
    assert group.attrib['display'] == 'none'
    assert module.inline_svg_styles(result) == result


@pytest.mark.parametrize('identifier', ['4000000000000102', '5550000000102', 'user.name', 'user_name', 'user-name', '1user'])
def test_username_only_contract_rejects_cards_accounts_and_symbols(client, identifier):
    response = client.post(API + '/auth/login', json={'identifier': identifier, 'password': 'Salma#2026', 'identifier_type': 'username', 'bank_code': 'faisal'})
    assert response.status_code == 422


def test_username_login_uses_existing_user_bank_and_password(client, db_session):
    row = db_session.scalar(select(User).where(User.login_identifier_hash == hash_identifier(READY_USERS[1]['card'])))
    row.username = 'entrycustomer'; row.username_key = username_key(row.username)
    db_session.flush()
    body = {'identifier': 'ENTRYCUSTOMER', 'password': READY_USERS[1]['password'], 'identifier_type': 'username', 'bank_code': 'faisal'}
    response = client.post(API + '/auth/login', json=body)
    assert response.status_code == 200
    assert response.json()['user']['id'] == str(row.id)
    assert response.json()['user']['profile']['bank_code'] == 'faisal'
    assert client.post(API + '/auth/login', json={**body, 'bank_code': 'cib'}).status_code == 401
    assert client.post(API + '/auth/login', json={**body, 'password': 'Incorrect#2026'}).status_code == 401
    # Existing clients still use the exact same authentication and first-login policy.
    legacy = client.post(API + '/auth/login', json={'identifier': READY_USERS[1]['card'], 'password': READY_USERS[1]['password']})
    assert legacy.status_code == 200 and legacy.json()['user']['id'] == str(row.id)


def test_public_bank_notices_do_not_leak_to_other_banks(client, staff):
    created = client.post(API + '/admin/announcements', headers=staff,
        json=payload(display_location='both', audience_type='bank', audience_value='cib'))
    assert created.status_code == 201, created.text
    key = created.json()['id']
    def visible(**query):
        return {x['id'] for x in client.get(API + '/public/announcements', params=query).json()}
    assert key in visible(bank_code='cib')
    assert key not in visible(bank_code='nbe') and key not in visible()
    # Authenticated users are scoped by the server profile, never a query string.
    customer = headers(client)
    assert key not in {x['id'] for x in client.get(API + '/announcements?bank_code=cib', headers=customer).json()}
    assert client.get(API + f'/announcements/{key}', headers=customer).status_code == 404
    assert client.post(API + '/admin/announcements', headers=customer, json=payload()).status_code == 403
    invalid = client.post(API + '/admin/announcements', headers=staff,
        json=payload(display_location='pre_login', audience_type='bank', audience_value='unknown'))
    assert invalid.status_code == 422
