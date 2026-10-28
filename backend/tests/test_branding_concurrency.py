"""Real independent PostgreSQL sessions; strictly isolated CI database only."""
from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
import uuid
from sqlalchemy import select, func, delete
from sqlalchemy.orm import Session
from app.core.database import engine
from app.core.exceptions import AppError
from app.models.branding import BrandingSettings, BrandingPublication
from app.models.user import User, AuditLog
from app.schemas.branding import BrandingConfig
from app.services import branding_service as service


def test_two_publishers_commit_one_version(seeded_dataset):
    assert (engine.url.database or '').endswith('_ci_test')
    with Session(engine) as db:
        actor=User(id=uuid.uuid4(),login_identifier_hash=uuid.uuid4().hex*2,
            login_identifier_masked='*** branding concurrency',login_type='staff',password_hash='unused-test-hash',
            must_change_password=False,enrollment_completed=True,is_active=True)
        db.add(actor);db.commit();actor_id=actor.id
        old=service.admin_config(db)
        saved=service.save_draft(db,actor,old['revision'],BrandingConfig(bank_overrides={'nbe': {'welcome_message':'Concurrent QA'}}))
        expected=saved['revision']
    barrier=Barrier(2)
    def run(_):
        with Session(engine) as db:
            user=db.get(User,actor_id)
            barrier.wait(timeout=10)
            try:return service.publish(db,user,expected)['configuration_version']
            except AppError as exc:db.rollback();return exc.code
    try:
        with ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(run,range(2)))
        assert results.count('branding_conflict')==1
        with Session(engine) as db:
            assert db.scalar(select(func.count()).select_from(BrandingPublication).where(BrandingPublication.version==expected+1))==1
            assert service.public_config(db)['configuration_version']==expected+1
    finally:
        # Restore only this test's own isolated configuration and actor records.
        with Session(engine) as db:
            row=db.get(BrandingSettings,1)
            row.active_version=old['configuration_version'] or None
            row.revision=old['revision'];row.draft=old['draft'];row.updated_by=None
            db.flush()
            db.execute(delete(BrandingPublication).where(BrandingPublication.published_by==actor_id))
            db.execute(delete(AuditLog).where(AuditLog.actor_id==actor_id))
            db.execute(delete(User).where(User.id==actor_id));db.commit()
