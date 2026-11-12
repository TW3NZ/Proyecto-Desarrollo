"""Load server-only configuration independently of the working directory."""
from pathlib import Path

from dotenv import load_dotenv


def load_settings(directory: Path | None = None) -> None:
    directory = directory or Path(__file__).resolve().parents[1]
    # A local backend/.env is authoritative: unrelated machine credentials must
    # not silently replace the project's key. Deployments can omit this file.
    load_dotenv(directory / ".env", override=True, encoding="utf-8-sig")
