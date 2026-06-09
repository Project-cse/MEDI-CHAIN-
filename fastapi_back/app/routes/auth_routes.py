from fastapi import APIRouter, Request, HTTPException
from fastapi.responses import JSONResponse

from app.controllers import auth_controller
from app.utils.auth_response import build_auth_response
from app.utils.refresh_cookie import clear_refresh_cookie, uses_cookie_storage

router = APIRouter(prefix="/api/auth", tags=["Auth"])


@router.post("/forgot-password")
async def forgot_password(req: Request):
    body = await req.json()
    email = body.get("email")
    role = body.get("role", "patient")
    result = await auth_controller.forgot_password(email, role)
    if result.get("success") is False:
        raise HTTPException(status_code=400, detail=result.get("message", "Failed to send OTP"))
    return result


@router.post("/verify-otp")
async def verify_otp(req: Request):
    body = await req.json()
    result = await auth_controller.verify_otp(
        body.get("email"),
        body.get("otp"),
        body.get("role", "patient"),
    )
    if not result.get("valid"):
        raise HTTPException(status_code=400, detail=result.get("message", "Invalid OTP"))
    return result


@router.post("/reset-password")
async def reset_password(req: Request):
    body = await req.json()
    new_password = body.get("new_password") or body.get("newPassword")
    result = await auth_controller.reset_password(
        body.get("email"),
        body.get("otp"),
        new_password,
        body.get("role", "patient"),
    )
    if result.get("success") is False:
        raise HTTPException(status_code=400, detail=result.get("message", "Reset failed"))
    return result


@router.post("/refresh")
async def refresh(req: Request):
    body = await req.json()
    role = body.get("role", "patient")
    result = await auth_controller.refresh_tokens(
        body.get("refresh_token") or body.get("refreshToken"),
        role,
        request=req,
    )
    if not result.get("success"):
        raise HTTPException(status_code=401, detail=result.get("message", "Refresh failed"))
    return build_auth_response(result, role, req)


@router.post("/logout")
async def logout(req: Request):
    body = await req.json()
    role = body.get("role", "patient")
    result = await auth_controller.logout(
        body.get("refresh_token") or body.get("refreshToken"),
        role,
        request=req,
    )
    response = JSONResponse(content=result)
    if uses_cookie_storage(req):
        clear_refresh_cookie(response, role)
    return response
