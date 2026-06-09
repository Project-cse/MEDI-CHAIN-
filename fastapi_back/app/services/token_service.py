"""JWT access + refresh token helpers."""
import hashlib
import hmac
import uuid
from datetime import datetime, timedelta
from typing import Optional, Tuple

from jose import jwt, JWTError

from app.config.config import settings

VALID_ROLES = frozenset({"patient", "doctor", "dean", "admin"})


def _secret() -> str:
    return settings.JWT_SECRET.strip('"').strip("'")


def hash_refresh_token(raw_token: str) -> str:
    """HMAC-SHA256 with server secret — prevents rainbow-table attacks on DB leaks."""
    secret = _secret().encode("utf-8")
    return hmac.new(secret, raw_token.encode("utf-8"), hashlib.sha256).hexdigest()


def access_token_expires_at() -> datetime:
    return datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)


def refresh_token_expires_at() -> datetime:
    return datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)


def create_access_token(
    role: str,
    *,
    user_id: Optional[int] = None,
    email: Optional[str] = None,
    hospital_id: Optional[int] = None,
) -> str:
    role = role.strip().lower()
    payload = {
        "token_type": "access",
        "role": role,
        "exp": access_token_expires_at(),
    }
    if role == "admin":
        payload["email"] = email
    elif role == "dean":
        payload["id"] = user_id
        payload["hospital_id"] = hospital_id
    else:
        payload["id"] = user_id
    return jwt.encode(payload, _secret(), algorithm="HS256")


def create_refresh_token(
    role: str,
    *,
    user_id: Optional[int] = None,
    email: Optional[str] = None,
    hospital_id: Optional[int] = None,
) -> Tuple[str, str, str]:
    """Return (raw_jwt, jti, user_key)."""
    role = role.strip().lower()
    jti = str(uuid.uuid4())
    payload = {
        "jti": jti,
        "token_type": "refresh",
        "role": role,
        "exp": refresh_token_expires_at(),
    }
    if role == "admin":
        payload["email"] = email
        user_key = str(email).strip().lower()
    elif role == "dean":
        payload["id"] = user_id
        payload["hospital_id"] = hospital_id
        user_key = str(user_id)
    else:
        payload["id"] = user_id
        user_key = str(user_id)
    raw = jwt.encode(payload, _secret(), algorithm="HS256")
    return raw, jti, user_key


def decode_token(raw_token: str) -> dict:
    return jwt.decode(raw_token, _secret(), algorithms=["HS256"])


def verify_access_payload(payload: dict) -> None:
    token_type = payload.get("token_type")
    if token_type == "refresh":
        raise JWTError("Refresh token cannot be used for API access")


def verify_refresh_payload(payload: dict, expected_role: str) -> None:
    if payload.get("token_type") != "refresh":
        raise JWTError("Invalid refresh token")
    role = (payload.get("role") or "").strip().lower()
    if role != expected_role.strip().lower():
        raise JWTError("Role mismatch")


def build_login_response(access: str, refresh: str) -> dict:
    return {
        "success": True,
        "token": access,
        "refresh_token": refresh,
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    }


async def issue_token_pair(
    role: str,
    *,
    user_id: Optional[int] = None,
    email: Optional[str] = None,
    hospital_id: Optional[int] = None,
    device_info: Optional[str] = None,
    ip_address: Optional[str] = None,
) -> dict:
    from app.models import refresh_token_model

    access = create_access_token(
        role,
        user_id=user_id,
        email=email,
        hospital_id=hospital_id,
    )
    refresh, _jti, user_key = create_refresh_token(
        role, user_id=user_id, email=email, hospital_id=hospital_id
    )
    await refresh_token_model.store_token(
        user_id=user_key,
        role=role,
        token_hash=hash_refresh_token(refresh),
        expires_at=refresh_token_expires_at(),
        device_info=device_info,
        ip_address=ip_address,
    )
    return build_login_response(access, refresh)
