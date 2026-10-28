"""Domain enums shared by models, schemas and services.

Stored as short VARCHAR values (not native PG enums) so migrations stay simple
and the values remain readable in reports.
"""

from __future__ import annotations

from enum import StrEnum


class LoginType(StrEnum):
    CUSTOMER = "customer"
    STAFF = "staff"


class AccountType(StrEnum):
    CURRENT = "current"
    INVESTMENT = "investment"
    SAVINGS = "savings"


class AccountStatus(StrEnum):
    ACTIVE = "active"
    PENDING = "pending"
    FROZEN = "frozen"
    DORMANT = "dormant"
    CLOSED = "closed"


class CardKind(StrEnum):
    DEBIT = "debit"
    CREDIT = "credit"


class CardStatus(StrEnum):
    PENDING_ACTIVATION = "pending_activation"
    ACTIVE = "active"
    FROZEN = "frozen"
    LOST = "lost"
    STOLEN = "stolen"
    BLOCKED = "blocked"
    CANCELLED = "cancelled"
    EXPIRED = "expired"


class TransactionType(StrEnum):
    TRANSFER = "transfer"
    DEPOSIT = "deposit"
    WITHDRAWAL = "withdrawal"
    PURCHASE = "purchase"
    BILL_PAYMENT = "bill_payment"
    CARD_REPAYMENT = "card_repayment"
    FEE = "fee"
    ADJUSTMENT = "adjustment"
    SALARY = "salary"


class TransactionDirection(StrEnum):
    DEBIT = "debit"
    CREDIT = "credit"


class TransactionStatus(StrEnum):
    POSTED = "posted"
    PENDING = "pending"
    FAILED = "failed"
    REVERSED = "reversed"


class RepaymentMode(StrEnum):
    FULL = "full"
    STATEMENT = "statement"
    MINIMUM = "minimum"
    CUSTOM = "custom"


class RepaymentStatus(StrEnum):
    PENDING = "pending"
    SIMULATED_COMPLETED = "simulated_completed"
    FAILED = "failed"
    REVERSED = "reversed"


class RequestType(StrEnum):
    ACCOUNT_OPEN = "account_open"
    ACCOUNT_CLOSE = "account_close"
    CARD_ISSUE = "card_issue"
    CARD_REPLACEMENT = "card_replacement"
    CARD_RENEWAL = "card_renewal"
    CARD_CANCELLATION = "card_cancellation"
    CARD_LIMIT_INCREASE = "card_limit_increase"
    CARD_LIMIT_DECREASE = "card_limit_decrease"
    PIN_RESET = "pin_reset"
    SUPPLEMENTARY_CARD = "supplementary_card"
    CREDIT_CARD_APPLICATION = "credit_card_application"
    INVESTMENT_PRODUCT = "investment_product"
    CUSTOMER_INFO_UPDATE = "customer_info_update"
    OTHER = "other"


class RequestStatus(StrEnum):
    DRAFT = "draft"
    SUBMITTED = "submitted"
    UNDER_REVIEW = "under_review"
    PENDING_CUSTOMER_INFO = "pending_customer_info"
    PENDING_APPROVAL = "pending_approval"
    APPROVED = "approved"
    REJECTED = "rejected"
    PROCESSING = "processing"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class NotificationCategory(StrEnum):
    TRANSACTION = "transaction"
    REQUEST_STATUS = "request_status"
    SECURITY = "security"
    ANNOUNCEMENT = "announcement"
    MAINTENANCE = "maintenance"
    OFFER = "offer"
    PRODUCT = "product"
    SYSTEM = "system"


class Priority(StrEnum):
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"


class AnnouncementStatus(StrEnum):
    DRAFT = "draft"
    SCHEDULED = "scheduled"
    PUBLISHED = "published"
    EXPIRED = "expired"
    ARCHIVED = "archived"


class AnnouncementCategory(StrEnum):
    ANNOUNCEMENT = "announcement"
    MAINTENANCE = "maintenance"
    SERVICE_INTERRUPTION = "service_interruption"
    SERVICE_RESTORED = "service_restored"
    OFFER = "offer"
    INVESTMENT = "investment"
    SECURITY = "security"
    CAMPAIGN = "campaign"


class AudienceType(StrEnum):
    ALL = "all"
    CUSTOMER_SEGMENT = "customer_segment"
    CUSTOMER = "customer"


class ProductType(StrEnum):
    INVESTMENT = "investment"
    SAVINGS = "savings"
    CERTIFICATE = "certificate"
    FINANCING = "financing"


class TicketStatus(StrEnum):
    OPEN = "open"
    PENDING = "pending"
    RESOLVED = "resolved"
    CLOSED = "closed"


class SupportSender(StrEnum):
    CUSTOMER = "customer"
    AGENT = "agent"


class PostingStatus(StrEnum):
    DRAFT = "draft"
    PUBLISHED = "published"
    ARCHIVED = "archived"


class RequestPriority(StrEnum):
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    URGENT = "urgent"
