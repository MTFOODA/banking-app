"""Reviewed public location snapshots. No outbound requests or customer access."""
import hashlib
import json
from functools import lru_cache
from pathlib import Path
from urllib.parse import urlsplit, parse_qs

from app.core.exceptions import AppError
from app.services.bank_catalogue_data import catalogue


@lru_cache(maxsize=1)
def _snapshots():
    data = json.loads((Path(__file__).resolve().parents[1] / 'data/bank_directories.json').read_text(encoding='utf-8'))
    known = {b['code'] for b in catalogue()['banks']}
    if set(data) != known:
        raise ValueError('Directory catalogue mismatch')
    for code, snapshot in data.items():
        if snapshot['bank_code'] != code:
            raise ValueError('Directory affiliation mismatch')
        for kind in ('branches', 'atms'):
            if snapshot[kind + '_status'] not in {'published', 'partial', 'unavailable', 'not_applicable'}:
                raise ValueError('Invalid directory coverage')
            ids = set()
            for row in snapshot[kind]:
                if not all(isinstance(row.get(k), str) and row[k].strip() for k in ('id', 'name', 'address', 'maps_url')) or row['id'] in ids:
                    raise ValueError('Invalid directory row')
                ids.add(row['id'])
                uri = urlsplit(row['maps_url'])
                if uri.scheme != 'https' or uri.netloc != 'www.google.com' or uri.path != '/maps/search/' or parse_qs(uri.query).get('api') != ['1']:
                    raise ValueError('Unsafe directory map link')
        # Derive the response version from the reviewed content, including any
        # contact metadata change. Never trust a client-supplied bank snapshot.
        snapshot['version'] = hashlib.sha256(json.dumps({k: v for k, v in snapshot.items() if k != 'version'}, sort_keys=True, ensure_ascii=False).encode()).hexdigest()[:16]
    return data


def public_directory(bank_code):
    value = _snapshots().get(bank_code)
    if value is None:
        raise AppError(code='bank_unavailable', message='Unknown bank.', status_code=404)
    return value
