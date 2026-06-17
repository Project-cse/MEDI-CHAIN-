"""Canonical appointment lifecycle statuses and transitions."""
from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Any, Optional

from app.config.config import settings, _env_bool
from app.config.db import db
from app.services import audit_service
from app.utils.app_logger import get_logger

log = get_logger(__name__)

ACTIVE_STATUSES = frozenset({
    "BOOKED",
    "CONFIRMED",
    "CHECKED_IN",
    "IN_PROGRESS",
    "FOLLOWUP_AVAILABLE",
    "RESCHEDULED_ONCE",
})

BLOCKING_STATUSES = frozenset({
    "BOOKED",
    "CONFIRMED",
    "IN_PROGRESS",
    "FOLLOWUP_AVAILABLE",
})

TERMINAL_STATUSES = frozenset({
    "CANCELLED",
    "NO_SHOW",
    "EXPIRED",
    "REFUNDED",
    "CLOSED",
    "FOLLOWUP_EXPIRED",
})

ALLOWED_TRANSITIONS: dict[str, frozenset[str]] = {
    "BOOKED": frozenset({
        "CONFIRMED", "CHECKED_IN", "CANCELLED", "NO_SHOW", "IN_PROGRESS",
        "COMPLETED", "REFUND_PENDING", "CLOSED",
    }),
    "CONFIRMED": frozenset({
        "CHECKED_IN", "IN_PROGRESS", "CANCELLED", "NO_SHOW",
        "RESCHEDULED_ONCE", "REFUND_PENDING", "COMPLETED",
    }),
    "CHECKED_IN": frozenset({"IN_PROGRESS", "COMPLETED", "NO_SHOW", "EXPIRED"}),
    "IN_PROGRESS": frozenset({"COMPLETED", "NO_SHOW"}),
    "COMPLETED": frozenset({"FOLLOWUP_AVAILABLE", "CLOSED"}),
    "FOLLOWUP_AVAILABLE": frozenset({
        "FOLLOWUP_USED", "FOLLOWUP_EXPIRED", "CLOSED",
    }),
    "FOLLOWUP_USED": frozenset({"FOLLOWUP_AVAILABLE", "FOLLOWUP_EXPIRED", "CLOSED"}),
    "RESCHEDULED_ONCE": frozenset({
        "CHECKED_IN", "IN_PROGRESS", "NO_SHOW", "EXPIRED", "CANCELLED", "COMPLETED",
    }),
    "CANCELLED": frozenset({"REFUND_PENDING", "CLOSED"}),
    "REFUND_PENDING": frozenset({"REFUNDED", "CLOSED"}),
    "REFUNDED": frozenset({"CLOSED"}),
    "NO_SHOW": frozenset({"CLOSED", "RESCHEDULED_ONCE"}),
    "EXPIRED": frozenset({"CLOSED"}),
    "FOLLOWUP_EXPIRED": frozenset({"CLOSED"}),
    "CLOSED": frozenset(),
}


class AppointmentPolicyError(Exception):
    def __init__(self, message: str, code: str = "POLICY_VIOLATION"):
        self.message = message
        self.code = code
        super().__init__(message)


def lifecycle_enforced() -> bool:
    return _env_bool("APPOINTMENT_LIFECYCLE_ENFORCED", True)


def _legacy_status_for(lifecycle: str) -> str:
    mapping = {
        "BOOKED": "pending",
        "CONFIRMED": "confirmed",
        "CHECKED_IN": "confirmed",
        "IN_PROGRESS": "in-consult",
        "COMPLETED": "completed",
        "CANCELLED": "cancelled",
        "NO_SHOW": "no-show",
        "RESCHEDULED_ONCE": "rescheduled",
        "EXPIRED": "expired",
        "REFUND_PENDING": "refund-pending",
        "REFUNDED": "refunded",
        "FOLLOWUP_AVAILABLE": "followup-available",
        "FOLLOWUP_USED": "followup-used",
        "FOLLOWUP_EXPIRED": "followup-expired",
        "CLOSED": "closed",
    }
    return mapping.get(lifecycle, "pending")


def _coerce_lifecycle(appointment: dict) -> str:
    ls = (appointment.get("lifecycle_status") or "").strip().upper()
    if ls:
        return ls
    if appointment.get("cancelled"):
        return "CANCELLED"
    if appointment.get("is_completed"):
        return "COMPLETED"
    st = (appointment.get("status") or "pending").lower()
    if st == "in-consult":
        return "IN_PROGRESS"
    if st == "confirmed":
        return "CONFIRMED"
    if st == "completed":
        return "COMPLETED"
    if st == "cancelled":
        return "CANCELLED"
    return "BOOKED"


def can_transition(current: str, target: str) -> bool:
    current = current.upper()
    target = target.upper()
    if current == target:
        return True
    return target in ALLOWED_TRANSITIONS.get(current, frozenset())


async def count_active_by_user(user_id: int) -> int:
    row = await db.fetch_row(
        """
        SELECT COUNT(*)::int AS c FROM appointments
        WHERE user_id = $1
          AND lifecycle_status = ANY($2::varchar[])
        """,
        int(user_id),
        list(BLOCKING_STATUSES),
    )
    return int(row["c"]) if row else 0


async def assert_can_book(
    user_id: int,
    *,
    admin_override: bool = False,
) -> None:
    if not lifecycle_enforced() or admin_override:
        return

    from app.services import trust_score_service

    await trust_score_service.assert_can_book(user_id)

    active = await count_active_by_user(user_id)
    if active > 0:
        raise AppointmentPolicyError(
            "Please complete, cancel, or close your existing appointment "
            "before creating a new one."
        )


async def transition(
    appointment_id: int,
    to_status: str,
    *,
    actor_id: Optional[int] = None,
    actor_role: Optional[str] = None,
    reason: Optional[str] = None,
    extra_fields: Optional[dict[str, Any]] = None,
) -> dict:
    appointment = await db.fetch_row(
        "SELECT * FROM appointments WHERE id = $1",
        int(appointment_id),
    )
    if not appointment:
        raise AppointmentPolicyError("Appointment not found", "NOT_FOUND")

    current = _coerce_lifecycle(appointment)
    target = to_status.upper()
    if not can_transition(current, target):
        raise AppointmentPolicyError(
            f"Cannot transition from {current} to {target}"
        )

    fields = ["lifecycle_status = $1", "status = $2", "updated_at = CURRENT_TIMESTAMP"]
    values: list[Any] = [target, _legacy_status_for(target)]
    idx = 3

    if reason is not None:
        fields.append(f"lifecycle_status_reason = ${idx}")
        values.append(reason)
        idx += 1

    if target in ("CANCELLED", "REFUND_PENDING"):
        fields.append(f"cancelled = ${idx}")
        values.append(True)
        idx += 1
    if target == "COMPLETED":
        fields.append(f"is_completed = ${idx}")
        values.append(True)
        idx += 1
        fields.append(f"completed_at = ${idx}")
        values.append(datetime.utcnow())
        idx += 1
    if target == "CHECKED_IN":
        fields.append(f"checked_in_at = ${idx}")
        values.append(datetime.utcnow())
        idx += 1
    if target in TERMINAL_STATUSES:
        fields.append(f"closed_at = ${idx}")
        values.append(datetime.utcnow())
        idx += 1

    if extra_fields:
        for key, val in extra_fields.items():
            fields.append(f"{key} = ${idx}")
            values.append(val)
            idx += 1

    values.append(int(appointment_id))
    sql = f"UPDATE appointments SET {', '.join(fields)} WHERE id = ${idx} RETURNING *"
    updated = await db.fetch_row(sql, *values)

    await audit_service.log_access(
        action="APPOINTMENT_STATUS_CHANGE",
        resource="appointment",
        resource_id=appointment_id,
        actor_id=actor_id,
        actor_role=actor_role,
        metadata={
            "from": current,
            "to": target,
            "reason": reason,
        },
    )
    return dict(updated) if updated else dict(appointment)


async def apply_booking_defaults(
    appointment_id: int,
    *,
    hospital_id: Optional[int],
    validity_days: int,
    max_visits: int,
    followup_visits_max: int,
    paid_at_booking: bool = False,
) -> None:
    valid_until = datetime.utcnow() + timedelta(days=int(validity_days))
    await db.execute(
        """
        UPDATE appointments SET
            hospital_id = COALESCE($2, hospital_id),
            validity_days = $3,
            max_visits = $4,
            valid_until = $5,
            followup_visits_max = $6,
            paid_at_booking = $7,
            lifecycle_status = 'BOOKED',
            status = 'pending',
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $1
        """,
        int(appointment_id),
        hospital_id,
        int(validity_days),
        int(max_visits),
        valid_until,
        int(followup_visits_max),
        bool(paid_at_booking),
    )
    await db.execute(
        "UPDATE users SET total_bookings = total_bookings + 1 WHERE id = "
        "(SELECT user_id FROM appointments WHERE id = $1)",
        int(appointment_id),
    )


async def mark_paid_confirmed(appointment_id: int) -> None:
    await db.execute(
        """
        UPDATE appointments SET
            paid_at_booking = true,
            payment = true,
            lifecycle_status = CASE
                WHEN lifecycle_status = 'BOOKED' THEN 'CONFIRMED'
                ELSE lifecycle_status
            END,
            status = CASE
                WHEN lifecycle_status IN ('BOOKED', 'CONFIRMED') THEN 'confirmed'
                ELSE status
            END,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $1
        """,
        int(appointment_id),
    )


def lifecycle_payload(appointment: dict) -> dict:
    ls = _coerce_lifecycle(appointment)
    valid_until = appointment.get("valid_until")
    if hasattr(valid_until, "isoformat"):
        valid_until = valid_until.isoformat()
    followup_until = appointment.get("followup_valid_until")
    if hasattr(followup_until, "isoformat"):
        followup_until = followup_until.isoformat()
    return {
        "lifecycleStatus": ls,
        "visitCount": int(appointment.get("visit_count") or 0),
        "maxVisits": appointment.get("max_visits"),
        "validityDays": appointment.get("validity_days"),
        "validUntil": valid_until,
        "followupVisitsUsed": int(appointment.get("followup_visits_used") or 0),
        "followupVisitsMax": appointment.get("followup_visits_max"),
        "followupValidUntil": followup_until,
        "graceExtensionUsed": bool(appointment.get("grace_extension_used")),
        "paidAtBooking": bool(appointment.get("paid_at_booking")),
    }
