"""Public bank metadata, with existing-database affiliation and strict server checks."""
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from app.models.bank import Bank
from app.services.bank_catalogue_data import BANK_ROWS, catalogue
from app.core.exceptions import AppError


def seed_bank_catalogue(db):
    """Add missing catalogue rows only; never rewrite customer affiliation/state."""
    for code,en,ar,url,_,_ in BANK_ROWS:
        db.execute(insert(Bank).values(code=code,name_en=en,name_ar=ar,website=url)
                   .on_conflict_do_nothing(index_elements=[Bank.code]))
    db.flush()


def public_catalogue(db):
    result=catalogue()
    active=set(db.scalars(select(Bank.code).where(Bank.is_active.is_(True))))
    result['banks']=[{**row,'registration_enabled':row['registration_enabled'] and row['code'] in active}
                     for row in result['banks']]
    # Activity changes also invalidate conditional catalogue responses.
    import hashlib,json
    result['version']=hashlib.sha256(json.dumps(result,sort_keys=True).encode()).hexdigest()[:16]
    return result


def registration_bank(db, code):
    row=db.get(Bank,code)
    definition=next((b for b in catalogue()['banks'] if b['code']==code),None)
    if row is None or not row.is_active or definition is None or not definition['registration_enabled']:
        raise AppError(code='bank_unavailable',message='Choose an available bank.',status_code=422)
    return row
