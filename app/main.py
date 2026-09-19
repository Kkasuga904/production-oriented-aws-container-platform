import json
import os
from contextlib import closing

import psycopg
from fastapi import FastAPI, HTTPException


app = FastAPI(title="platform-demo-api", version="1.0.0")


def database_config() -> dict[str, object]:
    raw_secret = os.environ.get("DB_SECRET_JSON")
    if not raw_secret:
        raise RuntimeError("DB_SECRET_JSON is not configured")

    secret = json.loads(raw_secret)
    return {
        "host": os.environ["DB_HOST"],
        "port": int(os.environ.get("DB_PORT", "5432")),
        "dbname": os.environ.get("DB_NAME", "app"),
        "user": secret["username"],
        "password": secret["password"],
        "connect_timeout": 2,
        "sslmode": os.environ.get("DB_SSLMODE", "require"),
    }


@app.get("/health", tags=["health"])
def health() -> dict[str, str]:
    """Liveness: the HTTP process can serve requests; no dependency check."""
    return {"status": "ok"}


@app.get("/ready", tags=["health"])
def ready() -> dict[str, str]:
    """Readiness: the service can establish a database session."""
    try:
        with closing(psycopg.connect(**database_config())) as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.fetchone()
    except (KeyError, TypeError, ValueError, json.JSONDecodeError, psycopg.Error, RuntimeError) as error:
        raise HTTPException(status_code=503, detail="database unavailable") from error
    return {"status": "ready"}
