"""Human-readable public identifiers (PAT00000125, APT202600001, etc.)."""

from __future__ import annotations

from datetime import datetime, timezone

from app.config.db import db


async def _next_sequence(scope: str) -> int:
    row = await db.fetch_row(
        """
        INSERT INTO public_id_sequences (scope, last_value, updated_at)
        VALUES ($1, 1, NOW())
        ON CONFLICT (scope) DO UPDATE
        SET last_value = public_id_sequences.last_value + 1,
            updated_at = NOW()
        RETURNING last_value
        """,
        scope,
    )
    return int(row["last_value"])


async def new_patient_public_id() -> str:
    return f"PAT{await _next_sequence('PAT'):08d}"


async def new_doctor_public_id() -> str:
    return f"DOC{await _next_sequence('DOC'):08d}"


async def new_dean_public_id() -> str:
    return f"DEA{await _next_sequence('DEA'):08d}"


async def new_admin_public_id() -> str:
    return f"ADM{await _next_sequence('ADM'):08d}"


def _year(year: int | None) -> int:
    return int(year or datetime.now(timezone.utc).year)


async def new_appointment_public_id(year: int | None = None) -> str:
    yr = _year(year)
    return f"APT{yr}{await _next_sequence(f'APT{yr}'):05d}"


async def new_payment_public_id(year: int | None = None) -> str:
    yr = _year(year)
    return f"PAY{yr}{await _next_sequence(f'PAY{yr}'):05d}"


async def new_health_record_public_id(year: int | None = None) -> str:
    yr = _year(year)
    return f"REC{yr}{await _next_sequence(f'REC{yr}'):05d}"


async def ensure_public_id_schema() -> None:
    """Idempotent for fresh installs before migration 013 runs."""
    await db.execute(
        """
        CREATE TABLE IF NOT EXISTS public_id_sequences (
            scope       VARCHAR(32) PRIMARY KEY,
            last_value  BIGINT NOT NULL DEFAULT 0,
            updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """
    )
    for table in (
        "users",
        "doctors",
        "deans",
        "admins",
        "appointments",
        "payment_transactions",
        "health_records",
    ):
        await db.execute(
            f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS public_id VARCHAR(20)"
        )
