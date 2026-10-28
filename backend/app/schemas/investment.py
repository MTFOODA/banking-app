import uuid
from decimal import Decimal
from typing import Literal
from pydantic import BaseModel, ConfigDict, Field, model_validator


class InvestmentAction(BaseModel):
    model_config = ConfigDict(extra='forbid')
    action: Literal['subscribe', 'redeem']
    product_id: uuid.UUID | None = None
    account_id: uuid.UUID | None = None
    holding_id: uuid.UUID | None = None
    amount: Decimal | None = Field(default=None, gt=0, max_digits=18, decimal_places=2)

    @model_validator(mode='after')
    def valid_action(self):
        if self.action == 'subscribe':
            if not self.product_id or not self.account_id or not self.amount or self.holding_id:
                raise ValueError('Product, account and amount are required for subscription')
        elif not self.holding_id or self.product_id or self.account_id or self.amount is not None:
            raise ValueError('Only a holding identifier is required for redemption')
        return self


class InvestmentExecute(InvestmentAction):
    authorization_token: str = Field(min_length=20, max_length=128)
