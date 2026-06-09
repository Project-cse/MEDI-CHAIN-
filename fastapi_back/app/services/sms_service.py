import json

async def send_sms(to: str, message: str):
    try:
        # Development mode - log SMS details
        print('\n📱 SMS Service (Development Mode):')
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        print(f"To: {to}")
        print(f"Message: {message[:200]}{'...' if len(message) > 200 else ''}")
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        print('⚠️  SMS service is disabled (development mode)')
        print('   SMS notifications are logged but not sent.\n')
        return {
            "success": True,
            "message": "SMS service disabled (development mode)",
            "provider": "dev-mode"
        }
    except Exception as e:
        print(f"SMS Service Error: {e}")
        return {
            "success": False,
            "message": str(e) or "Failed to send SMS"
        }

async def send_appointment_sms(phone: str, appointment_data: dict):
    patient_name = appointment_data.get('patientName', 'Patient')
    doctor_name = appointment_data.get('doctorName', 'Doctor')
    speciality = appointment_data.get('speciality', 'General')
    date = appointment_data.get('date', 'N/A')
    time = appointment_data.get('time', 'N/A')
    fee = appointment_data.get('fee', '0')
    hospital_address = appointment_data.get('hospitalAddress', 'Address not provided')
    google_maps_link = appointment_data.get('googleMapsLink')
    token_number = appointment_data.get('tokenNumber')

    message = f"""Appointment Confirmation

Hello {patient_name},

Your appointment with Dr. {doctor_name} ({speciality}) is confirmed.

Date: {date}
Time: {time}
Fee: Rs. {fee}
Location: {hospital_address}
{f'Maps: {google_maps_link}' if google_maps_link else ''}
{f'Token Number: {token_number}' if token_number else ''}

Thank you for choosing our service!"""

    return await send_sms(phone, message)

async def send_emergency_sms(phone: str, patient_name: str, location):
    location_text = 'Location not available'
    
    if location:
        if isinstance(location, str):
            location_text = location
        elif isinstance(location, dict) and location.get('latitude') and location.get('longitude'):
            lat = location['latitude']
            lng = location['longitude']
            location_text = f"Location: https://www.google.com/maps?q={lat},{lng}\nLat: {lat:.6f}, Lng: {lng:.6f}"

    message = f"""EMERGENCY ALERT

{patient_name} needs immediate help!

{location_text}

Please help or contact emergency services immediately."""

    return await send_sms(phone, message)
