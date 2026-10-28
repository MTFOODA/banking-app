"""Explicit, opt-in removal of demo customers and their related rows."""

from __future__ import annotations

from sqlalchemy import delete, select

from app.models.banking import (
    Account,
    Beneficiary,
    Card,
    CardLimit,
    SupplementaryCardRelationship,
)
from app.models.service import (
    Notification,
    NotificationRead,
    RequestDocument,
    RequestStatusHistory,
    ServiceRequest,
    SupportMessage,
    SupportTicket,
)
from app.models.transactions import (
    CreditCardStatement,
    Repayment,
    Transaction,
    TransactionEntry,
)
from app.models.user import CustomerProfile, User

DEMO_CUSTOMER_NUMBERS = ("C-100001", "C-100002")


def reset_demo(db) -> int:
    profile_rows = db.execute(
        select(CustomerProfile.user_id).where(
            CustomerProfile.customer_number.in_(DEMO_CUSTOMER_NUMBERS)
        )
    ).all()
    user_ids = [row[0] for row in profile_rows]
    if not user_ids:
        return 0

    transaction_ids = [
        row[0]
        for row in db.execute(
            select(Transaction.id).where(Transaction.customer_id.in_(user_ids))
        ).all()
    ]
    request_ids = [
        row[0]
        for row in db.execute(
            select(ServiceRequest.id).where(ServiceRequest.customer_id.in_(user_ids))
        ).all()
    ]
    ticket_ids = [
        row[0]
        for row in db.execute(
            select(SupportTicket.id).where(SupportTicket.customer_id.in_(user_ids))
        ).all()
    ]
    card_ids = [
        row[0]
        for row in db.execute(select(Card.id).where(Card.customer_id.in_(user_ids))).all()
    ]

    if transaction_ids:
        db.execute(delete(TransactionEntry).where(TransactionEntry.transaction_id.in_(transaction_ids)))
        db.execute(delete(Transaction).where(Transaction.id.in_(transaction_ids)))
    if request_ids:
        db.execute(delete(RequestDocument).where(RequestDocument.request_id.in_(request_ids)))
        db.execute(
            delete(RequestStatusHistory).where(RequestStatusHistory.request_id.in_(request_ids))
        )
        db.execute(delete(ServiceRequest).where(ServiceRequest.id.in_(request_ids)))
    if ticket_ids:
        db.execute(delete(SupportMessage).where(SupportMessage.ticket_id.in_(ticket_ids)))
        db.execute(delete(SupportTicket).where(SupportTicket.id.in_(ticket_ids)))
    if card_ids:
        db.execute(
            delete(SupplementaryCardRelationship).where(
                SupplementaryCardRelationship.primary_card_id.in_(card_ids)
            )
        )
        db.execute(
            delete(SupplementaryCardRelationship).where(
                SupplementaryCardRelationship.supplementary_card_id.in_(card_ids)
            )
        )
        db.execute(delete(CreditCardStatement).where(CreditCardStatement.card_id.in_(card_ids)))
        db.execute(delete(CardLimit).where(CardLimit.card_id.in_(card_ids)))

    db.execute(delete(Repayment).where(Repayment.customer_id.in_(user_ids)))
    if card_ids:
        db.execute(delete(Card).where(Card.id.in_(card_ids)))
    db.execute(delete(Account).where(Account.customer_id.in_(user_ids)))
    db.execute(delete(Beneficiary).where(Beneficiary.customer_id.in_(user_ids)))

    notification_ids = [
        row[0]
        for row in db.execute(
            select(Notification.id).where(Notification.customer_id.in_(user_ids))
        ).all()
    ]
    if notification_ids:
        db.execute(
            delete(NotificationRead).where(NotificationRead.notification_id.in_(notification_ids))
        )
        db.execute(delete(Notification).where(Notification.id.in_(notification_ids)))
    db.execute(delete(NotificationRead).where(NotificationRead.customer_id.in_(user_ids)))

    # Users cascade to profiles, preferences and sessions.
    db.execute(delete(User).where(User.id.in_(user_ids)))
    db.commit()
    return len(user_ids)

