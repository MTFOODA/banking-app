"""Short-lived, customer-owned FX snapshots for simulated own-account transfers."""
from datetime import datetime
from decimal import Decimal
import uuid
from sqlalchemy import CheckConstraint,DateTime,ForeignKey,Numeric,String,Uuid
from sqlalchemy.orm import Mapped,mapped_column
from app.models.base import Base,TimestampMixin,uuid_pk

class OwnFxQuote(Base,TimestampMixin):
    __tablename__='own_fx_quotes'
    __table_args__=(CheckConstraint('source_amount > 0 AND received_amount > 0 AND exchange_rate > 0',name='own_fx_positive'),
        CheckConstraint('source_account_id <> destination_account_id',name='own_fx_distinct_accounts'),)
    id=uuid_pk()
    customer_id:Mapped[uuid.UUID]=mapped_column(Uuid(as_uuid=True),ForeignKey('users.id',ondelete='RESTRICT'),index=True)
    source_account_id:Mapped[uuid.UUID]=mapped_column(Uuid(as_uuid=True),ForeignKey('accounts.id',ondelete='RESTRICT'))
    destination_account_id:Mapped[uuid.UUID]=mapped_column(Uuid(as_uuid=True),ForeignKey('accounts.id',ondelete='RESTRICT'))
    draft_fingerprint:Mapped[str]=mapped_column(String(64))
    source_amount:Mapped[Decimal]=mapped_column(Numeric(18,2))
    source_currency:Mapped[str]=mapped_column(String(3))
    received_amount:Mapped[Decimal]=mapped_column(Numeric(18,2))
    received_currency:Mapped[str]=mapped_column(String(3))
    exchange_rate:Mapped[Decimal]=mapped_column(Numeric(30,12))
    provider:Mapped[str]=mapped_column(String(64))
    market_at:Mapped[datetime]=mapped_column(DateTime(timezone=True))
    expires_at:Mapped[datetime]=mapped_column(DateTime(timezone=True),index=True)
    consumed_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True))
