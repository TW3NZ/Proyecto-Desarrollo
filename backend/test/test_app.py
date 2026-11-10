"""Tests for the avatar endpoint, without real OpenAI requests."""
import base64
import io
from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest
from fastapi.testclient import TestClient
from PIL import Image

from backend import app as api


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("AVATAR_SERVICE_TOKEN", "a" * 24)
    return TestClient(api.app)


def photo():
    output = io.BytesIO()
    Image.new("RGB", (12, 12), "blue").save(output, "PNG")
    return base64.b64encode(output.getvalue()).decode()


def send(client, image=None, **extra):
    return client.post("/avatar/suggest", headers={"Authorization": "Bearer " + "a" * 24},
                       json={"image_base64": image or photo(), "character_type": "mujer", **extra})


def test_unauthorized_never_calls_openai(client, monkeypatch):
    mock = AsyncMock()
    monkeypatch.setattr(api, "suggest", mock)
    assert client.post("/avatar/suggest", json={}).status_code == 401
    mock.assert_not_called()


def test_bad_input_is_not_echoed_or_sent(client, monkeypatch):
    mock = AsyncMock()
    monkeypatch.setattr(api, "suggest", mock)
    for image in ["private-not-base64", base64.b64encode(b"not an image").decode()]:
        response = send(client, image)
        assert response.status_code == 422
        assert image not in response.text
    assert send(client, unexpected="value").status_code == 422
    assert send(client, base64.b64encode(b"x" * (api.MAX_IMAGE + 1)).decode()).status_code == 413
    mock.assert_not_called()


def test_valid_photo_normalized_and_attributes_returned(client, monkeypatch):
    result = api.Suggestion(status="ok", skin="brown", hair="black", shirt=None,
                            trousers=None, hairstyle="rizado", eyes="almond",
                            nose="straight", mouth="smile")
    mock = AsyncMock(return_value=result)
    monkeypatch.setattr(api, "suggest", mock)
    response = send(client)
    assert response.status_code == 200
    assert response.json() == result.model_dump()
    encoded, character = mock.call_args.args
    assert character == "mujer"
    with Image.open(io.BytesIO(base64.b64decode(encoded))) as normalized:
        assert normalized.format == "JPEG"
        assert not normalized.getexif()


def test_openai_contract(client, monkeypatch):
    result = api.Suggestion(status="no_face", **{name: None for name in
        ["skin", "hair", "shirt", "trousers", "hairstyle", "eyes", "nose", "mouth"]})
    parse = AsyncMock(return_value=SimpleNamespace(output_parsed=result))
    fake = AsyncMock()
    fake.__aenter__.return_value = SimpleNamespace(responses=SimpleNamespace(parse=parse))
    monkeypatch.setenv("OPENAI_API_KEY", "test-only")
    monkeypatch.setattr(api, "AsyncOpenAI", lambda **kwargs: fake)
    assert send(client).json()["status"] == "no_face"
    kwargs = parse.call_args.kwargs
    assert kwargs["store"] is False
    assert kwargs["text_format"] is api.Suggestion
    assert kwargs["input"][0]["content"][1]["image_url"].startswith("data:image/jpeg;base64,")


def test_missing_key_and_refusal(client, monkeypatch):
    monkeypatch.delenv("OPENAI_API_KEY", raising=False)
    assert send(client).status_code == 503
    monkeypatch.setenv("OPENAI_API_KEY", "test-only")
    fake = AsyncMock()
    fake.__aenter__.return_value = SimpleNamespace(responses=SimpleNamespace(
        parse=AsyncMock(return_value=SimpleNamespace(output_parsed=None))))
    monkeypatch.setattr(api, "AsyncOpenAI", lambda **kwargs: fake)
    assert send(client).status_code == 422
