"""Add expiring own-account FX snapshots; preserve all banking records."""
from alembic import op
import sqlalchemy as sa
revision='ab71e439d205'
down_revision='f82b1d6a40c3'
branch_labels=None
depends_on=None

def upgrade():
    op.create_table('own_fx_quotes',
        sa.Column('id',sa.Uuid(),primary_key=True),
        sa.Column('customer_id',sa.Uuid(),sa.ForeignKey('users.id',ondelete='RESTRICT'),nullable=False),
        sa.Column('source_account_id',sa.Uuid(),sa.ForeignKey('accounts.id',ondelete='RESTRICT'),nullable=False),
        sa.Column('destination_account_id',sa.Uuid(),sa.ForeignKey('accounts.id',ondelete='RESTRICT'),nullable=False),
        sa.Column('draft_fingerprint',sa.String(64),nullable=False),
        sa.Column('source_amount',sa.Numeric(18,2),nullable=False),sa.Column('source_currency',sa.String(3),nullable=False),
        sa.Column('received_amount',sa.Numeric(18,2),nullable=False),sa.Column('received_currency',sa.String(3),nullable=False),
        sa.Column('exchange_rate',sa.Numeric(30,12),nullable=False),sa.Column('provider',sa.String(64),nullable=False),
        sa.Column('market_at',sa.DateTime(timezone=True),nullable=False),sa.Column('expires_at',sa.DateTime(timezone=True),nullable=False),
        sa.Column('consumed_at',sa.DateTime(timezone=True)),
        sa.Column('created_at',sa.DateTime(timezone=True),server_default=sa.func.now(),nullable=False),
        sa.Column('updated_at',sa.DateTime(timezone=True),server_default=sa.func.now(),nullable=False),
        sa.CheckConstraint('source_amount > 0 AND received_amount > 0 AND exchange_rate > 0',name='own_fx_positive'),
        sa.CheckConstraint('source_account_id <> destination_account_id',name='own_fx_distinct_accounts'))
    op.create_index('ix_own_fx_quotes_customer_id','own_fx_quotes',['customer_id'])
    op.create_index('ix_own_fx_quotes_expires_at','own_fx_quotes',['expires_at'])

def downgrade():
    op.drop_table('own_fx_quotes')
