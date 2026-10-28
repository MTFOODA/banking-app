"""Explicit additive migrations for the existing local demo; never resets data."""
import os
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'backend'))
os.environ['DEBUG']='false'
from app.core.config import settings
from sqlalchemy import create_engine,inspect
from sqlalchemy.engine import make_url
from alembic import command
from alembic.config import Config

def main():
    target=make_url(settings.test_database_url)
    if settings.is_production or target.host not in {'localhost','127.0.0.1','::1'} or not (target.database or '').endswith('_test'):
        raise RuntimeError('This command only migrates the configured local demo *_test database')
    engine=create_engine(settings.test_database_url)
    tables=set(inspect(engine).get_table_names())
    engine.dispose()
    if 'users' in tables and 'alembic_version' not in tables:
        raise RuntimeError('Unversioned existing schema: preserve it and reconcile migration history explicitly; refusing to stamp or reset it')
    settings.database_url=settings.test_database_url
    config=Config(str(ROOT/'backend/alembic.ini'))
    config.set_main_option('script_location',str(ROOT/'backend/alembic'))
    command.upgrade(config,'head')
    print('Local demo migrations are at head. Existing data was not reset.')

if __name__=='__main__':main()
