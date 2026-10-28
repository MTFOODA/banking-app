"""Authentication, identifier handling and customer-scoping regression tests."""

from __future__ import annotations

from datetime import timedelta

import pytest
from sqlalchemy import select

from app.core.security import hash_identifier
from app.models.banking import Account, AccountProduct
from app.models.user import User
from app.services.auth_service import resolve_login_user
from app.services.common import utcnow
from demo_banking_data import demo_id

API = "/api/v1"

READY_USERS = [
    dict(name="Youssef", card="4000000000000101", account="5550000000101", password="Youssef#2026"),
    dict(name="Salma", card="4000000000000102", account="5550000000102", password="Salma#2026"),
    dict(name="Omar", card="4000000000000104", account="5550000000104", password="Omar#2026"),
    dict(name="Hana", card="4000000000000106", account="5550000000107", password="Hana#2026"),
    dict(name="Karim", card="4000000000000107", account="5550000000108", password="Karim#2026"),
]
NADA = dict(card="4000000000000109", password="Temp#Nada2026")


def login(client, identifier: str, password: str, key: str = "identifier"):
    return client.post(
        f"{API}/auth/login",
        json={key: identifier, "password": password, "remember_device": False},
    )


def token_for(client, user: dict) -> str:
    response = login(client, user["card"], user["password"])
    assert response.status_code == 200, response.text
    return response.json()["access_token"]


@pytest.mark.parametrize("user", READY_USERS, ids=[item["name"] for item in READY_USERS])
def test_card_and_account_number_login_resolve_same_customer(client, user):
    by_card = login(client, user["card"], user["password"])
    by_account = login(client, user["account"], user["password"])

    assert by_card.status_code == 200, by_card.text
    assert by_account.status_code == 200, by_account.text
    assert by_card.json()["status"] == "authenticated"
    assert by_account.json()["status"] == "authenticated"
    assert by_card.json()["user"]["id"] == by_account.json()["user"]["id"]
    assert by_card.json()["user"]["must_change_password"] is False
    assert by_card.json()["access_token"]
    assert by_card.json()["refresh_token"]


def test_legacy_card_number_key_and_separators_are_accepted(client):
    response = login(client, "4000 0000 0000 0101", "Youssef#2026", key="card_number")
    assert response.status_code == 200, response.text
    assert response.json()["status"] == "authenticated"


def test_unknown_identifier_is_rejected(client):
    response = login(client, "4000000000000199", "Youssef#2026")
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "invalid_credentials"


def test_incorrect_password_is_rejected(client):
    response = login(client, READY_USERS[0]["card"], "Definitely-Wrong1!")
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "invalid_credentials"


def test_another_customers_card_cannot_be_used_with_a_different_password(client):
    response = login(client, READY_USERS[1]["card"], READY_USERS[0]["password"])
    assert response.status_code == 401

    # The same card with its real password still resolves to Salma.
    legitimate = login(client, READY_USERS[1]["card"], READY_USERS[1]["password"])
    salma = login(client, READY_USERS[1]["account"], READY_USERS[1]["password"])
    assert legitimate.status_code == 200
    assert legitimate.json()["user"]["id"] == salma.json()["user"]["id"]


def test_customer_with_multiple_accounts_can_use_each_account_number(client):
    response = login(client, "5550000000103", READY_USERS[1]["password"])  # Salma savings
    assert response.status_code == 200
    assert response.json()["user"]["id"] == login(
        client, READY_USERS[1]["account"], READY_USERS[1]["password"]
    ).json()["user"]["id"]

    token = response.json()["access_token"]
    accounts = client.get(f"{API}/accounts", headers={"Authorization": f"Bearer {token}"})
    assert accounts.status_code == 200
    assert len(accounts.json()["accounts"]) == 2


@pytest.mark.parametrize(
    "payload",
    [
        {},
        {"identifier": "1234", "password": "x"},
        {"identifier": "      ", "password": "x"},
        {"identifier": READY_USERS[0]["card"]},
    ],
)
def test_missing_or_malformed_login_fields_are_rejected(client, payload):
    response = client.post(f"{API}/auth/login", json=payload)
    assert response.status_code == 422


def test_locked_account_is_rejected(client, db_session):
    user = db_session.scalar(
        select(User).where(User.login_identifier_hash == hash_identifier(READY_USERS[3]["card"]))
    )
    user.locked_until = utcnow() + timedelta(minutes=10)
    db_session.flush()

    response = login(client, READY_USERS[3]["card"], READY_USERS[3]["password"])
    assert response.status_code == 423
    assert response.json()["error"]["code"] == "account_temporarily_locked"


def test_inactive_account_is_rejected(client, db_session):
    user = db_session.scalar(
        select(User).where(User.login_identifier_hash == hash_identifier(READY_USERS[4]["card"]))
    )
    user.is_active = False
    db_session.flush()

    response = login(client, READY_USERS[4]["card"], READY_USERS[4]["password"])
    assert response.status_code == 401


def test_token_issuance_and_authenticated_me(client):
    token = token_for(client, READY_USERS[0])
    response = client.get(f"{API}/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    body = response.json()
    assert body["login_identifier_masked"] == "**** **** **** 0101"
    assert body["login_type"] == "customer"
    assert body["must_change_password"] is False


def test_invalid_token_is_rejected(client):
    response = client.get(
        f"{API}/auth/me", headers={"Authorization": "Bearer not-a-real-token"}
    )
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "invalid_token"


def test_unauthenticated_endpoints_are_rejected(client):
    for path in ("/accounts", "/cards", "/transactions"):
        assert client.get(f"{API}{path}").status_code == 401


def test_customer_only_sees_owned_records(client):
    token = token_for(client, READY_USERS[2])  # Omar: 3 accounts, 2 cards
    headers = {"Authorization": f"Bearer {token}"}

    accounts = client.get(f"{API}/accounts", headers=headers)
    cards = client.get(f"{API}/cards", headers=headers)
    transactions = client.get(f"{API}/transactions?page_size=100", headers=headers)

    assert accounts.status_code == 200
    assert len(accounts.json()["accounts"]) == 3
    assert {item["account_number_masked"] for item in accounts.json()["accounts"]} == {
        "**** **** 0104",
        "**** **** 0105",
        "**** **** 0106",
    }
    assert cards.status_code == 200
    assert len(cards.json()["cards"]) == 2
    assert transactions.status_code == 200
    assert transactions.json()["total"] >= 10
    assert all(
        item["reference"].startswith("DEMO-BNK-")
        for item in transactions.json()["items"]
    )


def test_cross_customer_record_access_is_denied(client):
    salma_token = token_for(client, READY_USERS[1])
    salma_headers = {"Authorization": f"Bearer {salma_token}"}
    foreign_account = client.get(f"{API}/accounts", headers=salma_headers).json()[
        "accounts"
    ][0]["id"]
    foreign_card = client.get(f"{API}/cards", headers=salma_headers).json()["cards"][0][
        "id"
    ]
    foreign_txn = client.get(
        f"{API}/transactions?page_size=1", headers=salma_headers
    ).json()["items"][0]["id"]

    youssef_token = token_for(client, READY_USERS[0])
    headers = {"Authorization": f"Bearer {youssef_token}"}
    assert client.get(f"{API}/accounts/{foreign_account}", headers=headers).status_code == 404
    assert client.get(f"{API}/cards/{foreign_card}", headers=headers).status_code == 404
    assert (
        client.get(f"{API}/transactions/{foreign_txn}", headers=headers).status_code == 404
    )


def test_mandatory_password_setup_flow(client):
    started = login(client, NADA["card"], NADA["password"])
    assert started.status_code == 200
    body = started.json()
    assert body["status"] == "password_setup_required"
    setup_token = body["setup_token"]
    assert setup_token
    assert body["access_token"] is None

    setup_headers = {"Authorization": f"Bearer {setup_token}"}
    assert client.get(f"{API}/auth/me", headers=setup_headers).status_code == 403
    assert client.get(f"{API}/accounts", headers=setup_headers).status_code == 403

    weak = client.post(
        f"{API}/auth/first-login/complete",
        json={"new_password": "weakpass", "confirm_password": "weakpass"},
        headers=setup_headers,
    )
    assert weak.status_code == 422

    mismatch = client.post(
        f"{API}/auth/first-login/complete",
        json={"new_password": "Nada#Secure2026", "confirm_password": "Nada#Secure2027"},
        headers=setup_headers,
    )
    assert mismatch.status_code == 422

    completed = client.post(
        f"{API}/auth/first-login/complete",
        json={"new_password": "Nada#Secure2026", "confirm_password": "Nada#Secure2026"},
        headers=setup_headers,
    )
    assert completed.status_code == 200, completed.text
    assert completed.json()["status"] == "authenticated"

    access = completed.json()["access_token"]
    me = client.get(f"{API}/auth/me", headers={"Authorization": f"Bearer {access}"})
    assert me.status_code == 200
    assert me.json()["must_change_password"] is False

    assert login(client, NADA["card"], NADA["password"]).status_code == 401
    assert login(client, NADA["card"], "Nada#Secure2026").status_code == 200


def test_ambiguous_identifier_is_rejected(client, db_session):
    salma = db_session.scalar(
        select(User).where(User.login_identifier_hash == hash_identifier(READY_USERS[1]["card"]))
    )
    product = db_session.scalar(
        select(AccountProduct).where(AccountProduct.code == "AP-CURRENT")
    )
    db_session.add(
        Account(
            id=demo_id("test:ambiguous-account"),
            customer_id=salma.id,
            product_id=product.id,
            account_number_hash=hash_identifier(
                f"acct:{READY_USERS[0]['card']}"
            ),
            account_number_masked="**** **** 0101",
            iban="EG3800190005999999999999999",
            account_type="current",
            currency="EGP",
            status="active",
            current_balance=0,
            available_balance=0,
            blocked_balance=0,
            opened_at=utcnow(),
        )
    )
    db_session.flush()

    assert resolve_login_user(db_session, READY_USERS[0]["card"]) is None
    response = login(client, READY_USERS[0]["card"], READY_USERS[0]["password"])
    assert response.status_code == 401
