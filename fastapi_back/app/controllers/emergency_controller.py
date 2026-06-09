from app.services import sms_service

async def send_emergency_alert(data: dict):
    try:
        phone = data.get('phone')
        patient_name = data.get('patientName')
        location = data.get('location')

        if not phone or not patient_name:
            return {
                "success": False,
                "message": "Phone number and patient name are required"
            }

        result = await sms_service.send_emergency_sms(phone, patient_name, location)

        if result.get('success'):
            return {
                "success": True,
                "message": "Emergency SMS sent successfully",
                "sid": result.get('sid')
            }
        else:
            return {
                "success": False,
                "message": result.get('message') or "Failed to send emergency SMS"
            }
    except Exception as e:
        print(f"Emergency Alert Error: {e}")
        return {
            "success": False,
            "message": str(e) or "Failed to send emergency SMS"
        }
