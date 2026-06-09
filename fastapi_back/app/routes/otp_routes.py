from fastapi import APIRouter, Request
from app.controllers import otp_controller

router = APIRouter(prefix="/api", tags=["OTP"])

@router.post("/send-otp")
async def send_otp(req: Request):
    body = await req.json()
    email = body.get('email')
    return await otp_controller.send_otp(email)

@router.post("/verify-otp")
async def verify_otp(req: Request):
    body = await req.json()
    email = body.get('email')
    otp = body.get('otp')
    return await otp_controller.verify_otp_code(email, otp)

@router.get("/verify-brevo")
async def verify_brevo():
    from app.services import email_service
    return await email_service.verify_brevo_connection()
