"""Persist masked transfer routing and simulated delivery receipt.

Revision ID: f82b1d6a40c3
Revises: e4a61d02b980
"""
from alembic import op
import sqlalchemy as sa
revision='f82b1d6a40c3'
down_revision='e4a61d02b980'
branch_labels=None
depends_on=None

def upgrade():
    op.add_column('transactions',sa.Column('transfer_metadata',sa.JSON(),nullable=True))

def downgrade():
    op.drop_column('transactions','transfer_metadata')
