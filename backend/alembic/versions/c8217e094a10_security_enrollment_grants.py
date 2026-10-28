"""Add enrollment state, one-time challenges/grants and safe transfer bindings.

Revision ID: c8217e094a10
Revises: 74d37c614037
"""
from alembic import op
import sqlalchemy as sa

revision = "c8217e094a10"
down_revision = "74d37c614037"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("users", sa.Column("enrollment_completed", sa.Boolean(), nullable=False, server_default=sa.true()))
    op.add_column("beneficiaries", sa.Column("destination_account_id", sa.Uuid(), sa.ForeignKey("accounts.id", ondelete="RESTRICT")))
    op.create_index("ix_beneficiaries_destination_account_id", "beneficiaries", ["destination_account_id"])
    op.add_column("transactions", sa.Column("request_fingerprint", sa.String(64)))
    op.add_column("transactions", sa.Column("authorization_hash", sa.String(64)))
    op.create_table("otp_challenges",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("reference_hash", sa.String(64), nullable=False),
        sa.Column("identifier_hash", sa.String(64), nullable=False),
        sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE")),
        sa.Column("otp_hash", sa.String(64), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False),
        sa.Column("consumed_at", sa.DateTime(timezone=True)),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()))
    for column in ("reference_hash", "identifier_hash", "user_id", "expires_at"):
        op.create_index(f"ix_otp_challenges_{column}", "otp_challenges", [column], unique=column == "reference_hash")
    op.create_table("authorization_grants",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("token_hash", sa.String(64), nullable=False),
        sa.Column("scope", sa.String(32), nullable=False),
        sa.Column("binding", sa.String(64), nullable=False),
        sa.Column("credential_version", sa.String(64), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("consumed_at", sa.DateTime(timezone=True)),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()))
    for column in ("user_id", "token_hash", "scope", "expires_at"):
        op.create_index(f"ix_authorization_grants_{column}", "authorization_grants", [column], unique=column == "token_hash")
    op.create_table("security_throttles", sa.Column("key", sa.String(64), primary_key=True),
        sa.Column("window_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False))
    op.create_index("ix_security_throttles_window_start", "security_throttles", ["window_start"])


def downgrade():
    # A downgrade intentionally requires manual review: dropping consumed-token
    # history can re-enable credentials. Never destroy security state implicitly.
    raise RuntimeError("Security migration downgrade requires a reviewed backup/restore procedure")
