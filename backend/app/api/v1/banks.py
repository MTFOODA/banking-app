from fastapi import APIRouter,Depends,Query,Response
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.services.bank_catalogue import public_catalogue

router=APIRouter(prefix='/banks',tags=['Banks'])


@router.get('')
def list_banks(response:Response,known_version:str|None=Query(None,max_length=32),db:Session=Depends(get_db)):
    payload=public_catalogue(db)
    response.headers['Cache-Control']='no-cache'
    if known_version==payload['version']:
        return {'version':payload['version'],'unchanged':True}
    return payload
