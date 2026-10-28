"""Public active configuration; all draft/edit/upload APIs enforce existing RBAC."""
from fastapi import APIRouter, Depends, File, Query, Response, UploadFile, Request, HTTPException
from fastapi.routing import APIRoute
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.dependencies.auth import require_permissions
from app.models.user import User
from app.schemas.branding import BrandingDraftRequest, BrandingVersionRequest, BrandingRestoreRequest
from app.services import branding_service as service
from app.services.security_service import throttle

class BoundedBrandingRoute(APIRoute):
    """Bound the multipart body before parsing, including chunked requests."""
    def get_route_handler(self):
        original = super().get_route_handler()
        async def bounded(request: Request):
            if request.method == "POST" and request.url.path.endswith("/admin/branding/assets"):
                limit = service.MAX_IMAGE_BYTES + 64 * 1024
                length = request.headers.get("content-length")
                if length and (not length.isdigit() or int(length) > limit):
                    raise HTTPException(413, "Branding upload exceeds 2 MB plus multipart overhead.")
                receive = request._receive
                received = 0
                async def limited_receive():
                    nonlocal received
                    message = await receive()
                    received += len(message.get("body", b""))
                    if received > limit:
                        raise HTTPException(413, "Branding upload exceeds the allowed size.")
                    return message
                request._receive = limited_receive
            response = await original(request)
            if "/admin/branding" in request.url.path:
                response.headers["Cache-Control"] = "no-store"
            return response
        return bounded


router = APIRouter(tags=["Branding"], route_class=BoundedBrandingRoute)
admin = Depends(require_permissions("admin.content.manage"))


@router.get("/branding")
def published(response: Response, known_version: int | None = Query(None, ge=0), db: Session = Depends(get_db)):
    result = service.public_config(db)
    response.headers["Cache-Control"] = "no-cache"
    if known_version == result["configuration_version"]:
        return {"configuration_version": known_version, "unchanged": True}
    return result


@router.get("/branding/assets/{name}")
def public_asset(name: str, db: Session = Depends(get_db)):
    return FileResponse(service.published_asset(db, name), media_type="image/png",
                        headers={"Cache-Control": "public, max-age=31536000, immutable"})


@router.get("/admin/branding")
def get_admin(user: User = admin, db: Session = Depends(get_db)):
    return service.admin_config(db)


@router.patch("/admin/branding/draft")
def save(payload: BrandingDraftRequest, user: User = admin, db: Session = Depends(get_db)):
    return service.save_draft(db, user, payload.expected_revision, payload.config)


@router.post("/admin/branding/publish")
def publish(payload: BrandingVersionRequest, user: User = admin, db: Session = Depends(get_db)):
    return service.publish(db, user, payload.expected_revision)


@router.post("/admin/branding/defaults")
def defaults(payload: BrandingRestoreRequest, user: User = admin, db: Session = Depends(get_db)):
    return service.restore_draft(db, user, payload.expected_revision, bank_code=payload.bank_code)


@router.get("/admin/branding/history")
def history(before: int | None = Query(None, gt=0), user: User = admin, db: Session = Depends(get_db)):
    return service.history(db, before=before)


@router.post("/admin/branding/history/{version}/restore")
def restore(version: int, payload: BrandingRestoreRequest, user: User = admin, db: Session = Depends(get_db)):
    return service.restore_draft(db, user, payload.expected_revision, version, bank_code=payload.bank_code)


@router.post("/admin/branding/assets", status_code=201)
async def upload(file: UploadFile = File(...), user: User = admin, db: Session = Depends(get_db)):
    try:
        from app.core.exceptions import AppError
        raise AppError(code="fixed_application_identity", message="Banking App name and logo can only change in an application release.", status_code=403)
    finally:
        await file.close()


@router.get("/admin/branding/assets/{name}")
def private_asset(name: str, user: User = admin):
    return FileResponse(service.asset_path(name), media_type="image/png", headers={"Cache-Control": "private, no-store"})
