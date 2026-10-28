"""initial schema

Revision ID: 6c3fc325c841
Revises:
Create Date: 2026-10-24 19:29:20.052305

This is the empty baseline revision that is already recorded in the
`faisal_bank` database (`alembic_version.version_num = '6c3fc325c841'`).
It is intentionally a no-op: the business schema is created by the corrective
migration that revises this revision (see the `recover business schema`
migration). Do not delete it while the database still reports it as applied.
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "6c3fc325c841"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
