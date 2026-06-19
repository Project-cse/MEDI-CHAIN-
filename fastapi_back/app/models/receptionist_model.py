"""Receptionist accounts (hospital-scoped staff)."""
from __future__ import annotations

from typing import Any, Dict, Optional

from app.config.db import db


async def get_by_email(email: str):
    return await db.fetch_row(
        "SELECT * FROM receptionists WHERE LOWER(email) = LOWER($1)",
        (email or "").strip(),
    )


async def get_by_id(rec_id: int):
    return await db.fetch_row("SELECT * FROM receptionists WHERE id = $1", int(rec_id))


async def list_by_hospital(hospital_id: int):
    return await db.query(
        "SELECT * FROM receptionists WHERE hospital_id = $1 ORDER BY created_at DESC",
        int(hospital_id),
    )


async def list_all():
    return await db.query(
        """
        SELECT r.*, h.name AS hospital_name
        FROM receptionists r
        LEFT JOIN hospital_tieups h ON h.id = r.hospital_id
        ORDER BY r.created_at DESC
        """
    )


async def create(data: Dict[str, Any]):
    from app.services import public_id_service

    try:
        public_id = await public_id_service.new_patient_public_id()
    except Exception:
        public_id = None

    return await db.fetch_row(
        """
        INSERT INTO receptionists (name, email, password, phone, hospital_id, public_id)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *
        """,
        data.get("name"),
        (data.get("email") or "").strip().lower(),
        data.get("password"),
        data.get("phone"),
        int(data["hospital_id"]) if data.get("hospital_id") is not None else None,
        public_id,
    )


async def update_password(rec_id: int, password_hash: str):
    return await db.execute(
        "UPDATE receptionists SET password = $1, updated_at = NOW() WHERE id = $2",
        password_hash,
        int(rec_id),
    )


async def set_active(rec_id: int, is_active: bool):
    return await db.execute(
        "UPDATE receptionists SET is_active = $1, updated_at = NOW() WHERE id = $2",
        bool(is_active),
        int(rec_id),
    )


async def delete(rec_id: int):
    return await db.execute("DELETE FROM receptionists WHERE id = $1", int(rec_id))
