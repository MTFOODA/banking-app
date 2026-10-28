"""Explicit development setup for both configured local demo databases.

Run from project root with DEBUG=false. Preserve existing credentials and all
old banking rows; keep generated fictional passwords only in ignored files.
"""
import sys, json, secrets, hashlib
from pathlib import Path
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session
from sqlalchemy.engine import make_url
root = Path(__file__).resolve().parents[1]
(root / '.tmp').mkdir(exist_ok=True)
sys.path.insert(0, str(root / 'backend'))
from app.core.config import settings
from app.core.security import assess_password
from app.services.development_customers import provision_investor_fixtures, INVESTORS
from app.core.database import Base
import app.models

protected = ('users', 'customer_profiles', 'accounts', 'cards', 'transactions', 'transaction_entries',
             'beneficiaries', 'notifications', 'repayments', 'roles', 'permissions', 'user_roles', 'role_permissions',
             'customer_preferences')
def snapshot(engine):
    result = {}
    with engine.connect() as conn:
        for name in protected:
            table = Base.metadata.tables[name]
            columns = [c for c in table.c if not (name == 'users' and c.name in {'username', 'username_key', 'updated_at'})]
            result[name] = {str(row.get('id', json.dumps(dict(row), default=str, sort_keys=True))):
                hashlib.sha256(json.dumps(dict(row), default=str, sort_keys=True).encode()).hexdigest()
                for row in conn.execute(select(*columns)).mappings()}
    return result

private = root / 'admin/investor_credentials.local.json'
if private.exists():
    passwords = json.loads(private.read_text())
else:
    passwords = {}
    for suffix, *_ in INVESTORS:
        while True:
            value = 'Local#' + secrets.token_urlsafe(18) + '26'
            if assess_password(value).valid:
                passwords[suffix] = value
                break
    private.write_text(json.dumps(passwords, indent=2) + '\n')

states = {}
if not (make_url(settings.test_database_url).database or '').endswith('_test'):
    raise RuntimeError('The persistent handset database must have the _test suffix')
for label, url in [('development', settings.database_url), ('phone_test', settings.test_database_url)]:
    engine = create_engine(url)
    before = snapshot(engine)
    fixtures = provision_investor_fixtures(engine, passwords)
    after = snapshot(engine)
    assert all(after[name].get(key) == digest for name, rows in before.items() for key, digest in rows.items()), label + ': protected old data changed'
    assert provision_investor_fixtures(engine, passwords) == fixtures
    assert snapshot(engine) == after, label + ': non-idempotent seed'
    states[label] = {'preserved': True, 'old_counts': {name: len(rows) for name, rows in before.items()}}
    if label == 'phone_test':
        with Session(engine) as db:
            from export_demo_credentials import export_credentials
            export_credentials(db, root / 'admin/admin.txt')
    print(label + ': enrolled usernames assigned; two investors with six holdings; original records preserved; second run unchanged.')
    engine.dispose()
(root / '.tmp/phone_sample_preservation.json').write_text(json.dumps(states, indent=2))
print('Updated ignored admin/admin.txt; passwords were not printed.')
