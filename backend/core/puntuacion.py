"""Version 2 personal scoring rules; no I/O or client-supplied point totals."""
from decimal import Decimal, ROUND_HALF_UP
from datetime import datetime, timedelta, timezone

FACTORES = {'Baja': Decimal('0.8'), 'Media': Decimal('1'), 'Alta': Decimal('1.2')}
CAMPOS = {1: 'inteligencia', 2: 'finanzas', 3: 'salud', 4: 'disciplina'}
PRECISION = Decimal('0.0001')


def hoy_bogota():
    return datetime.now(timezone(timedelta(hours=-5))).date()


def puntos(prioridad, pendientes, categorias, *, vencida=False):
    categorias = set(categorias)
    if not categorias or not categorias <= CAMPOS.keys():
        raise ValueError('Categorias invalidas')
    if pendientes < 1:
        raise ValueError('La tarea actual debe estar incluida en pendientes')
    total = (Decimal('-10') if vencida else Decimal('30') / pendientes) * FACTORES[prioridad]
    cuota = (total / len(categorias)).quantize(PRECISION, rounding=ROUND_HALF_UP)
    return {CAMPOS[c]: cuota for c in categorias}


def limitar(value):
    return max(Decimal('0'), min(Decimal('100'), value)).quantize(PRECISION)
