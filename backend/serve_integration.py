"""Run the API exclusively against the configured isolated *_test database.

INTEGRATION_DATABASE_URL may select a dedicated *_test device database.
Unit tests use a separate *_ci_test database. Never drops tables or deletes data.
"""
import sys
import os
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "database"))
from app.core.config import settings

settings.database_url = os.environ.get('INTEGRATION_DATABASE_URL') or settings.test_database_url
settings.environment = "test"
settings.debug = False
settings.otp_provider = "development"
settings.otp_dev_expose = True
settings.outbound_transfer_provider = 'development'

from app.core.database import Base, engine, SessionLocal
import app.models
from seed_demo_banking_data import seed_demo_banking
from app.services.registration_demo import seed_registration_demo
from app.services.investment_service import seed_products
from app.services.development_customers import assign_enrolled_usernames

if not (engine.url.database or "").endswith("_test"):
    raise RuntimeError("Integration server refuses a database without the _test suffix")

if __name__ == "__main__":
    Base.metadata.create_all(engine)
    with SessionLocal() as db:
        seed_demo_banking(db)
        seed_registration_demo(db)
        seed_products(db)
        assign_enrolled_usernames(db)
        db.commit()
    import uvicorn
    from app.main import app
    port = int(os.environ.get('INTEGRATION_PORT', '8011'))
    if not 1024 <= port <= 65535:
        raise RuntimeError('Invalid integration server port')
    uvicorn.run(app, host="127.0.0.1", port=port, log_level="warning", access_log=False)
