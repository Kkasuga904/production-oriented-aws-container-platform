from fastapi.testclient import TestClient

from main import app


client = TestClient(app)


def test_health() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_ready_fails_closed_without_secret(monkeypatch) -> None:
    monkeypatch.delenv("DB_SECRET_JSON", raising=False)
    response = client.get("/ready")
    assert response.status_code == 503
    assert response.json() == {"detail": "database unavailable"}


def test_database_config_defaults_to_tls(monkeypatch) -> None:
    monkeypatch.setenv("DB_SECRET_JSON", '{"username":"appadmin","password":"secret"}')
    monkeypatch.setenv("DB_HOST", "database.internal")
    monkeypatch.delenv("DB_SSLMODE", raising=False)

    from main import database_config

    config = database_config()
    assert config["sslmode"] == "require"
    assert config["host"] == "database.internal"
