"""Shared helpers and demo constants for the seed scripts."""

from __future__ import annotations

import sys
import uuid
from datetime import UTC, datetime
from decimal import Decimal
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
BACKEND_DIR = REPO_ROOT / "backend"
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.models.transactions import Transaction, TransactionEntry  # noqa: E402

NOW = datetime.now(UTC)

DEMO_CARD_1 = "4508123456789012"
DEMO_TEMP_1 = "1002003004001"
DEMO_CARD_2 = "4508987654321098"
DEMO_TEMP_2 = "1002003004002"

_COUNTER = {"value": 0}


def money(value: str) -> Decimal:
    return Decimal(value)


def ref(prefix: str) -> str:
    _COUNTER["value"] += 1
    return f"{prefix}-DEMO-{_COUNTER['value']:04d}"


def add_transaction(
    db,
    *,
    customer_id: uuid.UUID,
    account=None,
    card=None,
    tx_type: str,
    direction: str,
    amount: str,
    description: str,
    description_ar: str,
    occurred_at: datetime,
    counterparty: str | None = None,
    merchant: str | None = None,
    balance_after: Decimal | None = None,
    status: str = "posted",
) -> Transaction:
    txn = Transaction(
        customer_id=customer_id,
        account_id=account.id if account else None,
        card_id=card.id if card else None,
        journal_id=uuid.uuid4(),
        reference=ref("TXN"),
        transaction_type=tx_type,
        direction=direction,
        amount=money(amount),
        currency="EGP",
        description=description,
        description_ar=description_ar,
        counterparty=counterparty,
        merchant=merchant,
        status=status,
        is_simulated=True,
        balance_after=balance_after,
        occurred_at=occurred_at,
    )
    db.add(txn)
    db.flush()
    db.add(
        TransactionEntry(
            transaction_id=txn.id,
            account_id=account.id if account else None,
            entry_type=direction,
            amount=money(amount),
        )
    )
    return txn
