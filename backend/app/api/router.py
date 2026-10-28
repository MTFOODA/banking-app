"""Versioned API router aggregation."""

from fastapi import APIRouter
from app.api.v1 import security, investments, branding

from app.api.v1 import (
    accounts,
    admin,
    admin_content,
    admin_request_actions,
    admin_requests,
    auth,
    card_request_routes,
    cards,
    notifications,
    payments,
    products,
    profile,
    repayments,
    requests,
    support,
    transactions,
    transfers,
)

api_router = APIRouter()
api_router.include_router(branding.router)
api_router.include_router(security.router)
api_router.include_router(investments.router)
api_router.include_router(auth.router)
api_router.include_router(accounts.router)
api_router.include_router(cards.router)
api_router.include_router(card_request_routes.router)
api_router.include_router(transactions.router)
api_router.include_router(transfers.router)
api_router.include_router(transfers.beneficiaries_router)
api_router.include_router(repayments.router)
api_router.include_router(payments.router)
api_router.include_router(requests.router)
api_router.include_router(notifications.router)
api_router.include_router(products.router)
api_router.include_router(profile.router)
api_router.include_router(support.router)
api_router.include_router(admin.router)
api_router.include_router(admin_requests.router)
api_router.include_router(admin_request_actions.router)
api_router.include_router(admin_content.router)
