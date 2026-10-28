"""Role/permission catalogue synchronisation."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.roles import PERMISSION_DEFINITIONS, ROLE_DEFINITIONS
from app.models.user import Permission, Role


def sync_roles(db: Session) -> dict[str, int]:
    """Idempotently create/refresh the permission catalogue and roles."""
    permissions: dict[str, Permission] = {}
    created_permissions = 0
    for code, names in PERMISSION_DEFINITIONS.items():
        permission = db.scalar(select(Permission).where(Permission.code == code))
        if permission is None:
            permission = Permission(code=code, name_en=names["name_en"], name_ar=names["name_ar"])
            db.add(permission)
            db.flush()
            created_permissions += 1
        permissions[code] = permission

    created_roles = 0
    for code, definition in ROLE_DEFINITIONS.items():
        role = db.scalar(select(Role).where(Role.code == code))
        if role is None:
            role = Role(code=code, name_en=str(definition["name_en"]), name_ar=str(definition["name_ar"]))
            db.add(role)
            created_roles += 1
        role.permissions = [permissions[item] for item in definition["permissions"]]  # type: ignore[index]
    db.commit()
    return {
        "permissions_created": created_permissions,
        "permissions_total": len(permissions),
        "roles_created": created_roles,
        "roles_total": len(ROLE_DEFINITIONS),
    }
