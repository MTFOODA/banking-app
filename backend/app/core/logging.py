"""Logging configuration that never writes secrets or full identifiers."""

from __future__ import annotations

import logging
import re
import sys

_SENSITIVE_PATTERNS = [
    (re.compile(r"(?i)(authorization|password|otp|pin|token)\s*[:=]\s*\S+"), r"\1=***"),
    (re.compile(r"\b\d{13,19}\b"), "****"),
]


class RedactingFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        try:
            message = record.getMessage()
        except Exception:  # pragma: no cover
            return True
        for pattern, replacement in _SENSITIVE_PATTERNS:
            message = pattern.sub(replacement, message)
        record.msg = message
        record.args = ()
        return True


def configure_logging(level: str = "INFO") -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(
        logging.Formatter("%(asctime)s | %(levelname)-8s | %(name)s | %(message)s")
    )
    handler.addFilter(RedactingFilter())
    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(level.upper())
    logging.getLogger("uvicorn.access").addFilter(RedactingFilter())
