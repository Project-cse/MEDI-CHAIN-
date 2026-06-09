import os
import aiosmtplib
import httpx
from email.message import EmailMessage
from app.config.config import settings
from datetime import datetime
import json

async def send_email(to: str, subject: str, html_content: str, recipient_name: str = "User", sender_name: str = None):
    try:
        # Configuration from settings
        api_key = settings.BREVO_API_KEY
        sender_email = settings.BREVO_SENDER_EMAIL or os.getenv("EMAIL_USER")
        app_name = settings.BREVO_APP_NAME or "MediChain+"
        
        if not api_key:
            print("[ERROR] Brevo API Key missing. Skipping HTTP attempt.")
            raise Exception("API Key missing")

        # Brevo HTTP API v3 endpoint
        url = "https://api.brevo.com/v3/smtp/email"
        headers = {
            "accept": "application/json",
            "content-type": "application/json",
            "api-key": api_key
        }
        
        payload = {
            "sender": {"email": sender_email, "name": sender_name or app_name},
            "to": [{"email": to, "name": recipient_name}],
            "subject": subject,
            "htmlContent": html_content
        }

        print(f"📡 Sending via Brevo HTTP API to {to}...")
        async with httpx.AsyncClient() as client:
            response = await client.post(url, headers=headers, json=payload, timeout=10.0)
            
        if response.status_code == 201:
            print(f"[SUCCESS] Email sent via Brevo HTTP successfully to {to}")
            return {"success": True, "message": "Email sent"}
        else:
            print(f"[WARNING] Brevo API Error ({response.status_code}): {response.text}")
            raise Exception(f"Brevo API error: {response.status_code}")

    except Exception as e:
        print(f"[WARNING] Brevo HTTP failed: {e}. Trying Gmail SMTP as fallback...")
        try:
            # Fallback to Gmail SMTP if Brevo fails
            gmail_user = os.getenv("EMAIL_USER")
            gmail_pass = os.getenv("EMAIL_APP_PASSWORD")
            
            if not gmail_user or not gmail_pass:
                print("[ERROR] Gmail fallback credentials missing.")
                return {"success": False, "message": "No configured email routes working"}

            msg = EmailMessage()
            msg["From"] = f"{sender_name or 'MediChain+'} <{gmail_user}>"
            msg["To"] = f"{recipient_name} <{to}>"
            msg["Subject"] = subject
            msg.set_content("HTML content received", subtype="html") # Fallback plain text
            msg.add_alternative(html_content, subtype="html")

            await aiosmtplib.send(
                msg,
                hostname="smtp.gmail.com",
                port=587,
                start_tls=True,
                username=gmail_user,
                password=gmail_pass
            )
            print(f"[SUCCESS] Email sent via Gmail Fallback successfully to {to}")
            return {"success": True, "message": "Email sent via fallback"}
        except Exception as fallback_e:
            print(f"[ERROR] Both email routes failed. Primary: {e}, Fallback: {fallback_e}")
            return {"success": False, "message": str(fallback_e)}

async def send_password_reset_otp(email: str, otp: str, user_name: str):
    subject = "Password Reset OTP - MediChain"
    html_content = f"""
    <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; border-radius: 10px;">
                <h1 style="text-align: center; color: #5f6fff;">🔐 Password Reset Request</h1>
                <p>Hi {user_name},</p>
                <p>We received a request to reset your password. Use the OTP below to complete the process:</p>
                <div style="background-color: #5f6fff; color: white; font-size: 32px; font-weight: bold; text-align: center; padding: 20px; border-radius: 8px; letter-spacing: 8px; margin: 20px 0;">
                    {otp}
                </div>
                <p style="background-color: #fff3cd; padding: 15px; border-radius: 4px;">
                    <strong>Important:</strong> This OTP is valid for 10 minutes only. Do not share it with anyone.
                </p>
                <p>If you didn't request this, please ignore this email.</p>
                <hr style="border: none; border-top: 1px solid #ddd; margin-top: 30px;">
                <p style="text-align: center; font-size: 12px; color: #666;">© {datetime.now().year} MediChain. All rights reserved.</p>
            </div>
        </body>
    </html>
    """
    return await send_email(email, subject, html_content, user_name)

async def send_appointment_confirmation(email: str, details: dict):
    patient_name = details.get('patientName', 'Patient')
    hospital_name = details.get('hospitalName', 'MediChain Hospital')
    
    subject = f"Appointment Confirmed - {hospital_name}"
    
    html_content = f"""
    <html>
        <head>
            <style>
                .medichain-highlight {{
                    color: #bfdbfe;
                }}
            </style>
        </head>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0;">
            <div style="background-color: #5f6fff; color: white; padding: 25px; text-align: center;">
                <h1 style="margin: 0; font-size: 24px;">🏥 MediChain+</h1>
                <p style="margin: 5px 0 0 0; font-size: 14px;">Your Health, Our Priority</p>
            </div>
            
            <div style="padding: 30px;">
                <p style="margin-top: 0;">Dear {patient_name},</p>
                
                <div style="background-color: #22c55e; color: white; padding: 12px; border-radius: 4px; text-align: center; font-weight: bold; margin-bottom: 20px;">
                    ✓ Your Appointment Has Been Confirmed!
                </div>
                
                <p>We're pleased to confirm your appointment at MediChain Hospital. Please find your appointment details below:</p>
                
                <div style="background-color: #f8fafc; border-left: 4px solid #5f6fff; padding: 20px; border-radius: 4px; margin-bottom: 25px;">
                    <h2 style="color: #5f6fff; margin: 0 0 15px 0; font-size: 18px;">📋 Appointment Details</h2>
                    
                    <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
                        <tr style="border-bottom: 1px solid #e2e8f0;">
                            <td style="padding: 10px 0; width: 30%; color: #64748b;">👨‍⚕️ Doctor:</td>
                            <td style="padding: 10px 0; font-weight: 500;">{details.get('doctorName')}</td>
                        </tr>
                        <tr style="border-bottom: 1px solid #e2e8f0;">
                            <td style="padding: 10px 0; color: #64748b;">🩺 Specialty:</td>
                            <td style="padding: 10px 0; font-weight: 500;">{details.get('speciality')}</td>
                        </tr>
                        <tr style="border-bottom: 1px solid #e2e8f0;">
                            <td style="padding: 10px 0; color: #64748b;">📅 Date:</td>
                            <td style="padding: 10px 0; font-weight: 500;">{details.get('date')}</td>
                        </tr>
                        <tr style="border-bottom: 1px solid #e2e8f0;">
                            <td style="padding: 10px 0; color: #64748b;">🕒 Time:</td>
                            <td style="padding: 10px 0; font-weight: 500;">{details.get('time')}</td>
                        </tr>
                        <tr style="border-bottom: 1px solid #e2e8f0;">
                            <td style="padding: 10px 0; color: #64748b;">💰 Consultation Fee:</td>
                            <td style="padding: 10px 0; font-weight: 500;">₹{details.get('fee')}</td>
                        </tr>
                        <tr>
                            <td style="padding: 10px 0; color: #64748b;">📍 Location:</td>
                            <td style="padding: 10px 0; font-weight: 500; line-height: 1.4;">{details.get('hospitalLocation', 'MediChain Hospital')}</td>
                        </tr>
                    </table>
                </div>
                
                <div style="background-color: #5f6fff; color: white; padding: 25px; border-radius: 4px; text-align: center; margin-bottom: 25px;">
                    <p style="margin: 0; font-size: 14px;">Your Token Number</p>
                    <h1 style="margin: 10px 0; font-size: 36px;">#{details.get('tokenNumber', 'N/A')}</h1>
                    <p style="margin: 0; font-size: 12px; opacity: 0.9;">Please show this at the reception</p>
                </div>
                
                <div style="background-color: #fef08a; padding: 20px; border-radius: 4px; border-left: 4px solid #eab308; margin-bottom: 30px;">
                    <p style="margin: 0 0 10px 0; font-weight: bold; color: #854d0e;">⚠️ Important Information:</p>
                    <ul style="margin: 0; padding-left: 20px; color: #713f12; font-size: 14px; line-height: 1.6;">
                        <li>Please arrive 15 minutes before your appointment time</li>
                        <li>Bring any relevant medical records or reports</li>
                        <li>Carry a valid ID proof</li>
                        <li>Your token number is #{details.get('tokenNumber', 'N/A')}</li>
                    </ul>
                </div>
                
                <div style="text-align: center;">
                    <a href="{details.get('mapsLink', '#')}" style="background-color: #5f6fff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold; display: inline-block; font-size: 14px;" target="_blank">📍 Get Directions to Hospital</a>
                </div>
            </div>
        </body>
    </html>
    """
    return await send_email(email, subject, html_content, patient_name)

async def send_otp_email(email: str, otp: str):
    subject = "MediChain+ Verification Code"
    html_content = f"""
    <html>
        <body style="font-family: sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                <div style="background: linear-gradient(135deg, #5f6fff 0%, #4f5fd9 100%); color: white; padding: 30px; text-align: center;">
                    <h1 style="margin: 0;">🏥 MediChain+</h1>
                    <p style="margin: 10px 0 0 0;">Secure Verification</p>
                </div>
                <div style="padding: 30px; text-align: center;">
                    <p>Use the following code to complete your verification:</p>
                    <div style="background-color: #f0f4ff; color: #5f6fff; font-size: 32px; font-weight: bold; padding: 20px; border-radius: 8px; letter-spacing: 8px; margin: 25px 0;">
                        {otp}
                    </div>
                    <p style="color: #666; font-size: 14px;">This code will expire in 10 minutes.</p>
                </div>
            </div>
        </body>
    </html>
    """
    return await send_email(email, subject, html_content)

async def send_welcome_email(email: str, name: str):
    subject = "Welcome to MediChain+ - Your Healthcare Journey Starts Here"
    html_content = f"""
    <html>
        <body style="font-family: sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                <div style="background: linear-gradient(135deg, #5f6fff 0%, #4f5fd9 100%); color: white; padding: 30px; text-align: center;">
                    <h1 style="margin: 0;">🏥 MediChain+</h1>
                    <p style="margin: 10px 0 0 0;">Welcome to our Community</p>
                </div>
                <div style="padding: 30px;">
                    <p>Dear {name},</p>
                    <p>Thank you for creating an account with <strong>MediChain+</strong>! We are excited to have you with us on your journey to better health.</p>
                    <div style="background-color: #f0f4ff; border-left: 4px solid #5f6fff; padding: 15px; border-radius: 4px; margin: 20px 0;">
                        <p style="margin: 0;"><strong>With your account, you can:</strong></p>
                        <ul style="margin: 10px 0;">
                            <li>Book appointments with top doctors</li>
                            <li>Access your digital health records</li>
                            <li>Order lab tests and track blood availability</li>
                            <li>Consult our AI Healthcare Assistant</li>
                        </ul>
                    </div>
                    <p>To get started, simply log in to your dashboard and complete your profile.</p>
                    <div style="text-align: center; margin-top: 30px;">
                        <p style="font-size: 14px; color: #666;">If you have any questions, our support team is here to help.</p>
                    </div>
                </div>
                <div style="background-color: #f8fafc; padding: 20px; text-align: center; font-size: 12px; color: #94a3b8;">
                    © {datetime.now().year} MediChain+. All rights reserved.
                </div>
            </div>
        </body>
    </html>
    """
    return await send_email(email, subject, html_content, name)

async def send_login_alert(email: str, name: str):
    subject = "Security Alert: New Login to MediChain+"
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    html_content = f"""
    <html>
        <body style="font-family: sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                <div style="background: #1e293b; color: white; padding: 20px; text-align: center;">
                    <h2 style="margin: 0;">🔐 Security Notification</h2>
                </div>
                <div style="padding: 30px;">
                    <p>Hi {name},</p>
                    <p>A new login was detected for your MediChain+ account on <strong>{now}</strong>.</p>
                    <p style="background-color: #fff7ed; border-left: 4px solid #f97316; padding: 15px; color: #9a3412;">
                        If this was not you, please reset your password immediately or contact our security team.
                    </p>
                </div>
                <div style="background-color: #f8fafc; padding: 20px; text-align: center; font-size: 12px; color: #94a3b8;">
                    This is an automated security message.
                </div>
            </div>
        </body>
    </html>
    """
    return await send_email(email, subject, html_content, name)

async def send_appointment_rejection(email: str, name: str, details: dict):
    subject = "Update regarding your Appointment - MediChain+"
    reason = details.get('reason', 'Scheduling conflict')
    
    html_content = f"""
    <html>
        <body style="font-family: sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                <div style="background: #ef4444; color: white; padding: 25px; text-align: center;">
                    <h1 style="margin: 0; font-size: 24px;">📅 Appointment Update</h1>
                </div>
                <div style="padding: 30px;">
                    <p>Dear {name},</p>
                    <p>We are writing to inform you that your appointment with <strong>{details.get('doctorName', 'our medical team')}</strong> scheduled for <strong>{details.get('date', 'N/A')}</strong> could not be confirmed at this time.</p>
                    
                    <div style="background-color: #fef2f2; border-left: 4px solid #ef4444; padding: 15px; margin: 25px 0; border-radius: 4px;">
                        <p style="margin: 0; color: #991b1b; font-weight: bold;">Reason for Cancellation:</p>
                        <p style="margin: 5px 0 0 0; color: #b91c1c;">{reason}</p>
                    </div>

                    <p>We sincerely apologize for this inconvenience. You can log in to your dashboard to book an alternative time slot or view other available specialists.</p>
                    
                    <div style="text-align: center; margin-top: 30px;">
                        <a href="{settings.FRONTEND_URL}/my-appointments" style="background-color: #5f6fff; color: white; padding: 12px 25px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">Go to Dashboard</a>
                    </div>
                </div>
                <div style="background-color: #f8fafc; border-top: 1px solid #e2e8f0; padding: 20px; text-align: center; font-size: 12px; color: #94a3b8;">
                    © {datetime.now().year} MediChain+. All rights reserved.
                </div>
            </div>
        </body>
    </html>
    """
    return await send_email(email, subject, html_content, name)

async def send_job_email(email, name, position, email_type):
    if email_type == 'interview':
        subject = f"Interview Scheduled with MediChain+ - {position}"
        html_content = f"""
        <html>
            <body style="font-family: sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4; padding: 20px;">
                <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                    <div style="background: #5f6fff; color: white; padding: 25px; text-align: center;">
                        <h1 style="margin: 0; font-size: 24px;">🎉 Good News!</h1>
                        <p style="margin: 5px 0 0 0;">Interview Invitation</p>
                    </div>
                    <div style="padding: 30px;">
                        <p>Hi {name},</p>
                        <p>We've reviewed your application for the <strong>{position}</strong> position and are impressed with your profile!</p>
                        <p>We’d like to schedule an interview to discuss how you can contribute to MediChain+.</p>
                        <div style="background-color: #f0f4ff; border-left: 4px solid #5f6fff; padding: 15px; border-radius: 4px; margin: 25px 0;">
                            <p style="margin: 0; color: #1e3a8a;"><strong>Next Steps:</strong></p>
                            <p style="margin: 5px 0 0 0;">Our HR team will contact you shortly via phone/email to finalize a time slot.</p>
                        </div>
                        <p>Thank you for your interest in joining our team!</p>
                    </div>
                    <div style="background-color: #f8fafc; border-top: 1px solid #e2e8f0; padding: 20px; text-align: center; font-size: 12px; color: #94a3b8;">
                        © {datetime.now().year} MediChain+. All rights reserved.
                    </div>
                </div>
            </body>
        </html>
        """
    else:
        subject = f"Update regarding your application with MediChain+"
        html_content = f"""
        <html>
            <body style="font-family: sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4; padding: 20px;">
                <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                    <div style="background: #1e293b; color: white; padding: 25px; text-align: center;">
                        <h1 style="margin: 0; font-size: 24px;">📄 Application Status</h1>
                    </div>
                    <div style="padding: 30px;">
                        <p>Hi {name},</p>
                        <p>Thank you for your interest in the <strong>{position}</strong> role at MediChain+. We enjoyed learning about your background.</p>
                        <p>After careful review, we’ve decided to move forward with other candidates at this time who more closely match our current needs.</p>
                        <p>We'll keep your profile in our database for future opportunities that align with your skills. We wish you the very best in your search!</p>
                    </div>
                    <div style="background-color: #f8fafc; border-top: 1px solid #e2e8f0; padding: 20px; text-align: center; font-size: 12px; color: #94a3b8;">
                        © {datetime.now().year} MediChain+. All rights reserved.
                    </div>
                </div>
            </body>
        </html>
        """
    return await send_email(email, subject, html_content, name)

async def send_doctor_credentials(email: str, name: str, password: str, hospital_name: str):
    subject = f"Your Doctor Account Credentials - {hospital_name}"
    html_content = f"""
    <html>
        <body style="font-family: sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                <div style="background: linear-gradient(135deg, #4f46e5 0%, #3730a3 100%); color: white; padding: 30px; text-align: center;">
                    <h1 style="margin: 0; font-size: 24px;">👨‍⚕️ Doctor Portal Access</h1>
                    <p style="margin: 10px 0 0 0;">Welcome to {hospital_name}</p>
                </div>
                <div style="padding: 30px;">
                    <p>Dear Dr. {name},</p>
                    <p>Your professional account has been successfully created by the hospital administration. You can now log in to the Doctor Portal to manage your profile and appointments.</p>
                    
                    <div style="background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 20px; margin: 25px 0;">
                        <p style="margin: 0 0 10px 0; font-weight: bold; color: #4f46e5; border-bottom: 1px solid #e2e8f0; padding-bottom: 10px;">Login Credentials</p>
                        <table style="width: 100%; font-size: 14px;">
                            <tr>
                                <td style="padding: 8px 0; color: #64748b; width: 30%;">Email:</td>
                                <td style="padding: 8px 0; font-weight: bold;">{email}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px 0; color: #64748b;">Password:</td>
                                <td style="padding: 8px 0; font-family: monospace; font-size: 16px; color: #1e293b; font-weight: bold;">{password}</td>
                            </tr>
                        </table>
                    </div>

                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{settings.FRONTEND_URL}/login" style="background-color: #4f46e5; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">Login to Doctor Panel</a>
                    </div>

                    <p style="background-color: #fef3c7; padding: 15px; border-radius: 6px; color: #92400e; font-size: 13px;">
                        <strong>Security Note:</strong> For your security, please change your password immediately after your first login. Do not share these credentials with anyone.
                    </p>
                </div>
                <div style="background-color: #f8fafc; border-top: 1px solid #e2e8f0; padding: 20px; text-align: center; font-size: 11px; color: #94a3b8;">
                    © {datetime.now().year} {hospital_name} via MediChain+. All rights reserved.
                </div>
            </div>
        </body>
    </html>
    """
    return await send_email(email, subject, html_content, name)

async def send_super_appointment_notification(email: str, name: str, details: dict):
    subject = f"Appointment Request Received - {details.get('service_type', 'MediChain+')}"
    
    html_content = f"""
    <html>
        <body style="font-family: sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                <div style="background: linear-gradient(135deg, #0ea5e9 0%, #2563eb 100%); color: white; padding: 30px; text-align: center;">
                    <h1 style="margin: 0; font-size: 24px;">📝 Support Request</h1>
                    <p style="margin: 10px 0 0 0;">MediChain+ Super Admin Services</p>
                </div>
                <div style="padding: 30px;">
                    <p>Dear {name},</p>
                    <p>Thank you for reaching out to MediChain+. We have received your request for <strong>{details.get('service_type')}</strong>. Our administrative team is reviewing your request and will contact you shortly.</p>
                    
                    <div style="background-color: #f0f9ff; border-left: 4px solid #0ea5e9; padding: 20px; border-radius: 4px; margin: 25px 0;">
                        <h2 style="color: #0369a1; margin: 0 0 15px 0; font-size: 16px;">Request Summary</h2>
                        <table style="width: 100%; font-size: 14px;">
                            <tr style="border-bottom: 1px solid #e0f2fe;">
                                <td style="padding: 8px 0; color: #64748b;">Service:</td>
                                <td style="padding: 8px 0; font-weight: bold;">{details.get('service_type')}</td>
                            </tr>
                            <tr style="border-bottom: 1px solid #e0f2fe;">
                                <td style="padding: 8px 0; color: #64748b;">Date:</td>
                                <td style="padding: 8px 0; font-weight: bold;">{details.get('appointment_date')}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px 0; color: #64748b;">Preferred Time:</td>
                                <td style="padding: 8px 0; font-weight: bold;">{details.get('appointment_time')}</td>
                            </tr>
                        </table>
                    </div>
                    
                    <p style="color: #64748b; font-size: 14px;">If you have any urgent queries, please reply to this email or visit our support portal.</p>
                </div>
                <div style="background-color: #f8fafc; border-top: 1px solid #e2e8f0; padding: 20px; text-align: center; font-size: 12px; color: #94a3b8;">
                    © {datetime.now().year} MediChain+. All rights reserved.
                </div>
            </div>
        </body>
    </html>
    """
    return await send_email(email, subject, html_content, name)

async def send_super_appointment_status_update(email: str, name: str, service_type: str, status: str):
    subject = f"Update: Your {service_type} Request is {status.capitalize()}"
    
    color = "#22c55e" if status.lower() == 'confirmed' else "#ef4444" if status.lower() == 'cancelled' else "#3b82f6"
    
    html_content = f"""
    <html>
        <body style="font-family: sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                <div style="background: {color}; color: white; padding: 25px; text-align: center;">
                    <h1 style="margin: 0; font-size: 22px;">🔄 Status Update</h1>
                </div>
                <div style="padding: 30px;">
                    <p>Dear {name},</p>
                    <p>The status of your <strong>{service_type}</strong> request has been updated to:</p>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <span style="background-color: {color}; color: white; padding: 10px 25px; border-radius: 50px; font-weight: bold; font-size: 18px; text-transform: uppercase; letter-spacing: 1px;">
                            {status}
                        </span>
                    </div>
                    
                    <p>If you have any questions regarding this update, please contact our support team at medichain123@gmail.com.</p>
                </div>
                <div style="background-color: #f8fafc; border-top: 1px solid #e2e8f0; padding: 20px; text-align: center; font-size: 11px; color: #94a3b8;">
                    © {datetime.now().year} MediChain+. All rights reserved.
                </div>
            </div>
        </body>
    </html>
    """
    return await send_email(email, subject, html_content, name)
