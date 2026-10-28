"""Discover catalogue: banking products and offers."""

from __future__ import annotations

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.models.content import BankingProduct, Offer
from app.models.user import User
from app.services.common import record_audit, utcnow


def public_products(db: Session) -> list[BankingProduct]:
    now = utcnow()
    return list(
        db.scalars(
            select(BankingProduct)
            .where(
                BankingProduct.is_active.is_(True),
                or_(BankingProduct.publish_at.is_(None), BankingProduct.publish_at <= now),
                or_(BankingProduct.expires_at.is_(None), BankingProduct.expires_at > now),
            )
            .order_by(BankingProduct.name_en)
        ).all()
    )


def all_products(db: Session) -> list[BankingProduct]:
    return list(db.scalars(select(BankingProduct).order_by(BankingProduct.created_at.desc())).all())


def create_product(db: Session, actor: User, payload: dict) -> BankingProduct:
    if db.scalar(select(BankingProduct.id).where(BankingProduct.code == payload["code"])):
        raise AppError(
            code="product_code_exists",
            message="A product with this code already exists.",
            status_code=409,
        )
    product = BankingProduct(**payload)
    db.add(product)
    db.flush()
    record_audit(
        db,
        actor=actor,
        action="product.created",
        entity_type="banking_product",
        entity_id=product.id,
        details={"code": product.code},
    )
    db.commit()
    db.refresh(product)
    return product


def public_offers(db: Session) -> list[Offer]:
    now = utcnow()
    return list(
        db.scalars(
            select(Offer)
            .where(
                Offer.status == "published",
                or_(Offer.start_at.is_(None), Offer.start_at <= now),
                or_(Offer.end_at.is_(None), Offer.end_at > now),
            )
            .order_by(Offer.is_featured.desc(), Offer.display_order, Offer.created_at.desc())
        ).all()
    )


def all_offers(db: Session) -> list[Offer]:
    return list(db.scalars(select(Offer).order_by(Offer.created_at.desc())).all())


def create_offer(db: Session, actor: User, payload: dict) -> Offer:
    offer = Offer(**payload)
    db.add(offer)
    db.flush()
    record_audit(
        db,
        actor=actor,
        action="offer.created",
        entity_type="offer",
        entity_id=offer.id,
        details={"status": offer.status},
    )
    db.commit()
    db.refresh(offer)
    return offer
