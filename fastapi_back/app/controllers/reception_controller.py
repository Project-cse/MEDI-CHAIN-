"""Reception and staff appointment operations."""
from __future__ import annotations

from app.services import qr_scan_service
from app.controllers import lifecycle_controller


async def scan_qr(
    booking_id: str,
    *,
    scanner_id: int | None = None,
    scanner_role: str | None = None,
    hospital_id: int | None = None,
):
    return await qr_scan_service.scan_and_checkin(
        booking_id,
        scanner_id=scanner_id,
        scanner_role=scanner_role,
        hospital_id=hospital_id,
        scan_method="QR",
    )


async def list_grace_requests(hospital_id: int | None = None):
    from app.config.db import db

    if hospital_id:
        rows = await db.query(
            """
            SELECT g.*, a.public_id, a.booking_id, u.name AS patient_name
            FROM appointment_grace_requests g
            JOIN appointments a ON a.id = g.appointment_id
            JOIN users u ON u.id = g.user_id
            WHERE g.status = 'PENDING' AND a.hospital_id = $1
            ORDER BY g.created_at ASC
            """,
            int(hospital_id),
        )
    else:
        rows = await db.query(
            """
            SELECT g.*, a.public_id, a.booking_id, u.name AS patient_name
            FROM appointment_grace_requests g
            JOIN appointments a ON a.id = g.appointment_id
            JOIN users u ON u.id = g.user_id
            WHERE g.status = 'PENDING'
            ORDER BY g.created_at ASC
            """
        )
    return {"success": True, "requests": [dict(r) for r in rows]}


async def approve_grace(request_id: int, reviewer_id: int, reviewer_role: str, notes: str | None = None):
    return await lifecycle_controller.review_grace_request(
        request_id,
        approve=True,
        reviewer_id=reviewer_id,
        reviewer_role=reviewer_role,
        notes=notes,
    )


async def reject_grace(request_id: int, reviewer_id: int, reviewer_role: str, notes: str | None = None):
    return await lifecycle_controller.review_grace_request(
        request_id,
        approve=False,
        reviewer_id=reviewer_id,
        reviewer_role=reviewer_role,
        notes=notes,
    )
