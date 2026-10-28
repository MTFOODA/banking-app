"""Local administration CLI (no hardcoded credentials).

Usage (from the backend directory, venv active):

    python -m app.cli sync-roles
    python -m app.cli bootstrap-admin
    python -m app.cli issue-reset-token --card-number 4508123456789012
    python -m app.cli verify

The demo administrator is provisioned from DEMO_ADMIN_EMPLOYEE_NUMBER and
DEMO_ADMIN_INITIAL_PASSWORD in the environment; the initial password must be
changed at first sign-in.
"""

from __future__ import annotations

import argparse
import getpass
import os
import sys

from sqlalchemy import select, text

from app.core.config import settings
from app.core.database import SessionLocal, engine
from app.core.security import assess_password, hash_identifier, hash_password
from app.models.roles import DEFAULT_STAFF_ROLE
from app.models.user import CustomerPreference, Role, User
from app.services import auth_service
from app.services.password_service import issue_reset_token
from app.services.rbac import sync_roles


def _mask_employee(employee_number: str) -> str:
    return f"{employee_number[:3]}****{employee_number[-2:]}"


def bootstrap_admin(employee_number: str | None, password: str | None, name: str) -> int:
    employee = (employee_number or settings.demo_admin_employee_number).strip()
    initial_password = password or settings.demo_admin_initial_password
    if not employee or not initial_password:
        print(
            "Set DEMO_ADMIN_EMPLOYEE_NUMBER and DEMO_ADMIN_INITIAL_PASSWORD "
            "(or pass --employee-number/--password) before bootstrapping."
        )
        return 2
    if len(initial_password) < 12 or not assess_password(initial_password).valid:
        print("Refusing to provision an administrator with a weak initial password.")
        return 2

    with SessionLocal() as db:
        existing = db.scalar(
            select(User).where(User.login_identifier_hash == hash_identifier(employee))
        )
        if existing is not None:
            if existing.login_type != "staff" or DEFAULT_STAFF_ROLE not in existing.role_codes:
                print("Identifier already exists without administrator access; no changes made.")
                return 2
            print("Administrator already exists; password and permissions preserved.")
            return 0
        sync_roles(db)
        role = db.scalar(select(Role).where(Role.code == DEFAULT_STAFF_ROLE))

        user = User(
            login_identifier_hash=hash_identifier(employee),
            login_identifier_masked=_mask_employee(employee),
            login_type="staff",
            password_hash=hash_password(initial_password),
            must_change_password=True,
            is_active=True,
            roles=[role] if role else [],
        )
        db.add(user)
        db.flush()
        db.add(CustomerPreference(user_id=user.id, language="en", theme="system"))
        db.commit()
        print(
            f"Provisioned administrator {employee}. Sign in with the initial password "
            "and complete the mandatory password setup."
        )
    return 0


def issue_token(card_number: str) -> int:
    with SessionLocal() as db:
        user = db.scalar(
            select(User).where(User.login_identifier_hash == hash_identifier(card_number))
        )
        if user is None:
            print("No user found for that identifier.")
            return 1
        token = issue_reset_token(db, user=user)
        print("One-time password reset code (valid 30 minutes, shown once):")
        print(token)
    return 0


def verify() -> int:
    with engine.connect() as connection:
        version = connection.execute(text("SELECT version()")).scalar()
    with SessionLocal() as db:
        count = db.scalar(text("SELECT count(*) FROM users"))  # type: ignore[arg-type]
    print("Database:", version)
    print("Users:", count)
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Faisal App backend CLI")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("sync-roles", help="Create or refresh roles and permissions")

    admin_parser = sub.add_parser("bootstrap-admin", help="Provision the demo administrator")
    admin_parser.add_argument("--employee-number", default=None)
    admin_parser.add_argument("--password", default=None)
    admin_parser.add_argument("--name", default=settings.demo_admin_name)

    token_parser = sub.add_parser(
        "issue-reset-token", help="Issue a one-time password reset code for a user"
    )
    token_parser.add_argument("--card-number", required=True)

    sub.add_parser("verify", help="Verify database connectivity")
    sub.add_parser("seed-registration-demo", help="Add one fictional, unenrolled development customer; preserve existing records")
    sub.add_parser('seed-investments', help='Add fictional certificates and investment funds without changing existing products')
    sub.add_parser('assign-demo-usernames', help='Assign usernames to enrolled development identities; preserve credentials and unenrolled customers')
    sub.add_parser('normalize-demo-usernames', help='Remove username symbols in development; preserve credentials and ownership')

    args = parser.parse_args(argv)

    if args.command == "sync-roles":
        with SessionLocal() as db:
            print(sync_roles(db))
        return 0
    if args.command == "bootstrap-admin":
        password = args.password or settings.demo_admin_initial_password
        if not password:
            password = getpass.getpass("Temporary development administrator password: ")
        return bootstrap_admin(args.employee_number, password, args.name)
    if args.command == "issue-reset-token":
        return issue_token(args.card_number)
    if args.command == "verify":
        return verify()
    if args.command == "seed-registration-demo":
        from app.services.registration_demo import seed_registration_demo
        with SessionLocal() as db:
            print("Fictional registration fixture created." if seed_registration_demo(db) else "Fixture already exists; no credentials or records changed.")
        return 0
    if args.command == 'seed-investments':
        from app.services.investment_service import seed_products
        with SessionLocal() as db:
            print('New simulated investment products:', seed_products(db))
        return 0
    if args.command == 'assign-demo-usernames':
        from app.services.development_customers import assign_enrolled_usernames
        with SessionLocal() as db:
            print('Enrolled identities assigned usernames:', assign_enrolled_usernames(db))
            db.commit()
        return 0
    if args.command == 'normalize-demo-usernames':
        from app.services.development_customers import normalize_existing_usernames
        with SessionLocal() as db:
            print('Usernames normalized:', len(normalize_existing_usernames(db)))
            db.commit()
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
