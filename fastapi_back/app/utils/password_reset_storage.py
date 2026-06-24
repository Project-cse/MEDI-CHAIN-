import time
import random
from typing import Dict, Optional

# { "role:email": { otp, expires_at, verified, attempts } }
_store: Dict[str, dict] = {}

RESET_EXPIRY_SECONDS = 10 * 60
MAX_VERIFY_ATTEMPTS = 5


def _key(role: str, email: str) -> str:
    return f"{role.strip().lower()}:{email.strip().lower()}"


def generate_otp() -> str:
    return str(random.randint(100000, 999999))


def store_otp(role: str, email: str, otp: str) -> None:
    key = _key(role, email)
    now = time.time()
    _store[key] = {
        "otp": otp,
        "expires_at": now + RESET_EXPIRY_SECONDS,
        "verified": False,
        "attempts": 0,
        "created_at": now,
    }


def verify_otp(role: str, email: str, input_otp: str, *, consume: bool = False) -> dict:
    key = _key(role, email)
    stored = _store.get(key)
    if not stored:
        return {"success": False, "message": "OTP not found. Please request a new OTP"}

    now = time.time()
    if stored["expires_at"] < now:
        del _store[key]
        return {"success": False, "message": "OTP expired. Please resend."}

    if stored["attempts"] >= MAX_VERIFY_ATTEMPTS:
        return {"success": False, "message": "Too many attempts. Try again later."}

    if stored["otp"] != str(input_otp).strip():
        stored["attempts"] += 1
        _store[key] = stored
        return {"success": False, "message": "Invalid OTP. Try again."}

    if consume:
        del _store[key]
        return {"success": True, "message": "OK"}

    stored["verified"] = True
    _store[key] = stored
    return {"success": True, "message": "OTP verified"}


def is_verified(role: str, email: str, otp: str) -> bool:
    key = _key(role, email)
    stored = _store.get(key)
    if not stored:
        return False
    if stored["expires_at"] < time.time():
        return False
    return stored.get("verified") and stored["otp"] == str(otp).strip()


def consume_verified_otp(role: str, email: str, otp: str) -> bool:
    if not is_verified(role, email, otp):
        stored = _store.get(_key(role, email))
        if not stored or stored["otp"] != str(otp).strip():
            return False
    verify_otp(role, email, otp, consume=True)
    return True


# --- Pre-signup email verification ------------------------------------------
# Emails proven via OTP *before* the account exists. Registration consumes this
# marker to set email_verified, so the front-end can verify on the signup form.
_verified_signup_emails: Dict[str, float] = {}
SIGNUP_VERIFIED_WINDOW = 30 * 60


def mark_signup_email_verified(email: str) -> None:
    _verified_signup_emails[email.strip().lower()] = time.time() + SIGNUP_VERIFIED_WINDOW


def is_signup_email_verified(email: str) -> bool:
    exp = _verified_signup_emails.get(email.strip().lower())
    return bool(exp and exp > time.time())


def consume_signup_email_verified(email: str) -> bool:
    key = email.strip().lower()
    exp = _verified_signup_emails.pop(key, None)
    return bool(exp and exp > time.time())
