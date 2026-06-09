from fastapi import APIRouter, Depends, UploadFile, File, Form, Request
from app.controllers import admin_controller
from app.middleware.auth import auth_admin
from app.utils.auth_response import build_auth_response
from typing import Optional

router = APIRouter(prefix="/api/admin", tags=["Admin"])

@router.post("/login")
async def login_admin(req: Request):
    body = await req.json()
    result = await admin_controller.login_admin(body)
    return build_auth_response(result, "admin", req)

@router.get("/appointments")
async def appointments_admin(email: str = Depends(auth_admin)):
    return await admin_controller.appointments_admin()

@router.post("/cancel-appointment")
async def appointment_cancel(req: Request, email: str = Depends(auth_admin)):
    body = await req.json()
    return await admin_controller.appointment_cancel(body.get('appointmentId'))

@router.post("/reject-appointment")
async def appointment_reject(req: Request, email: str = Depends(auth_admin)):
    body = await req.json()
    return await admin_controller.appointment_cancel(body.get('appointmentId'), body.get('reason'))

@router.post("/add-doctor")
async def add_doctor(
    name: str = Form(...),
    email: str = Form(...),
    password: str = Form(...),
    speciality: str = Form(...),
    degree: str = Form(...),
    experience: str = Form(...),
    about: str = Form(...),
    fees: str = Form(...),
    address: str = Form(...),
    image: Optional[UploadFile] = File(None),
    admin_email: str = Depends(auth_admin)
):
    form_data = {
        "name": name,
        "email": email,
        "password": password,
        "speciality": speciality,
        "degree": degree,
        "experience": experience,
        "about": about,
        "fees": fees,
        "address": address
    }
    return await admin_controller.add_doctor(form_data, image)

@router.get("/all-doctors")
async def all_doctors(email: str = Depends(auth_admin)):
    return await admin_controller.all_doctors()

@router.post("/change-availability")
async def change_availability(req: Request, admin_email: str = Depends(auth_admin)):
    body = await req.json()
    return await admin_controller.change_availability(body.get('docId'))

@router.get("/dashboard")
async def admin_dashboard(email: str = Depends(auth_admin)):
    return await admin_controller.admin_dashboard()

@router.post("/update-doctor")
async def update_doctor(
    docId: str = Form(...),
    name: Optional[str] = Form(None),
    email: Optional[str] = Form(None),
    speciality: Optional[str] = Form(None),
    degree: Optional[str] = Form(None),
    experience: Optional[str] = Form(None),
    about: Optional[str] = Form(None),
    fees: Optional[str] = Form(None),
    address: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    admin_email: str = Depends(auth_admin)
):
    form_data = {
        "docId": docId,
        "name": name,
        "email": email,
        "speciality": speciality,
        "degree": degree,
        "experience": experience,
        "about": about,
        "fees": fees,
        "address": address
    }
    return await admin_controller.update_doctor(form_data, image)

@router.delete("/delete-all-appointments")
async def delete_all_appointments(admin_email: str = Depends(auth_admin)):
    return await admin_controller.delete_all_appointments()

# Bulk Doctor Management
@router.post("/bulk-add-doctors-preview")
async def bulk_add_doctors_preview(file: UploadFile = File(...), admin_email: str = Depends(auth_admin)):
    return await admin_controller.bulk_add_doctors_preview(file)

@router.post("/bulk-add-doctors")
async def bulk_add_doctors(req: Request, admin_email: str = Depends(auth_admin)):
    body = await req.json()
    return await admin_controller.bulk_add_doctors(body.get('previewData'))

# Export Data
@router.get("/export/{table}")
async def export_data(table: str, admin_email: str = Depends(auth_admin)):
    return await admin_controller.export_data(table)

# ── DEAN Management (Admin only) ──────────────────────────────────────────────
from app.controllers import dean_controller

@router.get("/deans")
async def list_deans(admin_email: str = Depends(auth_admin)):
    return await dean_controller.admin_list_deans()

@router.post("/deans/create")
async def create_dean(req: Request, admin_email: str = Depends(auth_admin)):
    body = await req.json()
    return await dean_controller.admin_create_dean(body)

@router.delete("/deans/{dean_id}")
async def delete_dean(dean_id: int, admin_email: str = Depends(auth_admin)):
    return await dean_controller.admin_delete_dean(dean_id)

@router.put("/deans/{dean_id}")
async def update_dean(dean_id: int, req: Request, admin_email: str = Depends(auth_admin)):
    body = await req.json()
    return await dean_controller.admin_update_dean(dean_id, body)


@router.get("/users")
async def get_all_users(admin_email: str = Depends(auth_admin)):
    return await admin_controller.get_all_users()

@router.get("/revenue-analytics")
async def get_revenue_analytics(admin_email: str = Depends(auth_admin)):
    return await admin_controller.get_revenue_analytics()
