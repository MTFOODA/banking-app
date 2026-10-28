"""Atomic optimistic branding writes, immutable history and safe raster storage."""
from __future__ import annotations

import hashlib
import io
import re
import warnings
import os
import tempfile
from pathlib import Path

from PIL import Image, UnidentifiedImageError
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import AppError
from app.models.branding import BrandingPublication, BrandingSettings
from app.schemas.branding import BrandingConfig, InternalAppearance, current_policy_config
from app.services.common import record_audit

MAX_IMAGE_BYTES = 2 * 1024 * 1024
MAX_IMAGE_PIXELS = 4_000_000
ASSET_NAME = re.compile(r"^[a-f0-9]{64}\.png$")
ASSET_FIELDS = ("logo_url", "dark_logo_url", "splash_image_url")


def state(db: Session, *, lock=False) -> BrandingSettings:
    # Handles fresh test fixtures / create_all installations as well as migration.
    db.execute(insert(BrandingSettings).values(id=1, revision=0).on_conflict_do_nothing())
    query = select(BrandingSettings).where(BrandingSettings.id == 1)
    if lock:
        query = query.with_for_update()
    return db.scalar(query.execution_options(populate_existing=True))


def public_config(db: Session) -> dict:
    row = db.get(BrandingSettings, 1)
    publication = db.get(BrandingPublication, row.active_version) if row and row.active_version else None
    return {"configuration_version": publication.version if publication else 0,
            "config": current_policy_config(publication.config).model_dump(mode="json") if publication else BrandingConfig().model_dump(mode="json")}


def admin_config(db: Session) -> dict:
    row = state(db)
    result = {"revision": row.revision, "draft": current_policy_config(row.draft).model_dump(mode="json") if row.draft else None, **public_config(db)}
    db.commit()
    return result


def _locked(db, expected):
    row = state(db, lock=True)
    if row.revision != expected:
        raise AppError(code="branding_conflict", message="Branding changed in another session. Reload before saving.", status_code=409)
    return row


def asset_path(name: str) -> Path:
    if not ASSET_NAME.fullmatch(name):
        raise AppError(code="branding_asset_missing", message="Branding image not found.", status_code=404)
    root = (Path(settings.upload_dir) / "branding").resolve()
    path = root / name
    if path.is_symlink() or not path.is_file():
        raise AppError(code="branding_asset_missing", message="Branding image not found.", status_code=404)
    return path


def validate_assets(config: BrandingConfig):
    for field in ASSET_FIELDS:
        url = getattr(config, field)
        if url:
            asset_path(url.rsplit("/", 1)[-1])


def save_draft(db, actor, expected, config):
    config = BrandingConfig.model_validate(config.model_dump(mode="json"))
    validate_assets(config)
    row = _locked(db, expected)
    row.draft = config.model_dump(mode="json")
    row.revision += 1
    row.updated_by = actor.id
    record_audit(db, actor=actor, action="branding.draft_saved", entity_type="branding", details={"revision": row.revision})
    db.commit()
    return admin_config(db)


def publish(db, actor, expected):
    row = _locked(db, expected)
    if row.draft is None:
        raise AppError(code="branding_no_draft", message="Save a draft before publishing.", status_code=409)
    config = BrandingConfig.model_validate(row.draft)
    validate_assets(config)
    version = row.revision + 1
    db.add(BrandingPublication(version=version, config=config.model_dump(mode="json"), published_by=actor.id))
    db.flush()
    row.revision = version
    row.active_version = version
    row.updated_by = actor.id
    row.draft = None
    record_audit(db, actor=actor, action="branding.published", entity_type="branding", entity_id=str(version))
    db.commit()
    return admin_config(db)


def restore_draft(db, actor, expected, version=None, *, bank_code=None):
    if version is None:
        config = BrandingConfig()
    else:
        old = db.get(BrandingPublication, version)
        if old is None:
            raise AppError(code="branding_version_missing", message="Published version not found.", status_code=404)
        config = current_policy_config(old.config)
    if bank_code is not None:
        from app.services.bank_catalogue_data import BANK_ROWS
        if bank_code not in {row[0] for row in BANK_ROWS}:
            raise AppError(code='bank_unavailable',message='Unknown bank.',status_code=422)
        row=state(db)
        current=current_policy_config(row.draft or public_config(db)['config'])
        appearance=config.bank_overrides.get(bank_code) or InternalAppearance(**{
            key:getattr(config,key) for key in InternalAppearance.model_fields})
        current.bank_overrides={**current.bank_overrides,bank_code:appearance}
        config=current
    return save_draft(db, actor, expected, config)


def history(db, *, before=None):
    query = select(BrandingPublication).order_by(BrandingPublication.version.desc()).limit(50)
    if before is not None:
        query = query.where(BrandingPublication.version < before)
    return [{"version": p.version, "published_at": p.published_at, "published_by": p.published_by,
             "config": current_policy_config(p.config).model_dump(mode="json")} for p in db.scalars(query)]


def published_asset(db, name):
    url = "/branding/assets/" + name
    # Older publications remain readable to support offline cached configurations.
    predicates = [BrandingPublication.config[field].astext == url for field in ASSET_FIELDS]
    from sqlalchemy import or_
    if db.scalar(select(BrandingPublication.version).where(or_(*predicates)).limit(1)) is None:
        raise AppError(code="branding_asset_missing", message="Branding image not found.", status_code=404)
    return asset_path(name)


def store_image(db, actor, data: bytes, content_type: str) -> dict:
    if not data or len(data) > MAX_IMAGE_BYTES:
        raise AppError(code="branding_image_size", message="Images must be at most 2 MB.", status_code=413)
    if content_type not in {"image/png", "image/jpeg"}:
        raise AppError(code="branding_image_type", message="Use a PNG or JPEG image.", status_code=422)
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            with Image.open(io.BytesIO(data)) as image:
                expected = "PNG" if content_type == "image/png" else "JPEG"
                if image.format != expected or getattr(image, "n_frames", 1) != 1:
                    raise ValueError()
                width, height = image.size
                if min(width, height) < 16 or max(width, height) > 4096 or width * height > MAX_IMAGE_PIXELS:
                    raise ValueError()
                image.load()
                # Re-encode pixels, discarding metadata, trailing data and filenames.
                output = io.BytesIO()
                image.convert("RGBA").save(output, format="PNG")
                clean = output.getvalue()
                if len(clean) > MAX_IMAGE_BYTES:
                    raise ValueError()
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError, Image.DecompressionBombWarning) as exc:
        raise AppError(code="branding_invalid_image", message="Invalid image: use a single PNG/JPEG, 16–4096 pixels per side, at most 4 megapixels and 2 MB.", status_code=422) from exc
    digest = hashlib.sha256(clean).hexdigest()
    name = digest + ".png"
    root = Path(settings.upload_dir) / "branding"
    root.mkdir(parents=True, exist_ok=True)
    path = root / name
    # Same-filesystem replacement prevents partial images during concurrent uploads.
    with tempfile.NamedTemporaryFile(dir=root, suffix=".tmp", delete=False) as target:
        temporary = Path(target.name)
        target.write(clean)
    try:
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)
    record_audit(db, actor=actor, action="branding.asset_uploaded", entity_type="branding_asset", entity_id=digest,
                 details={"bytes": len(clean), "width": width, "height": height})
    db.commit()
    return {"url": "/branding/assets/" + name, "width": width, "height": height, "bytes": len(clean)}
