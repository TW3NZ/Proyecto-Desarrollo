"""Validated, account-owned appearance and aura preferences."""
from typing import Literal
from pydantic import BaseModel, ConfigDict, Field, model_validator


class AvatarConfig(BaseModel):
    model_config = ConfigDict(extra='forbid')
    version: Literal[1] = 1
    skin: Literal['original', 'light', 'golden', 'brown', 'deep'] = 'original'
    hair: Literal['original', 'black', 'blond', 'copper', 'silver'] = 'original'
    shirt: str = Field(default='original', pattern=r'^(original|blue|plum|coral|cream|#[0-9a-fA-F]{6})$')
    trousers: str = Field(default='original', pattern=r'^(original|charcoal|sand|olive|denim|#[0-9a-fA-F]{6})$')
    outfit: Literal['ninguno', 'developerSkin'] = 'ninguno'
    characterType: Literal['hombre', 'mujer'] = 'hombre'
    hairstyle: Literal['original', 'corto', 'rizado', 'recogido'] = 'original'
    eyes: Literal['original', 'almond', 'round'] = 'original'
    nose: Literal['original', 'straight', 'round'] = 'original'
    mouth: Literal['original', 'smile', 'neutral'] = 'original'
    eyeColor: str = Field(default='original', pattern=r'^(original|#[0-9a-fA-F]{6})$')
    motion: bool = True
    bodyWidth: float = Field(default=1, ge=0.8, le=1.5)
    bodyHeight: float = Field(default=1, ge=0.8, le=1)

    @model_validator(mode='after')
    def compatible_outfit(self):
        if self.characterType == 'mujer' and self.outfit == 'developerSkin':
            raise ValueError('Prenda no disponible para este personaje.')
        return self


class PreferenciasEstadisticas(BaseModel):
    model_config = ConfigDict(extra='forbid')
    inteligenciaActiva: bool = True
    finanzasActiva: bool = True
    saludActiva: bool = True
    disciplinaActiva: bool = True
