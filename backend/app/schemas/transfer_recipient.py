"""Normalized development routing inputs; no external directory verification."""
import re
import unicodedata
from pydantic import BaseModel, ConfigDict, Field, field_validator

OUTBOUND_TYPES = {'external_domestic', 'international', 'wallet', 'instapay'}
TRANSFER_TYPES = ('own_accounts', 'internal', 'external_domestic', 'international', 'wallet', 'instapay')

def compact(value: str) -> str:
    return ''.join(str(unicodedata.digit(c)) if c.isdecimal() else c for c in re.sub(r'[\s\-()]', '', value))

def valid_iban(value: str) -> bool:
    if not re.fullmatch(r'[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}', value):
        return False
    expanded=''.join(str(ord(c)-55) if c.isalpha() else c for c in value[4:]+value[:4])
    return int(expanded)%97==1

def egypt_mobile(value: str) -> str:
    value=compact(value)
    if value.startswith('0020'):value='0'+value[4:]
    elif value.startswith('+20'):value='0'+value[3:]
    if not re.fullmatch(r'01[0125][0-9]{8}',value):raise ValueError('Enter a valid Egyptian mobile number')
    return value

class TransferRecipient(BaseModel):
    model_config=ConfigDict(extra='forbid')
    name: str=Field(min_length=2,max_length=120)
    destination: str=Field(min_length=3,max_length=128)
    bank_name: str | None=Field(default=None,min_length=2,max_length=120)
    country_code: str | None=Field(default=None,pattern=r'^[A-Z]{2}$')
    swift_code: str | None=Field(default=None,pattern=r'^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$')

    @field_validator('name','bank_name','destination',mode='before')
    @classmethod
    def trim(cls,value):return value.strip() if isinstance(value,str) else value

    @field_validator('country_code','swift_code',mode='before')
    @classmethod
    def uppercase(cls,value):return value.strip().upper() if isinstance(value,str) else value

    def for_channel(self,channel: str):
        if channel=='wallet':
            self.destination=egypt_mobile(self.destination)
        elif channel=='instapay':
            value=compact(self.destination).lower()
            if '@' in value:
                if not re.fullmatch(r'[a-z0-9][a-z0-9._-]{1,63}@instapay',value):raise ValueError('Enter an IPA address or Egyptian mobile number')
                self.destination=value
            else:self.destination=egypt_mobile(value)
        else:
            value=compact(self.destination).upper()
            if not self.bank_name:raise ValueError('The receiving bank is required')
            if channel=='external_domestic':
                if value.startswith('EG'):
                    if len(value)!=29 or not valid_iban(value):raise ValueError('Enter a valid Egyptian IBAN')
                elif not re.fullmatch(r'[0-9]{6,34}',value):raise ValueError('Enter a valid domestic account number')
                if self.country_code not in {None,'EG'} or self.swift_code:raise ValueError('Domestic transfers use Egyptian banks')
                self.country_code='EG'
            elif channel=='international':
                if not self.country_code or self.country_code=='EG' or not self.swift_code:raise ValueError('Country outside Egypt and SWIFT/BIC are required')
                if self.swift_code[4:6]!=self.country_code:raise ValueError('SWIFT/BIC country does not match')
                if re.match(r'^[A-Z]{2}[0-9]{2}',value):
                    if not valid_iban(value) or value[:2]!=self.country_code:raise ValueError('IBAN country or checksum is invalid')
                elif not re.fullmatch(r'[A-Z0-9]{6,34}',value):raise ValueError('Enter a valid destination account number')
            self.destination=value
        if channel in {'wallet','instapay'} and any([self.bank_name,self.country_code,self.swift_code]):
            raise ValueError('Mobile/IPA routes do not accept bank routing fields')
        return self
