import time
import random
from typing import Dict, Optional

# In-memory storage for OTPs
# Structure: { email: { 'otp': str, 'expires_at': float, 'attempts': int, 'cooldown_until': float } }
otp_store: Dict[str, dict] = {}

# OTP expiry time: 5 minutes
OTP_EXPIRY_SECONDS = 5 * 60

# Max attempts before cooldown
MAX_ATTEMPTS = 5

# Cooldown period: 15 minutes
COOLDOWN_SECONDS = 15 * 60

def generate_otp() -> str:
    """Generate secure 6-digit OTP"""
    return str(random.randint(100000, 999999))

def store_otp(email: str, otp: str):
    """Store OTP for email"""
    email_key = email.lower()
    now = time.time()
    
    # Check if email is in cooldown
    existing = otp_store.get(email_key)
    if existing and existing.get('cooldown_until') and existing['cooldown_until'] > now:
        remaining_minutes = int((existing['cooldown_until'] - now) / 60) + 1
        raise Exception(f"Please wait {remaining_minutes} minute(s) before requesting a new OTP")

    # Store OTP with expiry
    otp_store[email_key] = {
        'otp': otp,
        'expires_at': now + OTP_EXPIRY_SECONDS,
        'attempts': 0,
        'created_at': now,
        'cooldown_until': None
    }
    
    # Cleanup expired OTPs occasionally
    cleanup_expired_otps()
    return True

def verify_otp(email: str, input_otp: str) -> dict:
    """Verify OTP for email"""
    email_key = email.lower()
    stored = otp_store.get(email_key)

    if not stored:
        return {
            'success': False,
            'message': 'OTP not found. Please request a new OTP'
        }

    now = time.time()

    # Check if OTP expired
    if stored['expires_at'] < now:
        del otp_store[email_key]
        return {
            'success': False,
            'message': 'OTP has expired. Please request a new OTP'
        }

    # Check attempts
    if stored['attempts'] >= MAX_ATTEMPTS:
        stored['cooldown_until'] = now + COOLDOWN_SECONDS
        otp_store[email_key] = stored
        remaining_minutes = int(COOLDOWN_SECONDS / 60)
        return {
            'success': False,
            'message': f"Too many failed attempts. Please wait {remaining_minutes} minutes before requesting a new OTP"
        }

    # Verify OTP
    if stored['otp'] != input_otp:
        stored['attempts'] += 1
        otp_store[email_key] = stored
        
        remaining_attempts = MAX_ATTEMPTS - stored['attempts']
        return {
            'success': False,
            'message': f"Invalid OTP. {f'{remaining_attempts} attempt(s) remaining' if remaining_attempts > 0 else 'No attempts remaining'}"
        }

    # OTP verified successfully - remove it
    del otp_store[email_key]

    return {
        'success': True,
        'message': 'OTP verified successfully'
    }

def remove_otp(email: str):
    """Remove OTP for email"""
    email_key = email.lower()
    if email_key in otp_store:
        del otp_store[email_key]

def has_active_otp(email: str) -> bool:
    """Check if email has active OTP"""
    stored = otp_store.get(email.lower())
    if not stored: return False
    
    return stored['expires_at'] > time.time()

def get_otp_remaining_time(email: str) -> int:
    """Get remaining time for OTP in seconds"""
    stored = otp_store.get(email.lower())
    if not stored: return 0
    
    remaining = int(stored['expires_at'] - time.time())
    return max(0, remaining)

def cleanup_expired_otps():
    """Cleanup expired OTPs"""
    now = time.time()
    keys_to_delete = []
    
    for email, data in otp_store.items():
        if data['expires_at'] < now and (not data.get('cooldown_until') or data['cooldown_until'] < now):
            keys_to_delete.append(email)
            
    for key in keys_to_delete:
        del otp_store[key]
