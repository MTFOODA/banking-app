import copy
import io
import pytest
from PIL import Image
from sqlalchemy import select, func
from app.models.branding import BrandingPublication, BrandingSettings
from app.models.user import AuditLog
from app.schemas.branding import BrandingConfig
from tests.test_admin_workflow import staff  # existing real RBAC/login fixture
from tests.test_security_flows import headers

API = "/api/v1"


@pytest.fixture(autouse=True)
def upload_storage(tmp_path, monkeypatch):
    from app.core.config import settings
    monkeypatch.setattr(settings, "upload_dir", tmp_path)


def draft(client, staff, **changes):
    current = client.get(API + "/admin/branding", headers=staff).json()
    config = copy.deepcopy(current["draft"] or current["config"])
    for key, value in changes.items():
        if key in ("light", "dark"):
            config[key].update(value)
        else:
            config[key] = value
    return client.patch(API + "/admin/branding/draft", headers=staff,
                      json={"expected_revision": current["revision"], "config": config})


def publish(client, staff, revision):
    return client.post(API + "/admin/branding/publish", headers=staff, json={"expected_revision": revision})


def image_bytes():
    output = io.BytesIO()
    Image.new("RGBA", (48, 32), (20, 90, 60, 255)).save(output, "PNG")
    return output.getvalue()


def test_default_draft_publish_history_rollback(client, staff, db_session):
    assert client.get(API + "/admin/branding", headers=staff).headers["cache-control"] == "no-store"
    public = client.get(API + "/branding").json()
    assert public["configuration_version"] == 0
    assert public["config"] == BrandingConfig().model_dump()
    result = draft(client, staff, application_name="Fictional QA Brand")
    assert result.status_code == 200
    revision = result.json()["revision"]
    assert client.get(API + "/branding").json() == public
    assert client.get(API + "/branding?known_version=0").json()["unchanged"] is True
    result = publish(client, staff, revision)
    assert result.status_code == 200
    first = result.json()["configuration_version"]
    assert result.json()["draft"] is None
    assert client.get(API + "/branding").json()["config"]["application_name"] == "Fictional QA Brand"
    assert client.get(API + f"/branding?known_version={first}").json()["unchanged"]
    defaults = client.post(API + "/admin/branding/defaults", headers=staff, json={"expected_revision": result.json()["revision"]})
    assert defaults.status_code == 200
    assert client.get(API + "/branding").json()["configuration_version"] == first
    reset = publish(client, staff, defaults.json()["revision"]).json()
    assert reset["config"] == public["config"]
    old = client.post(API + f"/admin/branding/history/{first}/restore", headers=staff,
                      json={"expected_revision": reset["revision"]})
    restored = publish(client, staff, old.json()["revision"]).json()
    assert restored["configuration_version"] > reset["configuration_version"]
    assert restored["config"]["application_name"] == "Fictional QA Brand"
    history = client.get(API + "/admin/branding/history", headers=staff).json()
    assert len(history) == 3
    assert len(client.get(API + f"/admin/branding/history?before={history[0]['version']}", headers=staff).json()) == 2
    assert db_session.scalar(select(func.count()).select_from(AuditLog).where(AuditLog.action == "branding.published")) == 3
    assert set(client.get(API + "/branding").json()) == {"configuration_version", "config"}


def test_conflicting_writes_and_no_draft(client, staff, db_session):
    current = client.get(API + "/admin/branding", headers=staff).json()
    assert publish(client, staff, current["revision"]).status_code == 409
    result = draft(client, staff)
    assert publish(client, staff, current["revision"]).status_code == 409
    assert publish(client, staff, result.json()["revision"]).status_code == 200
    assert publish(client, staff, result.json()["revision"]).status_code == 409
    assert db_session.scalar(select(func.count()).select_from(BrandingPublication)) == 1
    assert client.post(API + "/admin/branding/history/999/restore", headers=staff,
                       json={"expected_revision": 2}).status_code == 404


@pytest.mark.parametrize("changes", [
    {"logo_url": "https://evil.example/logo.svg"}, {"logo_url": "/branding/assets/../../secret"},
    {"logo_url": "data:image/png;base64,AAA"}, {"primary_font": "Untrusted"},
    {"font_size_scale": 2}, {"heading_font_weight": 900}, {"application_name": " "},
    {"application_name": "Spoof\u202e"}, {"theme_mode": "invalid"}, {"unknown": "value"},
    {"light": {"primary": "red"}}, {"dark": {"text_primary": "#000000"}},
    {"light": {"button_background": "#FFFFFF"}}, {"light": {"text_secondary": "#FFFFFF"}},
    {"light": {"primary": "#FFFFFF"}}, {"dark": {"error": "#0B1F19"}},
])
def test_invalid_configuration_rejected(client, staff, changes):
    assert draft(client, staff, **changes).status_code == 422
    assert client.get(API + "/branding").json()["configuration_version"] == 0


def test_uploaded_assets_private_until_publish_and_preserved_for_history(client, staff, db_session):
    result = client.post(API + "/admin/branding/assets", headers=staff, files={"file": ("unsafe-name.svg", image_bytes(), "image/png")})
    assert result.status_code == 201
    url = result.json()["url"]
    assert url.endswith(".png")
    assert client.get(API + url).status_code == 404
    assert client.get(API + "/admin" + url, headers=staff).status_code == 200
    saved = draft(client, staff, logo_url=url, dark_logo_url=url, splash_image_url=url)
    assert client.get(API + url).status_code == 404
    assert publish(client, staff, saved.json()["revision"]).status_code == 200
    response = client.get(API + url)
    assert response.status_code == 200
    assert "immutable" in response.headers["cache-control"]
    assert response.headers["content-type"] == "image/png"


@pytest.mark.parametrize("data,mime,status", [
    (b"<svg onload='x'/>", "image/svg+xml", 422), (b"fake", "image/png", 422),
    (b"x" * (2 * 1024 * 1024 + 1), "image/png", 413), (b"", "image/png", 413),
], ids=["svg", "corrupt", "oversize", "empty"])
def test_failed_uploads_preserve_configuration(client, staff, data, mime, status):
    before = client.get(API + "/branding").json()
    assert client.post(API + "/admin/branding/assets", headers=staff, files={"file": ("logo.png", data, mime)}).status_code == status
    assert client.get(API + "/branding").json() == before


def test_missing_asset_rejected_on_save_and_publish(client, staff):
    assert draft(client, staff, logo_url="/branding/assets/" + "a" * 64 + ".png").status_code == 404
    result = client.post(API + "/admin/branding/assets", headers=staff, files={"file": ("logo.png", image_bytes(), "image/png")}).json()
    saved = draft(client, staff, logo_url=result["url"]).json()
    from app.services.branding_service import asset_path
    asset_path(result["url"].split("/")[-1]).unlink()
    assert publish(client, staff, saved["revision"]).status_code == 404
    assert client.get(API + "/branding").json()["configuration_version"] == 0


@pytest.mark.parametrize("endpoint,method", [
    ("", "get"), ("/draft", "patch"), ("/publish", "post"), ("/defaults", "post"),
    ("/history", "get"), ("/history/1/restore", "post"), ("/assets", "post"),
    ("/assets/" + "a" * 64 + ".png", "get"),
])
def test_unauthorized_and_customer_denied(client, endpoint, method):
    target = API + "/admin/branding" + endpoint
    call = getattr(client, method)
    assert call(target).status_code == 401
    assert call(target, headers=headers(client)).status_code == 403


def test_publish_rollback_keeps_previous_active(client, staff, db_session, monkeypatch):
    first = draft(client, staff, application_name="First").json()
    assert publish(client, staff, first["revision"]).status_code == 200
    second = draft(client, staff, application_name="Second").json()
    from app.services import branding_service
    original = branding_service.record_audit
    def fail(*args, **kwargs):
        raise RuntimeError("Injected publication failure")
    monkeypatch.setattr(branding_service, "record_audit", fail)
    with pytest.raises(RuntimeError):
        publish(client, staff, second["revision"])
    monkeypatch.setattr(branding_service, "record_audit", original)
    assert client.get(API + "/branding").json()["config"]["application_name"] == "First"


def test_upload_body_limit_before_multipart_parsing(client, staff):
    assert client.post(API + "/admin/branding/assets", headers=staff,
                       content=b"x" * (3 * 1024 * 1024)).status_code == 413


def test_staff_without_content_permission_is_denied(client, staff, db_session):
    from app.models.user import User
    actor=db_session.scalar(select(User).where(User.login_identifier_masked=='EMP-***QA'))
    actor.roles=[];db_session.commit()
    assert client.get(API + "/admin/branding", headers=staff).status_code == 403
    assert client.post(API + "/admin/branding/publish", headers=staff,json={'expected_revision':0}).status_code == 403
