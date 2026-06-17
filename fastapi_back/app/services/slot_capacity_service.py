"""Slot capacity validation beyond doctor_slots row locking."""
from __future__ import annotations

from datetime import date
from typing import Any, Optional

from app.config.db import db
from app.models import hospital_policy_model
from app.services.appointment_lifecycle_service import ACTIVE_STATUSES

ACTIVE_LIST = list(ACTIVE_STATUSES) + ["CHECKED_IN"]


async def count_active_for_slot(
    doctor_id: int,
    slot_date: str,
    slot_time: str,
    *,
    mode: Optional[str] = None,
    slot_id: Optional[int] = None,
) -> int:
    if slot_id:
        row = await db.fetch_row(
            """
            SELECT COUNT(*)::int AS c FROM appointments
            WHERE slot_id = $1
              AND lifecycle_status = ANY($2::varchar[])
              AND cancelled = false
            """,
            int(slot_id),
            ACTIVE_LIST,
        )
        return int(row["c"]) if row else 0

    row = await db.fetch_row(
        """
        SELECT COUNT(*)::int AS c FROM appointments
        WHERE doctor_id = $1
          AND slot_date = $2
          AND slot_time = $3
          AND lifecycle_status = ANY($4::varchar[])
          AND cancelled = false
        """,
        int(doctor_id),
        slot_date,
        slot_time,
        ACTIVE_LIST,
    )
    return int(row["c"]) if row else 0


async def assert_capacity_available(
    doctor_id: int,
    slot: dict[str, Any],
    *,
    slot_date_str: Optional[str] = None,
) -> Optional[str]:
    policy = await hospital_policy_model.get_policy_for_doctor(int(doctor_id))
    mode = (slot.get("mode") or "offline").lower()
    slot_type = slot.get("slot_type") or ""

    if mode == "online" or slot_type == "video":
        capacity = int(policy.get("video_slot_capacity") or 4)
        msg = "Video slot already booked."
    else:
        capacity = int(policy.get("opd_slot_capacity") or 20)
        msg = "Slot already full."

    slot_date = slot.get("slot_date")
    if isinstance(slot_date, date):
        from app.services.doctor_slot_service import legacy_slot_date
        slot_date_str = legacy_slot_date(slot_date)
    elif not slot_date_str:
        slot_date_str = ""

    from app.services.doctor_slot_service import slot_time_label
    slot_time = slot_time_label(slot)

    count = await count_active_for_slot(
        int(doctor_id),
        slot_date_str,
        slot_time,
        mode=mode,
        slot_id=int(slot["id"]) if slot.get("id") else None,
    )

    if slot_type in ("morning_opd", "evening_opd"):
        block_count = await _count_block_bookings(
            slot.get("doctor_ref"),
            slot.get("slot_date"),
            slot_type,
        )
        if block_count >= capacity:
            return msg
        return None

    if count >= capacity:
        return msg
    return None


async def _count_block_bookings(
    doctor_ref: Optional[str],
    slot_date: Any,
    slot_type: str,
) -> int:
    if not doctor_ref or not slot_date:
        return 0
    row = await db.fetch_row(
        """
        SELECT COUNT(*)::int AS c
        FROM appointments a
        JOIN doctor_slots ds ON ds.id = a.slot_id
        WHERE ds.doctor_ref = $1
          AND ds.slot_date = $2
          AND ds.slot_type = $3
          AND a.lifecycle_status = ANY($4::varchar[])
          AND a.cancelled = false
        """,
        str(doctor_ref),
        slot_date,
        slot_type,
        ACTIVE_LIST,
    )
    return int(row["c"]) if row else 0
