"""Appointment lifecycle API orchestration."""
from __future__ import annotations

from datetime import date
from typing import Any, Optional

from app.config.db import db
from app.models import appointment_model, doctor_model
from app.services import (
    appointment_lifecycle_service,
    followup_service,
    refund_service,
    trust_score_service,
)
from app.services.appointment_lifecycle_service import AppointmentPolicyError
from app.utils.app_logger import get_logger

log = get_logger(__name__)


def _clean_text(value: Any) -> Optional[str]:
    if value is None:
        return None
    text = str(value).strip()
    return text or None


def _parse_followup_date(value: Any) -> Optional[date]:
    if value is None:
        return None
    if isinstance(value, date):
        return value
    text = _clean_text(value)
    if not text:
        return None
    try:
        return date.fromisoformat(text[:10])
    except ValueError:
        return None


def _consultation_fields_from_body(body: dict[str, Any]) -> tuple[
    Optional[str], Optional[str], Optional[str], Optional[str], Optional[date]
]:
    return (
        _clean_text(body.get("diagnosis")),
        _clean_text(body.get("advice")),
        _clean_text(body.get("notes")),
        _clean_text(body.get("prescription")),
        _parse_followup_date(body.get("followupDate") or body.get("followup_date")),
    )


async def _ensure_consultation_for_appointment(appointment: dict[str, Any]):
    from app.models import consultation_model
    from app.controllers import consultation_controller

    consultation = await consultation_model.get_consultation_by_appointment_id(
        int(appointment["id"])
    )
    if not consultation:
        consultation, _ = await consultation_controller._ensure_consultation_record(
            appointment
        )
    return consultation


async def save_consultation_draft(
    doctor_id: int,
    appointment_id: int,
    body: dict[str, Any],
) -> dict:
    """Persist prescription/clinical notes without ending the call or completing the visit."""
    appointment = await appointment_model.get_appointment_by_id(int(appointment_id))
    if not appointment or appointment["doctor_id"] != doctor_id:
        return {"success": False, "message": "Unauthorized or not found"}

    import json

    consultation = await _ensure_consultation_for_appointment(appointment)
    if not consultation:
        return {"success": False, "message": "Consultation not found"}

    diagnosis, advice, notes, prescription, followup = _consultation_fields_from_body(body)

    await db.execute(
        """
        UPDATE consultations SET
            diagnosis = COALESCE($2, diagnosis),
            advice = COALESCE($3, advice),
            notes = COALESCE($4, notes),
            prescription = COALESCE($5, prescription),
            followup_date = COALESCE($6::date, followup_date),
            attachments = COALESCE($7::jsonb, attachments),
            updated_at = NOW()
        WHERE id = $1
        """,
        int(consultation["id"]),
        diagnosis,
        advice,
        notes,
        prescription,
        followup,
        json.dumps(body.get("attachments") or []),
    )

    return {
        "success": True,
        "message": "Prescription saved for patient",
        "consultationId": int(consultation["id"]),
    }


async def get_lifecycle(appointment_id: int, user_id: Optional[int] = None) -> dict:
    appointment = await appointment_model.get_appointment_by_id(int(appointment_id))
    if not appointment:
        return {"success": False, "message": "Not found"}
    if user_id is not None and appointment["user_id"] != user_id:
        return {"success": False, "message": "Unauthorized"}
    return {
        "success": True,
        "lifecycle": appointment_lifecycle_service.lifecycle_payload(appointment),
    }


async def cancel_with_policy(
    user_id: int,
    appointment_id: int,
    *,
    reason: str = "Cancelled by patient",
    is_late: bool = False,
) -> dict:
    appointment = await appointment_model.get_appointment_by_id(int(appointment_id))
    if not appointment or appointment["user_id"] != user_id:
        return {"success": False, "message": "Unauthorized or not found"}

    ls = (appointment.get("lifecycle_status") or "BOOKED").upper()
    if ls in appointment_lifecycle_service.TERMINAL_STATUSES:
        return {"success": False, "message": "Appointment already closed."}

    paid = bool(appointment.get("payment") or appointment.get("paid_at_booking"))
    refund_row = None
    if paid:
        refund_row = await refund_service.create_refund_record(
            int(appointment_id),
            user_id,
            reason=reason,
        )
        await appointment_lifecycle_service.transition(
            int(appointment_id),
            "REFUND_PENDING",
            actor_id=user_id,
            actor_role="patient",
            reason=reason,
        )
    else:
        await appointment_lifecycle_service.transition(
            int(appointment_id),
            "CANCELLED",
            actor_id=user_id,
            actor_role="patient",
            reason=reason,
        )
        await appointment_lifecycle_service.transition(
            int(appointment_id),
            "CLOSED",
            actor_id=user_id,
            actor_role="patient",
        )

    if paid:
        await trust_score_service.apply_event(user_id, "REFUND_REQUEST")
    elif is_late:
        await trust_score_service.apply_event(user_id, "LATE_CANCEL")

    return {
        "success": True,
        "message": "Appointment cancelled",
        "refund": refund_row,
        "lifecycle": appointment_lifecycle_service.lifecycle_payload(
            await appointment_model.get_appointment_by_id(int(appointment_id)) or appointment
        ),
    }


async def request_grace_reschedule(
    user_id: int,
    appointment_id: int,
    requested_date: str,
) -> dict:
    appointment = await appointment_model.get_appointment_by_id(int(appointment_id))
    if not appointment or appointment["user_id"] != user_id:
        return {"success": False, "message": "Unauthorized or not found"}

    if not bool(appointment.get("paid_at_booking") or appointment.get("payment")):
        return {"success": False, "message": "Grace reschedule applies to paid appointments only."}
    if appointment.get("grace_extension_used"):
        return {"success": False, "message": "Grace extension already used."}

    try:
        req_date = date.fromisoformat(requested_date[:10])
    except ValueError:
        return {"success": False, "message": "Invalid date."}

    row = await db.fetch_row(
        """
        INSERT INTO appointment_grace_requests (
            appointment_id, user_id, requested_date, status
        ) VALUES ($1,$2,$3,'PENDING')
        RETURNING *
        """,
        int(appointment_id),
        int(user_id),
        req_date,
    )
    return {"success": True, "request": dict(row) if row else {}}


async def review_grace_request(
    request_id: int,
    *,
    approve: bool,
    reviewer_id: int,
    reviewer_role: str,
    notes: Optional[str] = None,
) -> dict:
    req = await db.fetch_row(
        "SELECT * FROM appointment_grace_requests WHERE id = $1",
        int(request_id),
    )
    if not req or req.get("status") != "PENDING":
        return {"success": False, "message": "Request not found or already reviewed"}

    status = "APPROVED" if approve else "REJECTED"
    await db.execute(
        """
        UPDATE appointment_grace_requests SET
            status = $2, reviewed_by = $3, reviewed_role = $4,
            notes = $5, updated_at = NOW()
        WHERE id = $1
        """,
        int(request_id),
        status,
        reviewer_id,
        reviewer_role,
        notes,
    )

    if approve:
        appointment_id = int(req["appointment_id"])
        slot_date = req["requested_date"].strftime("%d_%m_%Y")
        await db.execute(
            """
            UPDATE appointments SET
                slot_date = $2,
                grace_extension_used = true,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            """,
            appointment_id,
            slot_date,
        )
        await appointment_lifecycle_service.transition(
            appointment_id,
            "RESCHEDULED_ONCE",
            actor_id=reviewer_id,
            actor_role=reviewer_role,
            reason="Grace reschedule approved",
        )

    return {"success": True, "status": status}


async def complete_consultation(
    doctor_id: int,
    appointment_id: int,
    body: dict[str, Any],
) -> dict:
    appointment = await appointment_model.get_appointment_by_id(int(appointment_id))
    if not appointment or appointment["doctor_id"] != doctor_id:
        return {"success": False, "message": "Unauthorized or not found"}

    from app.models import health_record_model
    import json

    consultation = await _ensure_consultation_for_appointment(appointment)

    if consultation:
        diagnosis, advice, notes, prescription, followup = _consultation_fields_from_body(body)

        await db.execute(
            """
            UPDATE consultations SET
                diagnosis = COALESCE($2, diagnosis),
                advice = COALESCE($3, advice),
                notes = COALESCE($4, notes),
                prescription = COALESCE($5, prescription),
                followup_date = COALESCE($6::date, followup_date),
                attachments = COALESCE($7::jsonb, attachments),
                status = 'completed',
                ended_at = COALESCE(ended_at, NOW()),
                updated_at = NOW()
            WHERE id = $1
            """,
            int(consultation["id"]),
            diagnosis,
            advice,
            notes,
            prescription,
            followup,
            json.dumps(body.get("attachments") or []),
        )

    try:
        await appointment_lifecycle_service.transition(
            int(appointment_id),
            "COMPLETED",
            actor_id=doctor_id,
            actor_role="doctor",
        )
    except Exception as exc:
        # Prescription is saved above — still mark legacy completed if lifecycle blocks.
        try:
            await db.execute(
                """
                UPDATE appointments SET
                    is_completed = true,
                    status = 'completed',
                    completed_at = COALESCE(completed_at, NOW()),
                    lifecycle_status = COALESCE(NULLIF(lifecycle_status, ''), 'COMPLETED'),
                    updated_at = NOW()
                WHERE id = $1
                """,
                int(appointment_id),
            )
        except Exception:
            pass
        if not isinstance(exc, AppointmentPolicyError):
            log.warning(
                "Lifecycle transition after prescription save (appointment %s): %s",
                appointment_id,
                exc,
            )
    try:
        from app.services import doctor_slot_service
        await doctor_slot_service.complete_slot_for_appointment(appointment)
    except Exception:
        pass
    try:
        from app.config.db import db as _db
        doctor = await doctor_model.get_doctor_by_id(doctor_id)
        if doctor and doctor.get("current_appointment_id") == int(appointment_id):
            await _db.execute(
                "UPDATE doctors SET status = $1, current_appointment_id = NULL WHERE id = $2",
                "in-clinic",
                doctor_id,
            )
    except Exception:
        pass

    try:
        await trust_score_service.apply_event(
            int(appointment["user_id"]),
            "COMPLETED_VISIT",
            actor_id=doctor_id,
            actor_role="doctor",
        )
    except Exception as exc:
        log.warning("Trust score update skipped for appointment %s: %s", appointment_id, exc)

    try:
        updated_apt = await appointment_model.get_appointment_by_id(int(appointment_id))
        if updated_apt:
            await followup_service.open_followup_window(updated_apt)
    except Exception as exc:
        log.warning("Follow-up window skipped for appointment %s: %s", appointment_id, exc)

    try:
        doc = await doctor_model.get_doctor_by_id(doctor_id)
        doc_name = (doc.get("name") if doc else None) or body.get("doctorName") or "Doctor"
        record_payload = {
            "userId": appointment["user_id"],
            "docId": doctor_id,
            "appointmentId": appointment_id,
            "recordType": "Consultation Summary",
            "title": f"Consultation with {doc_name}",
            "description": (
                body.get("prescription")
                or body.get("notes")
                or body.get("diagnosis")
                or "Consultation completed"
            ),
            "doctorName": doc_name,
            "date": date.today(),
            "files": body.get("attachments") or [],
            "tags": ["Consultation", "Completed"],
            "isImportant": True,
        }
        await health_record_model.create_health_record(record_payload)
    except Exception:
        pass

    try:
        from app.services import fcm_service
        import asyncio
        doc = await doctor_model.get_doctor_by_id(doctor_id)
        doc_name = doc.get("name", "Doctor") if doc else "Doctor"
        asyncio.create_task(
            fcm_service.notify_appointment_booked(
                int(appointment["user_id"]),
                doc_name,
                str(appointment.get("slot_date", "")),
                "Your prescription is ready",
                int(appointment_id),
            )
        )
    except Exception:
        pass

    return {
        "success": True,
        "message": "Consultation completed",
        "lifecycle": appointment_lifecycle_service.lifecycle_payload(
            await appointment_model.get_appointment_by_id(int(appointment_id)) or appointment
        ),
    }


async def get_consultation_summary(appointment_id: int, user_id: int) -> dict:
    appointment = await appointment_model.get_appointment_by_id(int(appointment_id))
    if not appointment or appointment["user_id"] != user_id:
        return {"success": False, "message": "Unauthorized or not found"}

    from app.models import consultation_model

    consultation = await consultation_model.get_consultation_by_appointment_id(
        int(appointment_id)
    )
    if not consultation:
        if appointment.get("is_completed") or (appointment.get("lifecycle_status") or "").upper() == "COMPLETED":
            return {
                "success": True,
                "summary": {
                    "diagnosis": None,
                    "prescription": None,
                    "notes": "Consultation completed. Prescription not yet added by doctor.",
                    "advice": None,
                    "followupDate": None,
                    "attachments": [],
                },
            }
        return {"success": False, "message": "No consultation summary available"}

    summary = {
        "diagnosis": consultation.get("diagnosis"),
        "prescription": consultation.get("prescription"),
        "notes": consultation.get("notes"),
        "advice": consultation.get("advice"),
        "followupDate": (
            consultation["followup_date"].isoformat()
            if consultation.get("followup_date") and hasattr(consultation["followup_date"], "isoformat")
            else consultation.get("followup_date")
        ),
        "attachments": consultation.get("attachments") or [],
    }
    has_content = any(
        summary.get(k) for k in ("diagnosis", "prescription", "notes", "advice")
    )
    if not has_content and not (appointment.get("is_completed") or (appointment.get("lifecycle_status") or "").upper() in ("COMPLETED", "FOLLOWUP_AVAILABLE")):
        return {"success": False, "message": "No consultation summary available"}

    return {"success": True, "summary": summary}
