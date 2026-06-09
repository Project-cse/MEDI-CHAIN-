"""
DEAN (Hospital Controller) Model
Stores DEAN accounts in the `deans` table.

Schema:
  id           SERIAL PRIMARY KEY
  name         TEXT NOT NULL
  email        TEXT UNIQUE NOT NULL
  password     TEXT NOT NULL         -- bcrypt hashed
  hospital_id  INT  NOT NULL REFERENCES hospital_tieups(id) ON DELETE CASCADE
  created_at   TIMESTAMPTZ DEFAULT NOW()
  updated_at   TIMESTAMPTZ DEFAULT NOW()
"""
from app.config.db import db


async def create_deans_table():
    """Idempotent: create the deans table if it does not exist."""
    sql = """
        CREATE TABLE IF NOT EXISTS deans (
            id          SERIAL PRIMARY KEY,
            name        TEXT NOT NULL,
            email       TEXT UNIQUE NOT NULL,
            password    TEXT NOT NULL,
            password_text TEXT,
            hospital_id INT NOT NULL REFERENCES hospital_tieups(id) ON DELETE CASCADE,
            created_at  TIMESTAMPTZ DEFAULT NOW(),
            updated_at  TIMESTAMPTZ DEFAULT NOW()
        );
    """
    await db.execute(sql)


async def get_dean_by_email(email: str):
    sql = "SELECT * FROM deans WHERE email = $1"
    return await db.fetch_row(sql, email)


async def get_dean_by_id(dean_id: int):
    sql = """
        SELECT d.*, h.name AS hospital_name, h.address AS hospital_address
        FROM deans d
        LEFT JOIN hospital_tieups h ON d.hospital_id = h.id
        WHERE d.id = $1
    """
    return await db.fetch_row(sql, dean_id)


async def create_dean(data: dict):
    sql = """
        INSERT INTO deans (name, email, password, password_text, hospital_id)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING *
    """
    return await db.fetch_row(sql, data["name"], data["email"], data["password"], data.get("password_text"), data["hospital_id"])


async def update_dean(dean_id: int, data: dict):
    fields, values, idx = [], [], 1
    for col in ("name", "email", "password", "password_text"):
        if col in data:
            fields.append(f"{col} = ${idx}")
            values.append(data[col])
            idx += 1
    if not fields:
        return None
    fields.append(f"updated_at = NOW()")
    sql = f"UPDATE deans SET {', '.join(fields)} WHERE id = ${idx} RETURNING *"
    values.append(dean_id)
    return await db.fetch_row(sql, *values)


async def delete_dean(dean_id: int):
    sql = "DELETE FROM deans WHERE id = $1 RETURNING *"
    return await db.fetch_row(sql, dean_id)


async def get_all_deans():
    sql = """
        SELECT d.id, d.name, d.email, d.password_text, d.hospital_id, d.created_at,
               h.name AS hospital_name
        FROM deans d
        LEFT JOIN hospital_tieups h ON d.hospital_id = h.id
        ORDER BY h.name ASC
    """
    return await db.query(sql)
