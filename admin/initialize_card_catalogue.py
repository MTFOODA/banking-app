"""Add missing fictional card/FX account products without touching banking rows."""
import os
from pathlib import Path
import sys

os.environ.setdefault('DEBUG', 'false')
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'backend'))
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from app.core.config import settings
from app.services.card_catalogue import seed_catalogue

def main():
    if settings.environment not in {'development', 'test'}:
        raise RuntimeError('This initializer is for local development only')
    for label, url in [('development', settings.database_url), ('phone', settings.test_database_url)]:
        engine = create_engine(url)
        with Session(engine) as db:
            added = seed_catalogue(db)
            db.commit()
        engine.dispose()
        print(label, 'missing catalogue rows added:', added, '(existing rows preserved)')

if __name__ == '__main__':
    main()
