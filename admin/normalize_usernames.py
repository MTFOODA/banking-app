"""Normalize configured local usernames without changing credentials/banking rows."""
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'backend'))
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.database import Base
import app.models
from app.services.development_customers import normalize_existing_usernames
from export_demo_credentials import export_credentials


def snapshot(db):
    result = {}
    for name, table in Base.metadata.tables.items():
        columns = [c for c in table.c if not (name == 'users' and c.name in {'username', 'username_key', 'updated_at'})]
        result[name] = {
            tuple(str(row[c.name]) for c in table.primary_key):
            hashlib.sha256(json.dumps(dict(row), sort_keys=True, default=str).encode()).hexdigest()
            for row in db.execute(select(*columns)).mappings()
        }
    return result


def main():
    if settings.environment not in {'development', 'test'}:
        raise RuntimeError('Local username normalization refuses production')
    seen = set()
    for label, url in [('development', settings.database_url), ('phone', settings.test_database_url)]:
        if url in seen:
            continue
        seen.add(url)
        engine = create_engine(url)
        with Session(engine) as db:
            with db.begin():
                before = snapshot(db)
                changes = normalize_existing_usernames(db)
                after = snapshot(db)
                assert all(after[name].get(key) == value for name, rows in before.items()
                           for key, value in rows.items()), 'Protected existing data changed; rolled back'
            with db.begin():
                assert normalize_existing_usernames(db) == [], 'Not idempotent'
            print(f'{label}: {len(changes)} usernames normalized; existing credentials and banking records preserved.')
        engine.dispose()
    engine = create_engine(settings.test_database_url)
    with Session(engine) as db:
        count = export_credentials(db, ROOT / 'admin/admin.txt')
    engine.dispose()
    print(f'Private admin file refreshed for {count} identities. No passwords printed.')


if __name__ == '__main__':
    main()
