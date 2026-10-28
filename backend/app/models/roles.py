"""Role and permission catalogue seeded into PostgreSQL.

Administrators are never created with a hardcoded password: the demo bootstrap
reads DEMO_ADMIN_EMPLOYEE_NUMBER / DEMO_ADMIN_INITIAL_PASSWORD from the
environment (see scripts/setup_backend.ps1 and README).
"""

from __future__ import annotations

ROLE_SUPER_ADMIN = "super_admin"
ROLE_CUSTOMER_SERVICE = "customer_service"
ROLE_ACCOUNT_OPERATIONS = "account_operations"
ROLE_CARD_OPERATIONS = "card_operations"
ROLE_CONTENT_MANAGER = "content_manager"
ROLE_COMPLIANCE_REVIEWER = "compliance_reviewer"
ROLE_AUDITOR = "auditor"

PERMISSION_DEFINITIONS: dict[str, dict[str, str]] = {
    "admin.dashboard.view": {"name_en": "View dashboard", "name_ar": "عرض لوحة المعلومات"},
    "admin.customers.view": {"name_en": "View customers", "name_ar": "عرض العملاء"},
    "admin.requests.view": {"name_en": "View requests", "name_ar": "عرض الطلبات"},
    "admin.requests.decide": {"name_en": "Decide requests", "name_ar": "اتخاذ قرار بشأن الطلبات"},
    "admin.requests.assign": {"name_en": "Assign reviewers", "name_ar": "تعيين المراجعين"},
    "admin.requests.request_information": {
        "name_en": "Request more information",
        "name_ar": "طلب معلومات إضافية",
    },
    "admin.cards.review": {"name_en": "Review card operations", "name_ar": "مراجعة عمليات البطاقات"},
    "admin.content.manage": {"name_en": "Manage content", "name_ar": "إدارة المحتوى"},
    "admin.products.manage": {"name_en": "Manage products", "name_ar": "إدارة المنتجات"},
    "admin.audit.view": {"name_en": "View audit log", "name_ar": "عرض سجل التدقيق"},
    "admin.roles.manage": {"name_en": "Manage roles", "name_ar": "إدارة الأدوار"},
}

ROLE_DEFINITIONS: dict[str, dict[str, object]] = {
    ROLE_SUPER_ADMIN: {
        "name_en": "Super Administrator",
        "name_ar": "مدير النظام",
        "permissions": list(PERMISSION_DEFINITIONS.keys()),
    },
    ROLE_CUSTOMER_SERVICE: {
        "name_en": "Customer Service",
        "name_ar": "خدمة العملاء",
        "permissions": [
            "admin.dashboard.view",
            "admin.customers.view",
            "admin.requests.view",
            "admin.requests.assign",
            "admin.requests.request_information",
        ],
    },
    ROLE_ACCOUNT_OPERATIONS: {
        "name_en": "Account Operations",
        "name_ar": "عمليات الحسابات",
        "permissions": [
            "admin.dashboard.view",
            "admin.customers.view",
            "admin.requests.view",
            "admin.requests.decide",
            "admin.requests.assign",
            "admin.requests.request_information",
        ],
    },
    ROLE_CARD_OPERATIONS: {
        "name_en": "Card Operations",
        "name_ar": "عمليات البطاقات",
        "permissions": [
            "admin.dashboard.view",
            "admin.customers.view",
            "admin.requests.view",
            "admin.requests.decide",
            "admin.requests.request_information",
            "admin.cards.review",
        ],
    },
    ROLE_CONTENT_MANAGER: {
        "name_en": "Content Manager",
        "name_ar": "مدير المحتوى",
        "permissions": [
            "admin.dashboard.view",
            "admin.content.manage",
            "admin.products.manage",
        ],
    },
    ROLE_COMPLIANCE_REVIEWER: {
        "name_en": "Compliance Reviewer",
        "name_ar": "مراجع الالتزام",
        "permissions": [
            "admin.dashboard.view",
            "admin.customers.view",
            "admin.requests.view",
            "admin.requests.decide",
            "admin.audit.view",
        ],
    },
    ROLE_AUDITOR: {
        "name_en": "Read-only Auditor",
        "name_ar": "مراجع للقراءة فقط",
        "permissions": [
            "admin.dashboard.view",
            "admin.requests.view",
            "admin.audit.view",
            "admin.customers.view",
        ],
    },
}

# Demo staff accounts created by `python -m app.cli bootstrap_admin` use the
# super administrator role by default.
DEFAULT_STAFF_ROLE = ROLE_SUPER_ADMIN
