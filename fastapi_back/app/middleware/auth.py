from fastapi import Request, HTTPException, Security, Depends
import fastapi.security
from jose import jwt, JWTError
from app.config.config import settings
from app.services.token_service import verify_access_payload
from datetime import datetime

security = fastapi.security.HTTPBearer(auto_error=False)

async def auth_user(request: Request, token: fastapi.security.HTTPAuthorizationCredentials = Depends(security)):
    # Try getting token from Bearer header OR from 'token' header
    token_str = token.credentials if token else None
    
    if not token_str:
        token_str = request.headers.get("token") or request.headers.get("Token")
        
    # Extra check: Authorization header might be sent without 'Bearer ' prefix
    if not token_str:
        auth_header = request.headers.get("Authorization")
        if auth_header and not auth_header.startswith("Bearer "):
            token_str = auth_header
        
    if not token_str:
        print(f"⚠️ Auth Failed: No token found in headers. Headers: {dict(request.headers)}")
        raise HTTPException(status_code=401, detail="No token provided")
        
    try:
        secret = settings.JWT_SECRET.strip('"').strip("'")
        payload = jwt.decode(token_str, secret, algorithms=["HS256"])
        verify_access_payload(payload)

        user_id = payload.get("id")
        if user_id is None:
            # Try 'userId' just in case
            user_id = payload.get("userId")
            
        if user_id is None:
            print(f"⚠️ Auth Failed: Token decoded but 'id' missing. Payload: {payload}")
            raise HTTPException(status_code=401, detail="Invalid token")
            
        return user_id
    except JWTError as e:
        print(f"❌ Auth JWT Error: {str(e)} for token: {token_str[:15]}...")
        # If it's a "Signature verification failed", it's likely a secret mismatch
        raise HTTPException(status_code=401, detail="Not authorized, login again")

async def auth_admin(request: Request, token: fastapi.security.HTTPAuthorizationCredentials = Depends(security)):
    # Try getting token from Bearer header OR from 'atoken' / 'aToken' / 'token' header
    token_str = token.credentials if token else None
    
    if not token_str:
        # Debug: check all headers
        all_headers = dict(request.headers)
        token_str = all_headers.get("atoken") or all_headers.get("atoken") or \
                    all_headers.get("token") or all_headers.get("Token")
        
        # Manual case-insensitive find because .get() usually works but let's be sure
        if not token_str:
            for k, v in all_headers.items():
                if k.lower() in ["atoken", "token"]:
                    token_str = v
                    print(f"[auth_admin] Found token in header: {k}", flush=True)
                    break
        
    if not token_str:
        auth_header = request.headers.get("Authorization")
        if auth_header and not auth_header.startswith("Bearer "):
            token_str = auth_header

    if not token_str:
        print("[auth_admin] No token in headers (atoken, token, Authorization)", flush=True)
        raise HTTPException(status_code=401, detail="No admin token provided")
        
    try:
        secret = settings.JWT_SECRET.strip('"').strip("'")
        payload = jwt.decode(token_str, secret, algorithms=["HS256"])
        verify_access_payload(payload)
        email = payload.get("email")

        # Debug info
        expected_admin = getattr(settings, "ADMIN_EMAIL", None)
        if not expected_admin:
            print("[auth_admin] ADMIN_EMAIL not configured in .env", flush=True)
            raise HTTPException(status_code=500, detail="Server configuration error")

        if not email or str(email).strip().lower() != str(expected_admin).strip().lower():
            print(f"[auth_admin] Unauthorized email: {email}", flush=True)
            raise HTTPException(status_code=401, detail="Not authorized as admin")
        return email
    except JWTError as e:
        print(f"[auth_admin] JWT error: {e}", flush=True)
        raise HTTPException(status_code=401, detail="Not authorized, login again")

async def auth_doctor(request: Request, token: fastapi.security.HTTPAuthorizationCredentials = Depends(security)):
    # Try getting token from Bearer header OR from 'dtoken' / 'dToken' / 'token' header
    token_str = token.credentials if token else None
    if not token_str:
        token_str = request.headers.get("dtoken") or request.headers.get("dToken") or \
                    request.headers.get("token") or request.headers.get("Token")
        
    if not token_str:
        auth_header = request.headers.get("Authorization")
        if auth_header and not auth_header.startswith("Bearer "):
            token_str = auth_header

    if not token_str:
        raise HTTPException(status_code=401, detail="No doctor token provided")
        
    try:
        secret = settings.JWT_SECRET.strip('"').strip("'")
        payload = jwt.decode(token_str, secret, algorithms=["HS256"])
        verify_access_payload(payload)
        doc_id = payload.get("id")
        if doc_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return doc_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Not authorized, login again")

async def auth_dean(request: Request, token: fastapi.security.HTTPAuthorizationCredentials = Depends(security)):
    """Extract and validate a DEAN JWT. Returns dict with id & hospital_id."""
    token_str = token.credentials if token else None
    if not token_str:
        for header_key in ["deantoken", "dean-token", "token"]:
            token_str = request.headers.get(header_key)
            if token_str:
                break
    if not token_str:
        auth_header = request.headers.get("Authorization")
        if auth_header and not auth_header.startswith("Bearer "):
            token_str = auth_header
    if not token_str:
        raise HTTPException(status_code=401, detail="No DEAN token provided")
    try:
        secret = settings.JWT_SECRET.strip('"').strip("'")
        payload = jwt.decode(token_str, secret, algorithms=["HS256"])
        verify_access_payload(payload)
        if payload.get("role") != "dean":
            raise HTTPException(status_code=403, detail="Access denied: DEAN role required")
        dean_id = payload.get("id")
        hospital_id = payload.get("hospital_id")
        if dean_id is None or hospital_id is None:
            raise HTTPException(status_code=401, detail="Invalid DEAN token")
        return {"id": dean_id, "hospital_id": hospital_id}
    except JWTError:
        raise HTTPException(status_code=401, detail="Not authorized, login again")
