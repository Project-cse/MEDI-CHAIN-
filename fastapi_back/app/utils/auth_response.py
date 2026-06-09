"""Build auth JSON responses with optional HttpOnly refresh cookie."""
from fastapi import Request
from fastapi.responses import JSONResponse

from app.utils.refresh_cookie import set_refresh_cookie, uses_cookie_storage


def build_auth_response(result: dict, role: str, request: Request | None) -> JSONResponse:
    """Attach HttpOnly refresh cookie for web; never expose refresh token in JSON body."""
    if not isinstance(result, dict):
        return JSONResponse(content=result)

    payload = dict(result)
    refresh = payload.pop("refresh_token", None)

    if refresh and request and uses_cookie_storage(request):
        response = JSONResponse(content=payload)
        set_refresh_cookie(response, role, refresh)
        return response

    if refresh:
        payload["refresh_token"] = refresh

    return JSONResponse(content=payload)
