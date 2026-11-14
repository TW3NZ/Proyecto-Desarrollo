from datetime import date
from typing import Literal
from pydantic import BaseModel, ConfigDict, Field, field_validator


class CrearEquipo(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    nombre: str = Field(min_length=1, max_length=50)


class UnirseEquipo(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    codigo: str = Field(pattern=r'^[A-Z0-9]{8}$')

    @field_validator('codigo', mode='before')
    @classmethod
    def mayusculas(cls, value):
        return value.strip().upper() if isinstance(value, str) else value


class CrearProyecto(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    nombre: str = Field(min_length=1, max_length=100)
    meta: str = Field(default='', max_length=500)
    categoria: Literal[1,2,3,4] = 4


class AsignarTarea(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    titulo: str = Field(min_length=1, max_length=150)
    descripcion: str = Field(default='', max_length=2000)
    prioridad: Literal['Baja','Media','Alta'] = 'Media'
    fechaLimite: date | None = None
    categorias: set[Literal[1,2,3,4]] = Field(min_length=1)
    participantes: set[int] = Field(min_length=1, max_length=100)
