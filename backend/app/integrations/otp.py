"""OTP delivery adapters. Never log messages, codes or recipient addresses."""
from __future__ import annotations

import smtplib
import ssl
from email.message import EmailMessage
from typing import Protocol

from app.core.config import settings


class OtpProvider(Protocol):
    def send(self, *, email: str | None, phone: str | None, code: str) -> None: ...


class DevelopmentOtpProvider:
    """No delivery. Codes can be displayed only by explicit development opt-in."""
    def send(self, *, email: str | None, phone: str | None, code: str) -> None:
        if settings.environment not in {"development", "test"}:
            raise RuntimeError("Development OTP delivery is disabled")


class SmtpOtpProvider:
    def send(self, *, email: str | None, phone: str | None, code: str) -> None:
        if not email or not settings.smtp_host or not settings.smtp_from:
            raise RuntimeError("Email delivery is not configured")
        message = EmailMessage()
        message["From"] = settings.smtp_from
        message["To"] = email
        message["Subject"] = "Development Bank - registration verification"
        message.set_content(f"Your registration code is {code}. It expires in {settings.otp_ttl_seconds // 60} minutes. Do not share it.")
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=10) as smtp:
            smtp.starttls(context=ssl.create_default_context())
            if settings.smtp_username:
                smtp.login(settings.smtp_username, settings.smtp_password)
            smtp.send_message(message)


def get_otp_provider() -> OtpProvider:
    if settings.otp_provider == "smtp":
        return SmtpOtpProvider()
    if settings.otp_provider == "development" and settings.environment in {"development", "test"}:
        return DevelopmentOtpProvider()
    raise RuntimeError("OTP delivery is not configured")
