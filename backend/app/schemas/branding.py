"""Strict, versioned and public-safe branding contract; no executable resources."""
from __future__ import annotations

import re
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

ASSET_PATTERN = r"^/branding/assets/[a-f0-9]{64}\.png$"
COLOR_KEYS = (
    "primary", "secondary", "accent", "background", "surface", "text_primary",
    "text_secondary", "error", "button_background", "button_text", "card", "border",
)


def contrast(a: str, b: str) -> float:
    def luminance(value):
        channels = [int(value[i:i + 2], 16) / 255 for i in (1, 3, 5)]
        linear = [c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4 for c in channels]
        return sum(c * w for c, w in zip(linear, (.2126, .7152, .0722)))
    x, y = sorted((luminance(a), luminance(b)))
    return (y + .05) / (x + .05)


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class BrandingColors(StrictModel):
    primary: str = "#075C46"
    secondary: str = "#0B795A"
    accent: str = "#C8A44D"
    background: str = "#F4F9F5"
    surface: str = "#FFFFFF"
    text_primary: str = "#172923"
    text_secondary: str = "#52635A"
    error: str = "#C83C42"
    button_background: str = "#075C46"
    button_text: str = "#FFFFFF"
    card: str = "#FFFFFF"
    border: str = "#E5EBE6"

    @field_validator(*COLOR_KEYS)
    @classmethod
    def valid_hex(cls, value):
        if not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
            raise ValueError("Use an opaque HEX color such as #075C46")
        return value.upper()

    @model_validator(mode="after")
    def accessible(self):
        for foreground in (self.text_primary, self.text_secondary, self.primary, self.error):
            for background in (self.background, self.surface, self.card):
                if contrast(foreground, background) < 4.5:
                    raise ValueError("Text contrast must be at least 4.5:1 on background, surface and cards")
        if contrast(self.button_text, self.button_background) < 4.5:
            raise ValueError("Button text contrast must be at least 4.5:1")
        return self


def dark_colors():
    return BrandingColors(
        primary="#58B394", secondary="#9FD7C2", accent="#D9B862", background="#0B1F19",
        surface="#0B1F19", text_primary="#F2F7F4", text_secondary="#9DB2A8",
        error="#F0737A", button_background="#58B394", button_text="#0B1F19",
        card="#123027", border="#24463A",
    )


class BrandingConfig(StrictModel):
    schema_version: Literal[1] = 1
    # Null means preserve the existing, localized presentation exactly.
    application_name: str | None = Field(default=None, min_length=1, max_length=40)
    application_short_name: str | None = Field(default=None, min_length=1, max_length=20)
    application_tagline: str | None = Field(default=None, max_length=100)
    welcome_message: str | None = Field(default=None, max_length=160)
    logo_url: str | None = None
    dark_logo_url: str | None = None
    splash_image_url: str | None = None
    custom_theme: bool = False
    light: BrandingColors = Field(default_factory=BrandingColors)
    dark: BrandingColors = Field(default_factory=dark_colors)
    primary_font: Literal["System", "NotoSans", "NotoSansArabic"] = "System"
    arabic_font: Literal["System", "NotoSansArabic"] = "System"
    english_font: Literal["System", "NotoSans"] = "System"
    font_size_scale: float = Field(default=1, ge=.9, le=1.15, allow_inf_nan=False)
    heading_font_weight: Literal[400, 500, 600, 700] = 700
    body_font_weight: Literal[400, 500, 600] = 400
    # 'user' preserves the current local/system theme selection.
    theme_mode: Literal["user", "light", "dark", "system"] = "user"

    @field_validator("logo_url", "dark_logo_url", "splash_image_url")
    @classmethod
    def local_asset(cls, value):
        if value is not None and not re.fullmatch(ASSET_PATTERN, value):
            raise ValueError("Only validated, uploaded branding images may be used")
        return value

    @field_validator("application_name", "application_short_name", "application_tagline", "welcome_message")
    @classmethod
    def plain_text(cls, value):
        if value is None:
            return None
        if value != value.strip() or any(ord(c) < 32 or c in "\u202a\u202b\u202c\u202d\u202e\u2066\u2067\u2068\u2069" for c in value):
            raise ValueError("Use plain text without control characters or surrounding spaces")
        return value


class BrandingVersionRequest(StrictModel):
    expected_revision: int = Field(ge=0)


class BrandingDraftRequest(BrandingVersionRequest):
    config: BrandingConfig
