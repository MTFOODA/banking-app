"""Idempotent demo seed for Faisal App.

Apply migrations first, then run:

    cd backend
    .venv\\Scripts\\python.exe ..\\database\\seed_demo.py

Demo credentials (demo-only, never production):
    Customer 1  card 4508 1234 5678 9012   temporary credential 1002003004001
    Customer 2  card 4508 9876 5432 1098   temporary credential 1002003004002

The first successful sign-in forces a password change for each demo customer.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
for extra in (REPO_ROOT / "backend", REPO_ROOT / "database"):
    if str(extra) not in sys.path:
        sys.path.insert(0, str(extra))

from sqlalchemy import inspect  # noqa: E402

from app.core.database import SessionLocal, engine  # noqa: E402
from app.services.rbac import sync_roles  # noqa: E402
from demo_activity import seed_activity  # noqa: E402
from demo_announcements import seed_announcements  # noqa: E402
from demo_common import DEMO_CARD_1, DEMO_CARD_2, DEMO_TEMP_1, DEMO_TEMP_2  # noqa: E402
from demo_customers import seed_customers  # noqa: E402
from demo_notifications import seed_notifications, seed_support  # noqa: E402
from demo_offers import seed_products_and_offers  # noqa: E402
from demo_products import seed_products  # noqa: E402
from demo_requests import seed_requests  # noqa: E402
from demo_reset import reset_demo  # noqa: E402


def run(reset: bool, confirmed: bool) -> int:
    tables = set(inspect(engine).get_table_names())
    if "users" not in tables:
        print("Schema not found. Run `alembic upgrade head` from ./backend first.")
        return 1

    with SessionLocal() as db:
        if reset:
            if not confirmed:
                print("Refusing to delete demo data without --yes.")
                return 2
            removed = reset_demo(db)
            print(f"Removed demo customers: {removed}")

        roles = sync_roles(db)
        print(
            f"Roles ready: {roles['roles_total']} "
            f"(created {roles['roles_created']}), permissions {roles['permissions_total']}"
        )
        products = seed_products(db)
        seed_announcements(db)
        seed_products_and_offers(db)

        data = seed_customers(db, products)
        if data is None:
            print("Demo customers already exist; skipping transactional seed data.")
        else:
            seed_activity(db, data)
            seed_requests(db, data)
            seed_notifications(db, data)
            seed_support(db, data)
            print("Demo customers, accounts, cards, transactions and requests created.")

    print("\nDemo sign-in (password setup is mandatory on first login):")
    print(f"  Card number : {DEMO_CARD_1}")
    print(f"  Temp code   : {DEMO_TEMP_1}  (account number used as temporary credential)")
    print(f"  Card number : {DEMO_CARD_2}")
    print(f"  Temp code   : {DEMO_TEMP_2}")
    print("  New password must satisfy the full bank password policy.")
    print("\nProvision the demo administrator with: python -m app.cli bootstrap-admin")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Seed Faisal App demo data")
    parser.add_argument(
        "--reset",
        action="store_true",
        help="Delete existing demo customers before seeding (requires --yes)",
    )
    parser.add_argument("--yes", action="store_true", help="Confirm destructive reset")
    args = parser.parse_args(argv)
    return run(reset=args.reset, confirmed=args.yes)


if __name__ == "__main__":
    sys.exit(main())
