"""End-to-end security regressions against the isolated PostgreSQL test database."""
from datetime import timedelta
from decimal import Decimal
import uuid

import pytest
from sqlalchemy import func, select

from app.core.config import settings
from app.core.security import hash_identifier, hash_token, verify_password
from app.models.banking import Account, AccountProduct, Beneficiary, Card
from app.models.security import AuthorizationGrant, OtpChallenge
from app.models.service import ServiceRequest
from app.models.transactions import Transaction, TransactionEntry
from app.models.user import AuditLog, User
from app.services import registration_service
from app.services.common import utcnow
from tests.test_auth_and_ownership import NADA, READY_USERS, login, token_for

API = "/api/v1"


@pytest.fixture
def enrollment(db_session, monkeypatch):
    user = db_session.scalar(select(User).where(User.login_identifier_hash == hash_identifier(NADA["card"])))
    user.enrollment_completed = False
    db_session.flush()
    codes = []
    class CaptureProvider:
        def send(self, **kwargs):
            codes.append(kwargs)
    monkeypatch.setattr(registration_service, "get_otp_provider", lambda: CaptureProvider())
    return user, codes


def start(client, identifier=NADA["card"]):
    return client.post(f"{API}/auth/registration/start", json={"identifier": identifier})


def verify(client, challenge, code):
    return client.post(f"{API}/auth/registration/verify", json={"challenge": challenge, "code": code})


def headers(client, user=READY_USERS[1]):
    return {"Authorization": f"Bearer {token_for(client, user)}"}


def authorize(client, h, scope, password="Salma#2026", draft=None):
    data = {"scope": scope, "current_password": password}
    if draft:
        data["transfer"] = draft
    return client.post(f"{API}/auth/authorize", headers=h, json=data)


def draft_for(client, h):
    accounts = client.get(f"{API}/accounts", headers=h).json()["accounts"]
    return {"source_account_id": accounts[0]["id"], "destination_account_id": accounts[1]["id"],
            "amount": "12.34", "currency": "EGP", "purpose": "Fictional test", "note": "Security test"}


def submit(client, h, draft, key="security-test-001"):
    return client.post(f"{API}/transfers", headers={**h, "Idempotency-Key": key}, json=draft)


@pytest.mark.parametrize("identifier", ["4000-0000-0000-0109", "5550 0000 00110"])
def test_registration_complete_and_login(client, db_session, enrollment, identifier):
    user, codes = enrollment
    counts = [db_session.scalar(select(func.count()).select_from(model)) for model in (User, Account, Card, Transaction)]
    response = start(client, identifier)
    assert response.status_code == 200, response.text
    challenge = response.json()["challenge"]
    assert "development_code" not in response.json()
    assert codes[-1]["email"] == user.profile.email
    row = db_session.scalar(select(OtpChallenge).where(OtpChallenge.reference_hash == hash_token(challenge)))
    assert row.otp_hash != codes[-1]["code"]
    token = verify(client, challenge, codes[-1]["code"]).json()["authorization_token"]
    assert verify(client, challenge, codes[-1]["code"]).status_code == 409
    data = {"authorization_token": token, "username": "nadaregistration", "new_password": "New#Nada2026", "confirm_password": "New#Nada2026"}
    completed = client.post(f"{API}/auth/registration/complete", json=data)
    assert completed.status_code == 200, completed.text
    assert completed.json()["status"] == "authenticated"
    assert completed.json()["user"]["must_change_password"] is False
    assert client.get(f"{API}/accounts", headers={"Authorization": f"Bearer {completed.json()['access_token']}"}).status_code == 200
    assert login(client, identifier, "New#Nada2026").status_code == 200
    assert login(client, identifier, NADA["password"]).status_code == 401
    assert client.post(f"{API}/auth/registration/complete", json=data).status_code in (403, 409)
    assert counts == [db_session.scalar(select(func.count()).select_from(model)) for model in (User, Account, Card, Transaction)]


@pytest.mark.parametrize("identifier", ["x" * 16, "123", "4000/0000/0000/0109", "4000000000000109!", "0000000000000000000000000"])
def test_registration_invalid_format(client, identifier):
    assert start(client, identifier).status_code == 422


def test_leading_zero_normalization():
    assert registration_service.normalize_registration_identifier("000-001 234.567") == "000001234567"


@pytest.mark.parametrize("identifier", ["4999999999999999", READY_USERS[0]["card"], NADA["card"]])
def test_unknown_and_legacy_enrolled_identical_response(client, identifier):
    response = start(client, identifier)
    assert response.status_code == 200
    assert response.json()["contact_masked"] == "*** registered contact"
    assert verify(client, response.json()["challenge"], "123456").status_code == 400


def test_registration_rejects_untrusted_customer_id(client):
    assert client.post(f"{API}/auth/registration/start", json={"identifier": NADA["card"], "customer_id": str(uuid.uuid4())}).status_code == 422


@pytest.mark.parametrize("state", ["locked", "inactive", "account_inactive", "card_inactive", "ambiguous", "unverified"])
def test_ineligible_registration(client, db_session, enrollment, state):
    user, codes = enrollment
    if state == "locked": user.is_locked = True
    if state == "inactive": user.is_active = False
    if state == "unverified": user.profile.identity_verified = False
    if state == "card_inactive":
        db_session.scalar(select(Card).where(Card.card_number_hash == hash_identifier(NADA["card"]))).status = "blocked"
    if state == "account_inactive":
        for account in db_session.scalars(select(Account).where(Account.customer_id == user.id)).all():
            account.status = "closed"
    if state == "ambiguous":
        other = db_session.scalar(select(User).where(User.login_identifier_hash == hash_identifier(READY_USERS[0]["card"])))
        product = db_session.scalar(select(AccountProduct))
        db_session.add(Account(customer_id=other.id, product_id=product.id, account_number_hash=hash_identifier(f"acct:{NADA['card']}"),
            account_number_masked="***0109", account_type="current", currency="EGP", status="active", current_balance=0, available_balance=0, blocked_balance=0))
    db_session.flush()
    assert start(client).status_code == 200
    assert codes == []


def test_otp_delivery_failure(client, monkeypatch, enrollment):
    class Failing:
        def send(self, **kwargs): raise RuntimeError("secret provider detail")
    monkeypatch.setattr(registration_service, "get_otp_provider", lambda: Failing())
    response = start(client)
    assert response.status_code == 200
    assert "secret" not in response.text
    assert verify(client, response.json()["challenge"], "123456").status_code == 400


def test_otp_cooldown_resend_expiry_attempt_limit(client, db_session, enrollment):
    user, codes = enrollment
    challenge = start(client).json()["challenge"]
    old_code = codes[-1]["code"]
    assert start(client).status_code == 429
    assert client.post(f"{API}/auth/registration/resend", json={"challenge": challenge}).status_code == 429
    row = db_session.scalar(select(OtpChallenge).where(OtpChallenge.reference_hash == hash_token(challenge)))
    row.sent_at = utcnow() - timedelta(seconds=settings.otp_resend_seconds + 1)
    row.expires_at = utcnow() - timedelta(seconds=1)
    db_session.flush()
    assert verify(client, challenge, old_code).json()["error"]["code"] == "otp_expired"
    assert client.post(f"{API}/auth/registration/resend", json={"challenge": challenge}).status_code == 200
    for _ in range(settings.otp_max_attempts):
        wrong = "000000" if codes[-1]["code"] != "000000" else "111111"
        assert verify(client, challenge, wrong).status_code == 400
    assert verify(client, challenge, codes[-1]["code"]).status_code == 429


def test_new_challenge_invalidates_old(client, db_session, enrollment):
    user, codes = enrollment
    old = start(client).json()["challenge"]
    row = db_session.scalar(select(OtpChallenge).where(OtpChallenge.reference_hash == hash_token(old)))
    row.sent_at = utcnow() - timedelta(seconds=65)
    db_session.flush()
    newer = start(client, "5550000000110")
    assert newer.status_code == 200
    assert verify(client, old, codes[0]["code"]).status_code == 409


def test_resend_never_reissues_the_previous_code(client, db_session, enrollment, monkeypatch):
    _, codes = enrollment
    values = iter([123456, 123456, 654321])
    monkeypatch.setattr(registration_service.secrets, "randbelow", lambda _: next(values))
    challenge = start(client).json()["challenge"]
    row = db_session.scalar(select(OtpChallenge).where(OtpChallenge.reference_hash == hash_token(challenge)))
    row.sent_at = utcnow() - timedelta(seconds=65)
    db_session.commit()
    assert client.post(API+"/auth/registration/resend", json={"challenge": challenge}).status_code == 200
    assert codes[0]["code"] != codes[1]["code"]
    assert verify(client, challenge, codes[0]["code"]).status_code == 400


def test_unauthorized_sensitive_endpoints(client):
    for path, data in [("/auth/authorize", {"scope": "password_change", "current_password": "x"}),
                       ("/auth/change-password", {"authorization_token": "x"*30, "current_password": "x", "new_password": "New#Password26", "confirm_password": "New#Password26"})]:
        assert client.post(API+path, json=data).status_code == 401
    assert client.get(API+"/profile").status_code == 401


def test_incorrect_reauthentication_locks_existing_session(client, db_session):
    h = headers(client)
    for _ in range(settings.max_failed_login_attempts):
        assert authorize(client, h, "password_change", "wrong").status_code == 400
    assert client.get(API+"/profile", headers=h).status_code == 401


@pytest.mark.parametrize("failure", ["expired", "scope", "user", "amount", "purpose", "destination"])
def test_transfer_token_binding(client, db_session, failure):
    h = headers(client)
    draft = draft_for(client, h)
    issued = authorize(client, h, "transfer" if failure != "scope" else "password_change", draft=draft)
    assert issued.status_code == 200, issued.text
    token = issued.json()["authorization_token"]
    if failure == "expired":
        row = db_session.scalar(select(AuthorizationGrant).where(AuthorizationGrant.token_hash == hash_token(token)))
        row.expires_at = utcnow() - timedelta(seconds=1)
        db_session.flush()
    if failure == "amount": draft["amount"] = "13.34"
    if failure == "purpose": draft["purpose"] = "Altered"
    if failure == "destination": draft["destination_account_id"] = str(uuid.uuid4())
    if failure == "user": h = headers(client, READY_USERS[2])
    assert submit(client, h, {**draft, "authorization_token": token}).status_code == 403


def test_transfer_receipt_balanced_ledger_idempotency_and_replay(client, db_session):
    h = headers(client)
    draft = draft_for(client, h)
    quote = client.post(API+"/transfers/quote", headers=h, json=draft)
    assert quote.status_code == 200
    assert quote.json()["fees"] == "0.00"
    source = db_session.get(Account, uuid.UUID(draft["source_account_id"]))
    before = source.available_balance
    draft["authorization_token"] = authorize(client, h, "transfer", draft=draft).json()["authorization_token"]
    result = submit(client, h, draft)
    assert result.status_code == 201, result.text
    assert result.json()["status"] == "posted"
    assert result.json()["created_at"]
    replay = submit(client, h, draft)
    assert replay.json()["reference"] == result.json()["reference"]
    db_session.refresh(source)
    assert source.available_balance == before - Decimal("12.34")
    assert submit(client, h, draft, "security-test-002").status_code == 409
    assert submit(client, h, {**draft, "amount": "20.00"}).status_code == 409
    txns = db_session.scalars(select(Transaction).where(Transaction.journal_id == uuid.UUID(result.json()["journal_id"]))).all()
    assert len(txns) == 2
    assert sum(t.amount * (1 if t.direction == "credit" else -1) for t in txns) == 0
    entries = db_session.scalars(select(TransactionEntry).where(TransactionEntry.transaction_id.in_([t.id for t in txns]))).all()
    assert len(entries) == 2


@pytest.mark.parametrize("failure", ["missing_token", "ownership", "balance", "zero", "negative", "precision", "limit"])
def test_transfer_validation(client, failure):
    h = headers(client)
    draft = draft_for(client, h)
    if failure == "missing_token":
        assert submit(client, h, draft).status_code == 403
        return
    if failure == "ownership": draft["source_account_id"] = str(uuid.uuid4())
    if failure == "balance": draft["amount"] = "99000.00"
    if failure == "zero": draft["amount"] = "0"
    if failure == "negative": draft["amount"] = "-5"
    if failure == "precision": draft["amount"] = "1.001"
    if failure == "limit": draft["amount"] = "100001.00"
    assert client.post(API+"/transfers/quote", headers=h, json=draft).status_code in (404, 409, 422)


def test_transfer_rollback_preserves_grant(client, db_session, monkeypatch):
    from app.services import transfer_execution
    h = headers(client)
    draft = draft_for(client, h)
    draft["authorization_token"] = authorize(client, h, "transfer", draft=draft).json()["authorization_token"]
    before = db_session.get(Account, uuid.UUID(draft["source_account_id"])).available_balance
    original = transfer_execution.notification_service.notify
    monkeypatch.setattr(transfer_execution.notification_service, "notify", lambda *a, **k: (_ for _ in ()).throw(RuntimeError("Injected rollback")))
    with pytest.raises(RuntimeError): submit(client, h, draft)
    db_session.rollback()
    assert db_session.get(Account, uuid.UUID(draft["source_account_id"])).available_balance == before
    monkeypatch.setattr(transfer_execution.notification_service, "notify", original)
    assert submit(client, h, draft).status_code == 201


def test_profile_update_pending_and_audited(client, db_session):
    h = headers(client)
    assert client.get(API+"/preferences", headers=h).status_code == 200
    assert client.get(API+"/profile/sessions", headers=h).status_code == 200
    profile = client.get(API+"/profile", headers=h).json()["profile"]
    assert "***" in profile["email"] and "***" in profile["customer_number"]
    assert client.patch(API+"/profile", headers=h, json={"email": "new@example.test"}).status_code == 422
    token = authorize(client, h, "profile_update").json()["authorization_token"]
    response = client.patch(API+"/profile", headers=h, json={"authorization_token": token, "email": "new@example.com", "address": "Fictional Address 10"})
    assert response.status_code == 200, response.text
    assert response.json()["status"] == "pending_review"
    assert client.get(API+"/profile", headers=h).json()["profile"]["email"] == profile["email"]
    assert db_session.scalar(select(AuditLog).where(AuditLog.action == "profile.update_requested"))
    assert client.patch(API+"/profile", headers=h, json={"authorization_token": token, "address": "Fictional Address 11"}).status_code == 409
    assert client.patch(API+"/profile", headers=h, json={"authorization_token": token, "first_name_en": "Imposter"}).status_code == 422


def test_password_change_scope_reauth_and_session_revocation(client, db_session):
    h = headers(client)
    token = authorize(client, h, "password_change").json()["authorization_token"]
    data = {"authorization_token": token, "current_password": "wrong", "new_password": "New#Salma2026", "confirm_password": "New#Salma2026"}
    assert client.post(API+"/auth/change-password", headers=h, json=data).status_code == 400
    data["current_password"] = "Salma#2026"
    response = client.post(API+"/auth/change-password", headers=h, json=data)
    assert response.status_code == 200, response.text
    assert client.get(API+"/profile", headers=h).status_code == 401
    assert login(client, READY_USERS[1]["card"], "New#Salma2026").status_code == 200
    assert login(client, READY_USERS[1]["card"], "Salma#2026").status_code == 401


def test_admin_bootstrap_role_enforcement_and_preservation(client, db_session, monkeypatch):
    from contextlib import contextmanager
    from app import cli
    @contextmanager
    def session(): yield db_session
    monkeypatch.setattr(cli, "SessionLocal", session)
    assert cli.bootstrap_admin("EMP-SECURITY-01", "Temporary#Admin2026", "Test Admin") == 0
    staff = db_session.scalar(select(User).where(User.login_identifier_hash == hash_identifier("EMP-SECURITY-01")))
    original = staff.password_hash
    assert cli.bootstrap_admin("EMP-SECURITY-01", "Different#Admin2026", "Test Admin") == 0
    assert staff.password_hash == original
    assert cli.bootstrap_admin(READY_USERS[0]["card"], "Temporary#Admin2026", "Test Admin") == 2
    restricted = login(client, "EMP-SECURITY-01", "Temporary#Admin2026").json()
    assert restricted["status"] == "password_setup_required"
    complete = client.post(API+"/auth/first-login/complete", headers={"Authorization": "Bearer "+restricted["setup_token"]},
        json={"new_password": "Permanent#Admin2026", "confirm_password": "Permanent#Admin2026"})
    assert complete.status_code == 200, complete.text
    admin_h = {"Authorization": "Bearer "+complete.json()["access_token"]}
    assert client.get(API+"/admin/dashboard", headers=admin_h).status_code == 200
    assert client.get(API+"/admin/dashboard", headers=headers(client)).status_code == 403


def test_registration_grant_expiry_does_not_enroll(client, db_session, enrollment):
    user, codes = enrollment
    challenge = start(client).json()["challenge"]
    token = verify(client, challenge, codes[-1]["code"]).json()["authorization_token"]
    grant = db_session.scalar(select(AuthorizationGrant).where(AuthorizationGrant.token_hash == hash_token(token)))
    grant.expires_at = utcnow() - timedelta(seconds=1)
    db_session.commit()
    response = client.post(API+"/auth/registration/complete", json={"authorization_token": token,
        "username": "nadaexpired", "new_password": "New#Nada2026", "confirm_password": "New#Nada2026"})
    assert response.status_code == 403
    db_session.refresh(user)
    assert user.enrollment_completed is False


def test_registration_shared_rate_limit(client):
    from app.services.security_service import throttle
    for i in range(4): assert start(client, "4999999999999999").status_code in (200, 429)
    assert start(client, "4999999999999999").status_code == 429


def test_transfer_token_cannot_change_password(client):
    h = headers(client)
    draft = draft_for(client, h)
    token = authorize(client, h, "transfer", draft=draft).json()["authorization_token"]
    assert client.post(API+"/auth/change-password", headers=h, json={"authorization_token": token,
        "current_password": "Salma#2026", "new_password": "New#Salma2026", "confirm_password": "New#Salma2026"}).status_code == 403


def test_profile_request_cannot_bypass_step_up(client):
    h = headers(client)
    response = client.post(API+"/requests", headers=h, json={"request_type": "customer_info_update", "form_data": {"address": "Fictional Address 10"}})
    assert response.status_code == 403


def test_beneficiary_destination_and_ownership_validation(client, db_session):
    h = headers(client)
    draft = draft_for(client, h)
    saved = client.post(API+"/beneficiaries", headers=h, json={"name": "Fictional Youssef", "bank_name": "Internal Demo Bank",
        "account_number": READY_USERS[0]["account"], "currency": "EGP"})
    assert saved.status_code == 201, saved.text
    draft.pop("destination_account_id")
    draft["beneficiary_id"] = saved.json()["id"]
    token = authorize(client, h, "transfer", draft=draft).json()["authorization_token"]
    result = submit(client, h, {**draft, "authorization_token": token})
    assert result.status_code == 201, result.text
    credit = db_session.scalar(select(Transaction).where(Transaction.journal_id == uuid.UUID(result.json()["journal_id"]), Transaction.direction == "credit"))
    receiver = db_session.scalar(select(User).where(User.login_identifier_hash == hash_identifier(READY_USERS[0]["card"])))
    assert credit.customer_id == receiver.id
    assert authorize(client, headers(client, READY_USERS[2]), "transfer", password="Omar#2026", draft=draft).status_code == 404


def test_unsupported_external_beneficiary_never_debits(client, db_session):
    h = headers(client)
    draft = draft_for(client, h)
    external = Beneficiary(customer_id=uuid.UUID(client.get(API+"/auth/me", headers=h).json()["id"]), name="External fixture",
        bank_name="External Demo", account_number_masked="***9999", currency="EGP", status="active")
    db_session.add(external)
    db_session.commit()
    draft.pop("destination_account_id")
    draft["beneficiary_id"] = str(external.id)
    assert client.post(API+"/transfers/quote", headers=h, json=draft).json()["error"]["code"] == "destination_unsupported"


def test_profile_bank_approval_applies_only_validated_contact_fields(client, db_session):
    from app.services.request_effects import apply_approval_effects
    h = headers(client)
    token = authorize(client, h, "profile_update").json()["authorization_token"]
    response = client.patch(API+"/profile", headers=h, json={"authorization_token": token, "address": "Fictional Approved Address 20"})
    assert response.status_code == 200
    assert client.get(API+"/profile", headers=h).json()["pending_reference"] == response.json()["reference"]
    request = db_session.scalar(select(ServiceRequest).where(ServiceRequest.reference == response.json()["reference"]))
    customer = db_session.get(User, request.customer_id)
    old_name = customer.profile.first_name_en
    assert apply_approval_effects(db_session, request, actor=customer) == "completed"
    db_session.commit()
    assert customer.profile.address == "Fictional Approved Address 20"
    assert customer.profile.first_name_en == old_name
    assert db_session.scalar(select(AuditLog).where(AuditLog.action == "profile.update_approved"))
