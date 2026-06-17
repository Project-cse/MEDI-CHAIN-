from fastapi import APIRouter, Depends, Request
from app.controllers import reception_controller, lifecycle_controller
from app.middleware.auth import auth_admin, auth_dean, auth_user
from app.services import trust_score_service, refund_service
from app.models import hospital_policy_model

router = APIRouter(prefix="/api/reception", tags=["Reception"])


@router.post("/scan")
async def scan_appointment(req: Request, dean_info: dict = Depends(auth_dean)):
    body = await req.json()
    booking_id = body.get("bookingId") or body.get("booking_id") or ""
    return await reception_controller.scan_qr(
        booking_id,
        scanner_id=dean_info.get("id"),
        scanner_role="dean",
        hospital_id=dean_info.get("hospital_id"),
    )


@router.post("/scan/admin")
async def scan_appointment_admin(req: Request, _email: str = Depends(auth_admin)):
    body = await req.json()
    booking_id = body.get("bookingId") or body.get("booking_id") or ""
    hospital_id = body.get("hospitalId")
    return await reception_controller.scan_qr(
        booking_id,
        scanner_role="admin",
        hospital_id=int(hospital_id) if hospital_id else None,
    )


@router.get("/grace-requests")
async def grace_requests(dean_info: dict = Depends(auth_dean)):
    return await reception_controller.list_grace_requests(dean_info.get("hospital_id"))


@router.get("/grace-requests/admin")
async def grace_requests_admin(_email: str = Depends(auth_admin)):
    return await reception_controller.list_grace_requests()


@router.post("/grace-requests/{request_id}/approve")
async def approve_grace(request_id: int, req: Request, dean_info: dict = Depends(auth_dean)):
    body = await req.json()
    return await reception_controller.approve_grace(
        request_id,
        dean_info["id"],
        "dean",
        body.get("notes"),
    )


@router.post("/grace-requests/{request_id}/reject")
async def reject_grace(request_id: int, req: Request, dean_info: dict = Depends(auth_dean)):
    body = await req.json()
    return await reception_controller.reject_grace(
        request_id,
        dean_info["id"],
        "dean",
        body.get("notes"),
    )
