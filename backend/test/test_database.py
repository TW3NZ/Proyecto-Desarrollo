from unittest.mock import Mock

from backend.database import db


def test_connector_uses_inline_ca_and_transactions(monkeypatch):
    values = dict(DB_HOST="example.invalid", DB_USER="test", DB_PASSWORD="test",
                  DB_NAME="test", DB_PORT="10472", DB_SSL_CA="inline-pem", DB_CONNECT_TIMEOUT="7")
    for key, value in values.items():
        monkeypatch.setenv(key, value)
    context = Mock()
    create_context = Mock(return_value=context)
    connect = Mock()
    monkeypatch.setattr(db.ssl, "create_default_context", create_context)
    monkeypatch.setattr(db.pymysql, "connect", connect)
    assert db.get_connection() is connect.return_value
    create_context.assert_called_once_with(cadata="inline-pem")
    kwargs = connect.call_args.kwargs
    assert kwargs["ssl"] is context
    assert kwargs["autocommit"] is False
    assert kwargs["port"] == 10472
    assert kwargs["connect_timeout"] == 7
