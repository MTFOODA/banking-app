"""Add isolated branding documents; no existing banking data is changed."""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "b317a90d66e1"
down_revision = "ab71e439d205"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table("branding_publications",
        sa.Column("version", sa.Integer(), primary_key=True),
        sa.Column("config", postgresql.JSONB(), nullable=False),
        sa.Column("published_by", sa.Uuid(), sa.ForeignKey("users.id", ondelete="SET NULL")),
        sa.Column("published_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("version > 0", name="branding_version_positive"))
    table = op.create_table("branding_settings",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("revision", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("active_version", sa.Integer(), sa.ForeignKey("branding_publications.version", ondelete="RESTRICT")),
        sa.Column("draft", postgresql.JSONB()),
        sa.Column("updated_by", sa.Uuid(), sa.ForeignKey("users.id", ondelete="SET NULL")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.CheckConstraint("id = 1", name="branding_singleton"),
        sa.CheckConstraint("revision >= 0", name="branding_revision_positive"))
    op.bulk_insert(table, [{"id": 1, "revision": 0}])


def downgrade():
    # Explicit operator action only. Export branding/history before downgrade.
    op.drop_table("branding_settings")
    op.drop_table("branding_publications")
