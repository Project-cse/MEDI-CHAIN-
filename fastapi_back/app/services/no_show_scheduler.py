"""Background no-show detection for missed appointments."""
from __future__ import annotations

import asyncio
from datetime import datetime, timedelta

from app.config.config import settings
from app.config.db import db
from app.services import appointment_lifecycle_service, trust_score_service
from app.utils.app_logger import get_logger

log = get_logger(__name__)


async def process_missed_appointments() -> int:
    rows = await db.query(
        """
        SELECT a.* FROM appointments a
        WHERE a.lifecycle_status IN ('BOOKED', 'CONFIRMED', 'RESCHEDULED_ONCE')
          AND a.cancelled = false
          AND a.updated_at < NOW() - INTERVAL '1 day'
        LIMIT 200
        """
    )
    processed = 0
    for apt in rows:
        try:
            paid = bool(apt.get("paid_at_booking") or apt.get("payment"))
            if paid and not apt.get("grace_extension_used"):
                continue
            await appointment_lifecycle_service.transition(
                int(apt["id"]),
                "NO_SHOW",
                actor_role="system",
                reason="Auto no-show",
            )
            await appointment_lifecycle_service.transition(
                int(apt["id"]),
                "CLOSED",
                actor_role="system",
            )
            await trust_score_service.apply_event(
                int(apt["user_id"]), "NO_SHOW", actor_role="system"
            )
            processed += 1
        except Exception as exc:
            log.warning("No-show processing failed for %s: %s", apt.get("id"), exc)
    return processed


async def start_no_show_scheduler(interval_seconds: int = 3600) -> None:
    if not settings.AUTO_NO_SHOW_JOB:
        return
    while True:
        try:
            if db.pool:
                count = await process_missed_appointments()
                if count:
                    log.info("Processed %s no-show appointments", count)
        except Exception as exc:
            log.warning("No-show scheduler error: %s", exc)
        await asyncio.sleep(interval_seconds)
