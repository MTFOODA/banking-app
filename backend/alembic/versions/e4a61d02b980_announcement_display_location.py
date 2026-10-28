"""Choose announcement display location; keep existing notices at home.

Revision ID: e4a61d02b980
Revises: 9b9c0454d7c0
"""
from alembic import op
import sqlalchemy as sa

revision = 'e4a61d02b980'
down_revision = '9b9c0454d7c0'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('announcements', sa.Column('display_location', sa.String(16), nullable=False, server_default='home'))
    op.create_check_constraint('announcement_display_location', 'announcements', "display_location IN ('home','pre_login','both')")


def downgrade():
    op.drop_constraint('announcement_display_location', 'announcements', type_='check')
    op.drop_column('announcements', 'display_location')
