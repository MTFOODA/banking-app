"""Explicit delivery boundary. Only a local development adapter exists."""
from dataclasses import dataclass
from typing import Protocol
import uuid
from app.core.config import settings
from app.core.exceptions import AppError

@dataclass(frozen=True)
class DeliveryReceipt:
    status: str
    reference: str

class TransferDeliveryProvider(Protocol):
    def simulate(self, channel: str) -> DeliveryReceipt: ...

class DevelopmentTransferProvider:
    def simulate(self, channel: str) -> DeliveryReceipt:
        return DeliveryReceipt('simulated_completed','SIM-'+uuid.uuid4().hex[:24].upper())

def available() -> bool:
    return settings.environment in {'development','test'} and settings.outbound_transfer_provider=='development'

def provider() -> TransferDeliveryProvider:
    if not available():
        raise AppError(code='transfer_provider_unavailable',message='Real outbound delivery is not configured.',status_code=503)
    return DevelopmentTransferProvider()
