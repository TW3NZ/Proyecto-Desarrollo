from decimal import Decimal
import pytest
from backend.core.puntuacion import puntos, limitar


@pytest.mark.parametrize('n,expected', [(1,30),(2,15),(5,6),(10,3),(30,1)])
def test_fewer_pending_tasks_have_more_weight(n, expected):
    assert puntos('Media', n, [1]) == {'inteligencia': Decimal(expected)}


def test_categories_split_and_priorities():
    assert puntos('Alta', 1, [1,2,3]) == dict.fromkeys(['inteligencia','finanzas','salud'], Decimal(12))
    assert puntos('Baja', 2, [4]) == {'disciplina': Decimal(12)}
    assert puntos('Media', 1, [1,1]) == {'inteligencia': Decimal(30)}


def test_expiry_penalty_and_bounds():
    assert puntos('Media', 5, [1,2], vencida=True) == {'inteligencia': Decimal(-5), 'finanzas': Decimal(-5)}
    assert limitar(Decimal(105)) == 100
    assert limitar(Decimal(-5)) == 0


@pytest.mark.parametrize('n,categories', [(0,[1]),(1,[]),(1,[5])])
def test_invalid_inputs_rejected(n, categories):
    with pytest.raises(ValueError):
        puntos('Media', n, categories)
