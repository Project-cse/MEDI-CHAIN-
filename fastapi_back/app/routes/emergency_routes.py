from fastapi import APIRouter, Request
from app.controllers import emergency_controller

router = APIRouter(prefix="/api/emergency", tags=["Emergency"])

@router.post("/send-alert")
async def send_emergency_alert(req: Request):
    body = await req.json()
    return await emergency_controller.send_emergency_alert(body)
