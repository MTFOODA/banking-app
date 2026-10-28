"""Explicit atomic, idempotent fresh self-registration fixtures on demo API 8011."""
import argparse
import hashlib
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'backend'))
os.environ['DEBUG'] = 'false'
from sqlalchemy import create_engine, select
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.database import Base
import app.models
from app.services.registration_demo import provision_registration_batch
from export_demo_credentials import export_credentials


def snapshot(engine):
    names = ('users', 'customer_profiles', 'accounts', 'cards', 'transactions', 'transaction_entries',
             'beneficiaries', 'notifications', 'repayments', 'roles', 'permissions', 'user_roles', 'role_permissions')
    with engine.connect() as connection:
        return {name: {hashlib.sha256(json.dumps(dict(row), sort_keys=True, default=str).encode()).hexdigest()
                       for row in connection.execute(select(Base.metadata.tables[name])).mappings()} for name in names}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--batch', required=True, help='Alphanumeric idempotency label; use a new label for a new set.')
    parser.add_argument('--count', type=int, default=4)
    args = parser.parse_args()
    if settings.environment not in {'development', 'test'} or not (make_url(settings.test_database_url).database or '').endswith('_test'):
        raise RuntimeError('Only the configured local persistent demo test database is allowed')
    engine = create_engine(settings.test_database_url)
    before = snapshot(engine)
    with Session(engine) as db, db.begin():
        rows = provision_registration_batch(db, args.batch, args.count)
    after = snapshot(engine)
    assert all(hashes <= after[name] for name, hashes in before.items()), 'Existing banking data changed'
    with Session(engine) as db, db.begin():
        assert provision_registration_batch(db, args.batch, args.count) == rows
    assert snapshot(engine) == after, 'Non-idempotent registration seed'
    with Session(engine) as db:
        export_credentials(db, ROOT / 'admin/admin.txt', additional_identifiers=[r['card'] for r in rows])
    exported = (ROOT / 'admin/admin.txt').read_text(encoding='utf-8')
    blocks = re.split(r'\n\s*\n', exported)
    fresh = [next(block for block in blocks if 'Card: ' + row['card'] in block) for row in rows]
    (ROOT / 'admin/NEW_REGISTRATION_USERS.txt').write_text(
        'SELF-REGISTRATION BATCH ' + args.batch + '\nUse demo API 8011; choose username/password after OTP.\n\n' +
        '\n\n'.join(fresh) + '\n\nCommands: admin/RUN_COMMANDS.txt\n', encoding='utf-8')
    result = {'batch': args.batch, 'customers': len(rows), 'ready_for_registration': sum(not r['enrollment_completed'] for r in rows),
              'previous_rows_preserved': True, 'second_run_unchanged': True}
    (ROOT / '.tmp').mkdir(exist_ok=True)
    (ROOT / '.tmp/registration_batch_result.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result))
    print('Updated ignored admin/admin.txt; usernames and passwords are chosen after OTP. No credentials printed.')
    engine.dispose()


if __name__ == '__main__':
    main()
