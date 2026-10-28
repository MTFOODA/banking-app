"""Explicit local-only fictional branding QA server. Never resets existing data."""
from pathlib import Path
import sys,os,json,secrets
from sqlalchemy.engine import make_url
import psycopg
from psycopg import sql
root=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(root/'backend'),str(root/'database')]
from app.core.config import settings
if settings.is_production or os.environ.get('RUN_BRANDING_QA')!='1':
 raise RuntimeError('Local QA only: set RUN_BRANDING_QA=1 outside production')
source=make_url(settings.test_database_url)
if source.host not in {'localhost','127.0.0.1','::1'}:
 raise RuntimeError('Branding QA refuses a remote PostgreSQL host')
qa_name='faisal_branding_qa_test'
with psycopg.connect(source.set(drivername='postgresql',database='postgres').render_as_string(hide_password=False),autocommit=True) as connection:
 if not connection.execute('select 1 from pg_database where datname=%s',(qa_name,)).fetchone():
  connection.execute(sql.SQL('CREATE DATABASE {}').format(sql.Identifier(qa_name)))
settings.database_url=source.set(database=qa_name).render_as_string(hide_password=False)
settings.environment='test';settings.debug=False
settings.otp_provider='development';settings.otp_dev_expose=True
settings.outbound_transfer_provider='development'
settings.upload_dir=root/'.tmp/branding_qa_uploads'
from app.core.database import engine,Base,SessionLocal
import app.models
from sqlalchemy import select
from app.models.user import User,Role
from app.core.security import hash_identifier,hash_password,assess_password
from app.services.username_service import username_key
from app.services.rbac import sync_roles
from seed_demo_banking_data import seed_demo_banking
assert engine.url.database==qa_name
Base.metadata.create_all(engine)
credentials_file=root/'.tmp/branding_qa_credentials.local.json'
credentials_file.parent.mkdir(parents=True,exist_ok=True)
with SessionLocal() as db:
 seed_demo_banking(db)
 sync_roles(db)
 user=db.scalar(select(User).where(User.username_key==username_key('brandingqa')))
 if user is None:
  password='Qa7!'+secrets.token_urlsafe(24)
  while not assess_password(password).valid:password='Qa7!'+secrets.token_urlsafe(24)
  role=db.scalar(select(Role).where(Role.code=='super_admin'))
  user=User(username='brandingqa',username_key=username_key('brandingqa'),login_identifier_hash=hash_identifier('BRANDING-QA-ONLY'),
    login_identifier_masked='*** branding QA',login_type='staff',password_hash=hash_password(password),
    must_change_password=False,enrollment_completed=True,is_active=True,roles=[role])
  db.add(user);db.commit()
  credentials_file.write_text(json.dumps({'username':'brandingqa','password':password}),encoding='utf-8')
 elif not credentials_file.exists():raise RuntimeError('QA credentials unavailable; existing user preserved')
if __name__=='__main__':
 import uvicorn
 from app.main import app
 uvicorn.run(app,host='127.0.0.1',port=8017,log_level='warning',access_log=False)
