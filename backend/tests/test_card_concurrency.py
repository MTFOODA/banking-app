"""Independent sessions against the isolated CI database only."""
from concurrent.futures import ThreadPoolExecutor
import uuid
from sqlalchemy import select, func
from sqlalchemy.orm import Session
from app.core.database import engine
from app.core.exceptions import AppError
from app.core.security import hash_password
from app.models.user import User
from app.models.banking import Account, AccountProduct, Card
from app.models.service import ServiceRequest
from app.services import request_service

def fixture_data():
    assert (engine.url.database or '').endswith('_ci_test')
    with Session(engine) as db:
        users=[]
        for kind in ('customer','staff'):
            user=User(login_identifier_hash=uuid.uuid4().hex*2,login_identifier_masked='*** card QA',login_type=kind,
                password_hash=hash_password('Fictional#CardRace26'),must_change_password=False,enrollment_completed=True,is_active=True)
            db.add(user);users.append(user)
        db.flush()
        product=db.scalar(select(AccountProduct).where(AccountProduct.currency=='EGP'))
        account=Account(customer_id=users[0].id,product_id=product.id,account_number_hash=uuid.uuid4().hex*2,
            account_number_masked='*** race',account_type='current',currency='EGP',status='active',current_balance=100,available_balance=100,blocked_balance=0)
        db.add(account);db.flush();ids=users[0].id,users[1].id,account.id;db.commit()
        return ids

def test_concurrent_card_requests_are_serialized(seeded_dataset):
    customer,staff,account=fixture_data()
    def run(_):
        with Session(engine) as db:
            try:
                row=request_service.create_request(db,db.get(User,customer),request_type='card_issue',
                    form_data={'card_product_code':'CP-GOLD-DEBIT','account_id':str(account)})
                return row.id
            except AppError as e:
                db.rollback();return e.code
    with ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(run,range(2)))
    assert sum(isinstance(r,uuid.UUID) for r in results)==1 and 'duplicate_open_request' in results

def test_concurrent_card_approvals_issue_one_card(seeded_dataset):
    customer,staff,account=fixture_data()
    with Session(engine) as db:
        row=request_service.create_request(db,db.get(User,customer),request_type='card_issue',
            form_data={'card_product_code':'CP-GOLD-DEBIT','account_id':str(account)})
        identity=row.id
    def run(_):
        with Session(engine) as db:
            try:return request_service.approve_request(db,db.get(ServiceRequest,identity),actor=db.get(User,staff)).status
            except AppError as e:db.rollback();return e.code
    with ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(run,range(2)))
    assert sorted(results)==['completed','request_not_decidable']
    with Session(engine) as db:
        assert db.scalar(select(func.count()).select_from(Card).where(Card.customer_id==customer))==1
