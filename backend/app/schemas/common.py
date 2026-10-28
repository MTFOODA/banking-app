"""Shared schema helpers: money serialisation, pagination and errors."""

from __future__ import annotations

from decimal import Decimal
from typing import Annotated, Generic, TypeVar

from pydantic import BaseModel, ConfigDict, Field, PlainSerializer

T = TypeVar("T")


def _serialize_money(value: Decimal) -> float:
    return float(value.quantize(Decimal("0.01")))


# Money is stored as PostgreSQL NUMERIC and exposed as a JSON number with 2dp.
Money = Annotated[
    Decimal,
    PlainSerializer(_serialize_money, return_type=float, when_used="json"),
]

MoneyOrNone = Annotated[
    Decimal | None,
    PlainSerializer(
        lambda value: None if value is None else _serialize_money(value),
        return_type=float | None,
        when_used="json",
    ),
]


class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class Page(BaseModel, Generic[T]):
    items: list[T]
    page: int = Field(ge=1)
    page_size: int = Field(ge=1)
    total: int = Field(ge=0)
    has_next: bool

    @classmethod
    def build(cls, items: list[T], *, page: int, page_size: int, total: int) -> "Page[T]":
        return cls(
            items=items,
            page=page,
            page_size=page_size,
            total=total,
            has_next=page * page_size < total,
        )


class MessageResponse(BaseModel):
    message: str


class ErrorDetail(BaseModel):
    code: str
    message: str
