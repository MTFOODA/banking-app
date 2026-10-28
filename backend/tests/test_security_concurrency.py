"""Real independent PostgreSQL sessions; never use a development database."""
from concurrent.futures import ThreadPoolExecutor
from decimal import Decimal
import uuid

import pytest
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import engine
from app.core.exceptions import AppError
from app.core.security import hash_password, hash_token
from app.models.banking import Account, AccountProduct
from app.models.security import AuthorizationGrant
from app.models.user import User
from app.schemas.transaction import TransferCreate
from app.services import security_service, transfer_execution
from app.services import registration_service


def _funded_test_customer():
    # Committed fixtures are necessary for cross-connection visibility. They live
    # solely in the guarded *_test database, whose schema fixture removes them.
    assert engine.url.database.endswith("_test")
    with Session(engine, expire_on_commit=False) as db:
        user = User(login_identifier_hash=uuid.uuid4().hex + uuid.uuid4().hex, login_identifier_masked="*** concurrency",
            password_hash=hash_password("Concurrency#2026"), must_change_password=False, enrollment_completed=True,
            login_type="customer", is_active=True)
        db.add(user)
        db.flush()
        product = db.scalar(select(AccountProduct))
        accounts = [Account(customer_id=user.id, product_id=product.id, account_number_hash=uuid.uuid4().hex + uuid.uuid4().hex,
            account_number_masked=f"*** race {i}", account_type="current", currency="EGP", status="active",
            current_balance=100, available_balance=100, blocked_balance=0) for i in range(2)]
        db.add_all(accounts)
        db.flush()
        draft = TransferCreate(source_account_id=accounts[0].id, destination_account_id=accounts[1].id, amount=Decimal("80.00"), currency="EGP")
        tokens = [security_service.issue_grant(db, user, "transfer", transfer_execution.authorization_binding(db, draft)) for _ in range(2)]
        ids = user.id, accounts[0].id, accounts[1].id
        db.commit()
    return ids, draft, tokens


@pytest.mark.parametrize("same_key", [True, False])
def test_concurrent_submissions_never_double_debit(seeded_dataset, same_key):
    ids, draft, tokens = _funded_test_customer()
    def run(i):
        with Session(engine, expire_on_commit=False) as db:
            user = db.get(User, ids[0])
            payload = draft.model_copy(update={"authorization_token": tokens[0] if same_key else tokens[i]})
            try:
                return transfer_execution.execute_transfer(db, user, draft=payload,
                    idempotency_key="concurrency-same" if same_key else f"concurrency-different-{i}")
            except AppError as exc:
                db.rollback()
                return exc.code
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(run, (0, 1)))
    with Session(engine) as db:
        assert db.get(Account, ids[1]).available_balance == Decimal("20.00")
        assert db.get(Account, ids[2]).available_balance == Decimal("180.00")
    if same_key:
        assert results[0][0]["reference"] == results[1][0]["reference"]
        assert sorted(r[1] for r in results) == [False, True]
    else:
        assert sum(isinstance(r, tuple) for r in results) == 1
        assert "insufficient_funds" in results


def test_concurrent_enrollment_consumes_grant_once(seeded_dataset):
    ids, draft, _ = _funded_test_customer()
    with Session(engine) as db:
        user = db.get(User, ids[0])
        user.enrollment_completed = False
        token = security_service.issue_grant(db, user, "registration")
        db.commit()
    def run(i):
        with Session(engine, expire_on_commit=False) as db:
            try:
                user, issued = registration_service.complete(db, token, "Enrolled#2026", "Enrolled#2026", {"ip_address": f"race-{i}"}, username='race'+ids[0].hex[:20])
                return "enrolled"
            except AppError as exc:
                db.rollback()
                return exc.code
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(run, (0, 1)))
    assert results.count("enrolled") == 1


def test_different_customers_racing_same_username_only_one_enrolls(seeded_dataset):
    from app.services import username_service
    customers=[_funded_test_customer()[0][0] for _ in range(2)]
    chosen='unique'+uuid.uuid4().hex[:20]
    tokens=[]
    with Session(engine) as db:
        for identifier in customers:
            user=db.get(User,identifier)
            user.enrollment_completed=False
            tokens.append(security_service.issue_grant(db,user,'registration'))
        db.commit()
    def run(i):
        with Session(engine) as db:
            try:
                registration_service.complete(db,tokens[i],'Concurrent#2026','Concurrent#2026',{'ip_address':str(i)},username=chosen)
                return 'enrolled'
            except AppError as exc:
                db.rollback()
                return exc.code
    with ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(run,(0,1)))
    assert sorted(results)==['enrolled','username_taken']
    with Session(engine) as db:
        loser=results.index('username_taken')
        user=db.get(User,customers[loser])
        assert not user.enrollment_completed and user.username is None
        grant=db.scalar(select(AuthorizationGrant).where(AuthorizationGrant.token_hash==hash_token(tokens[loser])))
        assert grant.consumed_at is None


def test_concurrent_investment_subscriptions_and_redemptions(seeded_dataset):
    from app.services import investment_service
    from app.schemas.investment import InvestmentAction,InvestmentExecute
    from app.models.content import BankingProduct
    from app.models.investment import InvestmentHolding
    ids,_,_=_funded_test_customer()
    with Session(engine) as db:
        investment_service.seed_products(db)
        account=db.get(Account,ids[1]);account.current_balance=account.available_balance=Decimal('1500')
        db.flush()
        product=db.scalar(select(BankingProduct).where(BankingProduct.code=='INV-DEMO-3Y'))
        action=InvestmentAction(action='subscribe',product_id=product.id,account_id=account.id,amount=Decimal('1000'))
        user=db.get(User,ids[0])
        binding=investment_service.quote(db,user,action)['binding']
        tokens=[security_service.issue_grant(db,user,'investment_subscribe',binding) for _ in range(2)]
        db.commit()
    def run(i,request,grants):
        with Session(engine) as db:
            try:
                return investment_service.execute(db,db.get(User,ids[0]),
                    InvestmentExecute(**request.model_dump(),authorization_token=grants[i]),str(uuid.uuid4()))
            except AppError as exc:
                db.rollback();return exc.code
    with ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(lambda i:run(i,action,tokens),(0,1)))
    assert sum(isinstance(r,dict) for r in results)==1 and 'insufficient_funds' in results
    receipt=next(r for r in results if isinstance(r,dict))
    with Session(engine) as db:
        assert db.get(Account,ids[1]).current_balance==Decimal('500')
        request=InvestmentAction(action='redeem',holding_id=uuid.UUID(receipt['holding_id']))
        user=db.get(User,ids[0]);binding=investment_service.quote(db,user,request)['binding']
        grants=[security_service.issue_grant(db,user,'investment_redeem',binding) for _ in range(2)]
        db.commit()
    with ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(lambda i:run(i,request,grants),(0,1)))
    assert sum(isinstance(r,dict) for r in results)==1 and 'investment_redeemed' in results
    with Session(engine) as db:
        assert db.get(Account,ids[1]).current_balance==Decimal('1450')
