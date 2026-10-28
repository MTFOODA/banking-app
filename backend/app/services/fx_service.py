"""Global indicative FX quotes. Never disguise a derived spread as a bank quote."""
from copy import deepcopy
from datetime import datetime, timezone, timedelta
from decimal import Decimal
import threading
import time
import httpx
from app.core.config import settings
from app.core.exceptions import AppError

URL = 'https://api.exchangerate.dev/v1/latest/EGP'
SYMBOLS = ('USD', 'SAR', 'EUR', 'AED', 'GBP', 'KWD', 'QAR', 'CHF')
_lock = threading.Lock()
_cache = None
_retry_at = 0.0
_failure = False


def _timestamp(value):
    parsed = datetime.fromisoformat(value.replace('Z', '+00:00'))
    if parsed.tzinfo is None or parsed > datetime.now(timezone.utc) + timedelta(minutes=5):
        raise ValueError('Invalid market timestamp')
    return parsed


def parse(data, delay: int) -> dict:
    if data.get('result') != 'success' or data.get('base') != 'EGP':
        raise ValueError('Invalid global FX response')
    updated = _timestamp(data['data_updated_at'])
    rates = data['rates']
    spread = Decimal(settings.fx_spread_bps) / Decimal(20000)
    quotes = []
    for symbol in SYMBOLS:
        rate = Decimal(str(rates[symbol]))
        if not rate.is_finite() or rate <= 0 or rate > Decimal('1000000000000'):
            raise ValueError('Invalid global FX rate')
        midpoint = Decimal(1) / rate
        effective = _timestamp(data.get('effective_at', {}).get(symbol, data['data_updated_at']))
        quotes.append({'currency': symbol, 'mid': str(midpoint.quantize(Decimal('0.000001'))),
            'buy': str((midpoint * (1-spread)).quantize(Decimal('0.000001'))),
            'sell': str((midpoint * (1+spread)).quantize(Decimal('0.000001'))),
            'updated_at': effective.isoformat(), 'source': data.get('sources', {}).get(symbol, data['source']),
            'stale': bool(data.get('stale', {}).get(symbol, False)) or effective < datetime.now(timezone.utc)-timedelta(hours=24)})
    return {'base': 'EGP', 'source': 'exchangerate.dev', 'source_url': 'https://exchangerate.dev',
        'attribution_url': 'https://exchangerate.dev', 'market_session': data.get('market_session', 'unknown'),
        'provider_updated_at': updated.isoformat(), 'fetched_at': datetime.now(timezone.utc).isoformat(),
        'delay_seconds': max(0, delay), 'refresh_after_seconds': settings.fx_cache_seconds,
        'spread_bps': settings.fx_spread_bps, 'spread_is_simulated': True, 'is_executable': False,
        'quotes': quotes, 'stale': any(q['stale'] for q in quotes), 'upstream_unavailable': False}


def latest() -> dict:
    global _cache, _retry_at, _failure
    with _lock:
        if time.monotonic() >= _retry_at:
            _retry_at = time.monotonic() + settings.fx_cache_seconds
            try:
                headers = {'Accept': 'application/json'}
                if settings.fx_api_key:
                    headers['Authorization'] = f'Bearer {settings.fx_api_key}'
                with httpx.Client(timeout=12, follow_redirects=False) as client:
                    response = client.get(URL, params={'symbols': ','.join(SYMBOLS)}, headers=headers)
                    response.raise_for_status()
                    if len(response.content) > 200000:
                        raise ValueError('Unexpected FX response size')
                    _cache = parse(response.json(), int(response.headers.get('X-Price-Delay-Seconds', '900')))
                _failure = False
            except (httpx.HTTPError, ValueError, KeyError, TypeError, ArithmeticError):
                _failure = True
        if _cache is None:
            raise AppError(code='fx_unavailable', message='The market data provider is unavailable. Try again later.', status_code=503)
        result = deepcopy(_cache)
        result['upstream_unavailable'] = _failure
        now = datetime.now(timezone.utc)
        for row in result['quotes']:
            row['stale'] = row['stale'] or _timestamp(row['updated_at']) < now-timedelta(hours=24)
        result['stale'] = _failure or any(row['stale'] for row in result['quotes'])
        return result
