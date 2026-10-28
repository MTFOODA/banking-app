import pytest
from app.core.config import Settings


def production(**overrides):
    values = dict(environment="production", debug=False,
        database_url="postgresql+psycopg://bank:private@localhost/bank_live",
        jwt_secret="a" * 48, login_identifier_pepper="b" * 48,
        otp_provider="smtp", otp_dev_expose=False, smtp_host="smtp.example.com", smtp_from="bank@example.com")
    values.update(overrides)
    return Settings(_env_file=None, **values)


@pytest.mark.parametrize("override", [
    {"jwt_secret": "dev-only-faisal-app-super-secret-key-change-me"},
    {"login_identifier_pepper": "dev-only-faisal-app-pepper-change-me"},
    {"otp_provider": "development"}, {"otp_dev_expose": True}, {"smtp_host": ""},
])
def test_production_refuses_demo_secrets_and_delivery(override):
    with pytest.raises(RuntimeError): production(**override).validate_production_secrets()


def test_production_accepts_explicit_non_demo_configuration():
    production().validate_production_secrets()
