"""Faisal App API entry point."""

from __future__ import annotations

import logging
import uuid
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text

from app.api.router import api_router
from app.core.config import settings
from app.core.database import SessionLocal, engine
from app.core.exceptions import register_exception_handlers
from app.core.logging import configure_logging
from app.core.security import PASSWORD_MIN_LENGTH, PASSWORD_REQUIREMENT_CODES

configure_logging("DEBUG" if settings.debug else "INFO")
logger = logging.getLogger("faisal.app")


@asynccontextmanager
async def lifespan(app: FastAPI):
    Path(settings.upload_dir).mkdir(parents=True, exist_ok=True)
    settings.validate_production_secrets()
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        logger.info("Database connection verified")
    except Exception as exc:  # pragma: no cover - startup diagnostics
        logger.warning("Database not reachable at startup: %s", type(exc).__name__)
    yield


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description=(
        "Demo API for Faisal App (Faisal Islamic Bank of Egypt customer experience). "
        "All money movements are simulated and are not connected to a real core "
        "banking system."
    ),
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    openapi_tags=[
        {"name": "Authentication", "description": "Sign-in, first-login setup and sessions"},
        {"name": "Accounts", "description": "Customer accounts and account requests"},
        {"name": "Cards", "description": "Cards and immediate card controls"},
        {"name": "Card requests", "description": "Replacement, limits and supplementary cards"},
        {"name": "Transactions", "description": "Scoped transaction history"},
        {"name": "Transfers", "description": "Simulated transfers"},
        {"name": "Beneficiaries", "description": "Saved beneficiaries"},
        {"name": "Repayments", "description": "Simulated credit-card repayments"},
        {"name": "Requests", "description": "Unified service requests"},
        {"name": "Notifications", "description": "Customer notifications"},
        {"name": "Discover", "description": "Announcements, products and offers"},
        {"name": "Profile", "description": "Profile and preferences"},
        {"name": "Support", "description": "Support conversations"},
        {"name": "Administration", "description": "Staff-only operations"},
    ],
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_origin_regex=settings.cors_origin_regex,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Idempotency-Key", "X-Request-ID"],
    expose_headers=["X-Request-ID"],
)


@app.middleware("http")
async def request_context(request: Request, call_next):
    if settings.is_production and request.url.path.startswith(settings.api_v1_prefix) and request.url.scheme != "https":
        return JSONResponse(status_code=426, content={"error": {"code": "https_required", "message": "HTTPS is required."}})
    request_id = request.headers.get("x-request-id") or str(uuid.uuid4())
    request.state.request_id = request_id
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Referrer-Policy"] = "no-referrer"
    if request.url.path.startswith(settings.api_v1_prefix + "/auth") or request.url.path.startswith(settings.api_v1_prefix + "/profile"):
        response.headers["Cache-Control"] = "no-store"
    return response


register_exception_handlers(app)
app.include_router(api_router, prefix=settings.api_v1_prefix)


@app.get("/", tags=["System"], summary="Service metadata")
def root() -> dict:
    return {
        "name": settings.app_name,
        "environment": settings.environment,
        "api": settings.api_v1_prefix,
        "documentation": "/docs",
        "demo": True,
        "notice": (
            "Demo implementation. Not connected to Faisal Islamic Bank systems. "
            "All financial movements are simulated."
        ),
    }


@app.get("/health", tags=["System"], summary="Health check without credentials")
def health() -> JSONResponse:
    database_ok = True
    try:
        with SessionLocal() as session:
            session.execute(text("SELECT 1"))
    except Exception:  # pragma: no cover - environment dependent
        database_ok = False
    payload = {
        "status": "ok" if database_ok else "degraded",
        "database": "up" if database_ok else "down",
        "environment": settings.environment,
        "password_policy": {
            "min_length": PASSWORD_MIN_LENGTH,
            "requirements": list(PASSWORD_REQUIREMENT_CODES),
        },
    }
    return JSONResponse(status_code=200 if database_ok else 503, content=payload)
