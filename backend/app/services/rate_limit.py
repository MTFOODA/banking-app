"""In-process rate limiting for authentication and sensitive endpoints.

A single-process demo implementation. Production deployments must use a shared
store (Redis) or an API gateway so limits hold across instances.
"""

from __future__ import annotations

import threading
import time
from collections import defaultdict, deque

from app.core.config import settings
from app.core.exceptions import AppError

_lock = threading.Lock()
_buckets: dict[str, deque[float]] = defaultdict(deque)


def check_rate_limit(key: str, *, limit: int, window_seconds: int | None = None) -> None:
    window = window_seconds or settings.rate_limit_window_seconds
    now = time.monotonic()
    with _lock:
        bucket = _buckets[key]
        while bucket and now - bucket[0] > window:
            bucket.popleft()
        if len(bucket) >= limit:
            retry_after = int(window - (now - bucket[0])) + 1
            raise AppError(
                code="rate_limited",
                message="Too many attempts. Please try again later.",
                status_code=429,
                details={"retry_after_seconds": max(retry_after, 1)},
            )
        bucket.append(now)


def reset_rate_limits() -> None:
    """Used by tests to isolate cases."""
    with _lock:
        _buckets.clear()
