"""Application configuration loaded from environment variables.

Never commit real secrets. Copy `.env.example` to `.env` and adjust for local use.
"""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parents[2]
REPO_ROOT = BACKEND_DIR.parent


class Settings(BaseSettings):
    """Typed runtime settings.

    All values can be overridden with environment variables of the same name.
    """

    model_config = SettingsConfigDict(
        env_file=(BACKEND_DIR / ".env", REPO_ROOT / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    # --- Application -----------------------------------------------------
    app_name: str = "Banking App API"
    environment: str = "development"
    debug: bool = True
    api_v1_prefix: str = "/api/v1"

    # --- Database --------------------------------------------------------
    database_url: str = "postgresql+psycopg://faisal:faisal@localhost:5432/faisal_bank"
    test_database_url: str = (
        "postgresql+psycopg://faisal:faisal@localhost:5432/faisal_bank_test"
    )
    database_echo: bool = False
    database_pool_size: int = 5

    # --- Security --------------------------------------------------------
    jwt_secret: str = "change-me-development-only-secret-value"
    jwt_algorithm: str = "HS256"
    access_token_minutes: int = 15
    refresh_token_days: int = 30
    first_login_token_minutes: int = 10
    # Additional server-side pepper for deterministic identifiers (card number lookup).
    login_identifier_pepper: str = "change-me-development-only-pepper"
    password_argon2_time_cost: int = 3
    password_argon2_memory_cost: int = 65536
    password_argon2_parallelism: int = 2
    max_failed_login_attempts: int = 5
    login_lock_minutes: int = 15

    # --- Rate limiting (in-process; use Redis in production) -------------
    rate_limit_window_seconds: int = 60
    login_rate_limit_attempts: int = 10
    sensitive_rate_limit_attempts: int = 20
    otp_provider: str = "development"
    otp_dev_expose: bool = False
    otp_ttl_seconds: int = 300
    otp_resend_seconds: int = 60
    otp_max_attempts: int = 5
    authorization_ttl_seconds: int = 180
    transfer_limit: int = 100000
    outbound_transfer_provider: str = 'disabled'
    investment_max_penalty_percent: float = Field(default=5, ge=0, le=99)
    fx_api_key: str = ''
    fx_cache_seconds: int = Field(default=60, ge=60)
    own_fx_quote_seconds: int = Field(default=180,ge=30,le=600)
    fx_spread_bps: int = Field(default=100, ge=0, le=2000)
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_from: str = ""

    # --- CORS / client ---------------------------------------------------
    cors_origins: str = (
        "http://localhost:3000,http://localhost:8080,http://localhost:5173,"
        "http://127.0.0.1:3000,http://127.0.0.1:8080,http://127.0.0.1:5173"
    )
    cors_origin_regex: str = r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"

    # --- Uploads ---------------------------------------------------------
    upload_dir: Path = BACKEND_DIR / "var" / "uploads"
    max_upload_bytes: int = 5 * 1024 * 1024
    allowed_upload_types: str = "application/pdf,image/png,image/jpeg"

    # --- Demo administrator bootstrap (never hardcode in source) ---------
    demo_admin_employee_number: str = ""
    demo_admin_initial_password: str = ""
    demo_admin_name: str = "Demo Administrator"

    # --- Misc ------------------------------------------------------------
    expose_demo_credentials_in_docs: bool = True

    @field_validator("environment")
    @classmethod
    def _validate_environment(cls, value: str) -> str:
        allowed = {"development", "test", "staging", "production"}
        normalized = value.strip().lower()
        if normalized not in allowed:
            raise ValueError(f"environment must be one of {sorted(allowed)}")
        return normalized

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

    @property
    def allowed_upload_content_types(self) -> set[str]:
        return {item.strip() for item in self.allowed_upload_types.split(",") if item.strip()}

    @property
    def is_production(self) -> bool:
        return self.environment == "production"

    def validate_production_secrets(self) -> None:
        """Refuse to boot in production with the shipped development secrets."""
        if not self.is_production:
            return
        if self.outbound_transfer_provider != 'disabled':
            raise RuntimeError('No production outbound transfer provider is configured')
        if self.jwt_secret.startswith(("change-me", "dev-only")) or len(self.jwt_secret) < 32:
            raise RuntimeError("JWT_SECRET must be a strong unique value in production")
        if self.login_identifier_pepper.startswith(("change-me", "dev-only")) or len(self.login_identifier_pepper) < 32:
            raise RuntimeError("LOGIN_IDENTIFIER_PEPPER must be unique in production")
        if "faisal:faisal" in self.database_url:
            raise RuntimeError("DATABASE_URL must not use demo credentials in production")
        if self.debug:
            raise RuntimeError("DEBUG must be false in production")
        if self.otp_provider != "smtp" or self.otp_dev_expose:
            raise RuntimeError("Production requires real OTP delivery and disabled development codes")
        if not self.smtp_host or not self.smtp_from:
            raise RuntimeError("Production requires a configured SMTP host and sender")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
