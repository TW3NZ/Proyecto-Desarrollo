import os

from backend.utils.settings import load_settings


def test_loads_backend_env_from_any_working_directory(tmp_path, monkeypatch):
    directory = tmp_path / "backend"
    directory.mkdir()
    (directory / ".env").write_text('OPENAI_API_KEY="test-backend"\n', encoding="utf-8-sig")
    (tmp_path / ".env").write_text("OPENAI_API_KEY=test-root\nAVATAR_SERVICE_TOKEN=test-token\n")
    monkeypatch.delenv("OPENAI_API_KEY", raising=False)
    monkeypatch.delenv("AVATAR_SERVICE_TOKEN", raising=False)
    monkeypatch.chdir(directory)
    load_settings(directory)
    assert os.environ["OPENAI_API_KEY"] == "test-backend"
    # There is one project configuration file: backend/.env, never root/.env.
    assert "AVATAR_SERVICE_TOKEN" not in os.environ


def test_backend_file_overrides_unrelated_machine_key(tmp_path, monkeypatch):
    (tmp_path / ".env").write_text("OPENAI_API_KEY=test-file\n")
    monkeypatch.setenv("OPENAI_API_KEY", "test-process")
    load_settings(tmp_path)
    assert os.environ["OPENAI_API_KEY"] == "test-file"


def test_process_environment_works_without_files(tmp_path, monkeypatch):
    directory = tmp_path / "backend"
    directory.mkdir()
    monkeypatch.setenv("OPENAI_API_KEY", "test-process")
    load_settings(directory)
    assert os.environ["OPENAI_API_KEY"] == "test-process"
