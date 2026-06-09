import json
import uuid
from datetime import datetime, timezone

import razorpay
from app.config.config import settings
from app.controllers import user_controller
from app.models import appointment_model, doctor_model

razorpay_client = razorpay.Client(
    auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET)
)

_pending_orders: dict[str, dict] = {}
_checkout_tokens: dict[str, dict] = {}
_payment_history: list[dict] = []


def is_razorpay_test_mode() -> bool:
    key = (settings.RAZORPAY_KEY_ID or "").strip()
    return key.startswith("rzp_test_")


def get_razorpay_key():
    if not settings.RAZORPAY_KEY_ID:
        return {"success": False, "message": "Razorpay not configured"}
    return {
        "success": True,
        "key_id": settings.RAZORPAY_KEY_ID,
        "test_mode": is_razorpay_test_mode(),
    }


def _razorpay_test_mode_banner_html() -> str:
    if not is_razorpay_test_mode():
        return ""
    return """
  <div id="test-hint" style="max-width:520px;margin:16px auto;padding:14px 16px;background:#FEF3C7;border:1px solid #F59E0B;border-radius:12px;text-align:left;font-size:13px;color:#92400E;line-height:1.55;">
    <strong>Test mode — how to pay successfully:</strong>
    <ul style="margin:8px 0 0;padding-left:18px;">
      <li><strong>Card (Indian test):</strong> <code>5267 3181 8797 5449</code> or <code>4111 1111 1111 1111</code> — any future expiry, any CVV. If OTP is asked, enter <code>1234</code> (test only, no real SMS).</li>
      <li><strong>UPI ID</strong> (not QR scan): enter <code>success@razorpay</code></li>
      <li><strong>Netbanking / Wallet:</strong> pick any bank/wallet → Success on the mock page</li>
    </ul>
    <p style="margin:8px 0 0;font-size:12px;">“International cards not accepted” means a non-Indian card was used. This account accepts Indian payments only.</p>
  </div>"""


def _js_str(value: str) -> str:
    return json.dumps(value or "")


def _amount_to_paise(amount_raw) -> int:
    value = float(amount_raw)
    if value >= 100 and value == int(value):
        return int(value)
    return int(round(value * 100))


async def create_order(amount_inr: float, currency: str = "INR", receipt: str | None = None):
    try:
        amount_paise = int(round(float(amount_inr) * 100))
        if amount_paise < 100:
            return {"success": False, "message": "Minimum amount is ₹1"}

        order_data = {
            "amount": amount_paise,
            "currency": currency or (settings.CURRENCY or "INR"),
            "payment_capture": 1,
        }
        if receipt:
            order_data["receipt"] = receipt

        order = razorpay_client.order.create(data=order_data)
        order_id = order.get("id")
        checkout_token = uuid.uuid4().hex
        _pending_orders[order_id] = {
            "amount_paise": amount_paise,
            "doctor_name": "MediChain+ Payment",
            "simple": True,
        }
        _checkout_tokens[checkout_token] = {"order_id": order_id}

        return {
            "success": True,
            "order_id": order_id,
            "amount": order.get("amount"),
            "currency": order.get("currency", currency),
            "razorpay_key": settings.RAZORPAY_KEY_ID,
            "checkout_token": checkout_token,
        }
    except Exception as e:
        return {"success": False, "message": str(e)}


async def create_appointment_order(user_id: int, body: dict):
    try:
        doctor_id = body.get("doctor_id")
        if not doctor_id:
            return {"success": False, "message": "doctor_id is required"}

        amount_paise = _amount_to_paise(body.get("amount", 0))
        if amount_paise < 100:
            return {"success": False, "message": "Minimum amount is ₹1"}

        doc = await doctor_model.get_doctor_by_id(doctor_id)
        doctor_name = (doc or {}).get("name") or "Doctor"

        from app.models import user_model
        user = await user_model.get_user_by_id(user_id) or {}

        receipt = f"mc_{user_id}_{uuid.uuid4().hex[:10]}"
        order = razorpay_client.order.create(
            data={
                "amount": amount_paise,
                "currency": body.get("currency", "INR"),
                "payment_capture": 1,
                "receipt": receipt,
                "notes": {
                    "doctor_id": str(doctor_id),
                    "user_id": str(user_id),
                    "appointment_date": str(body.get("appointment_date") or ""),
                    "appointment_time": str(body.get("appointment_time") or ""),
                    "slot_id": str(body.get("slot_id") or body.get("slotId") or ""),
                    "slot_type": str(body.get("slot_type") or body.get("slotType") or ""),
                    "mode": str(body.get("mode") or "online"),
                    "visit_type": str(body.get("visit_type") or "online"),
                    "booking_notes": str(body.get("notes") or "")[:200],
                },
            }
        )
        order_id = order.get("id")
        appointment_id = f"pending_{order_id}"

        _pending_orders[order_id] = {
            "user_id": user_id,
            "doctor_id": str(doctor_id),
            "doctor_name": doctor_name,
            "customer_name": (user.get("name") or "").strip(),
            "customer_email": (user.get("email") or "").strip(),
            "customer_phone": (user.get("phone") or "").strip(),
            "appointment_date": body.get("appointment_date"),
            "appointment_time": body.get("appointment_time"),
            "visit_type": body.get("visit_type") or "online",
            "mode": body.get("mode") or "online",
            "slot_id": body.get("slot_id") or body.get("slotId"),
            "slot_type": body.get("slot_type") or body.get("slotType"),
            "notes": body.get("notes") or "",
            "amount_paise": amount_paise,
            "appointment_id": appointment_id,
        }

        checkout_token = uuid.uuid4().hex
        _checkout_tokens[checkout_token] = {
            "order_id": order_id,
            "user_id": user_id,
        }

        return {
            "success": True,
            "order_id": order_id,
            "amount": order.get("amount"),
            "currency": order.get("currency", "INR"),
            "razorpay_key": settings.RAZORPAY_KEY_ID,
            "doctor_name": doctor_name,
            "appointment_id": appointment_id,
            "checkout_token": checkout_token,
        }
    except Exception as e:
        return {"success": False, "message": str(e)}


def _paid_record_for_order(order_id: str) -> dict | None:
    for record in _payment_history:
        if record.get("order_id") == order_id and record.get("status") == "paid":
            return record
    return None


async def _resolve_pending_order(order_id: str) -> dict | None:
    pending = _pending_orders.get(order_id)
    if pending:
        return pending
    try:
        order = razorpay_client.order.fetch(order_id)
        notes = order.get("notes") or {}
        user_id = int(notes.get("user_id") or 0)
        doctor_id = notes.get("doctor_id")
        if not user_id or not doctor_id:
            return None
        doc = await doctor_model.get_doctor_by_id(doctor_id)
        slot_id = notes.get("slot_id") or ""
        return {
            "user_id": user_id,
            "doctor_id": str(doctor_id),
            "doctor_name": (doc or {}).get("name") or "Doctor",
            "appointment_date": notes.get("appointment_date") or "",
            "appointment_time": notes.get("appointment_time") or "",
            "visit_type": notes.get("visit_type") or "online",
            "mode": notes.get("mode") or "online",
            "slot_id": int(slot_id) if str(slot_id).isdigit() else slot_id or None,
            "slot_type": notes.get("slot_type") or None,
            "notes": notes.get("booking_notes") or "",
            "amount_paise": int(order.get("amount") or 0),
            "appointment_id": f"pending_{order_id}",
        }
    except Exception as e:
        print(f"[WARNING] Could not restore pending order {order_id}: {e}")
        return None


async def verify_signature(
    razorpay_order_id: str,
    razorpay_payment_id: str,
    razorpay_signature: str,
):
    try:
        params = {
            "razorpay_order_id": razorpay_order_id,
            "razorpay_payment_id": razorpay_payment_id,
            "razorpay_signature": razorpay_signature,
        }
        razorpay_client.utility.verify_payment_signature(params)
        return {"success": True}
    except Exception:
        return {"success": False, "message": "Invalid payment signature"}


async def _book_after_payment(user_id: int, pending: dict, razorpay_order_id: str, razorpay_payment_id: str):
    visit = pending.get("visit_type") or "online"
    mode = pending.get("mode") or ("online" if visit == "online" else "offline")
    book_body = {
        "docId": pending["doctor_id"],
        "slotDate": pending["appointment_date"],
        "slotTime": pending["appointment_time"],
        "symptoms": [pending.get("notes")] if pending.get("notes") else [],
        "paymentMethod": "razorpay",
        "mode": mode,
        "visitType": "Online" if visit == "online" else "In-clinic",
    }
    if pending.get("slot_id"):
        book_body["slotId"] = pending["slot_id"]
    if pending.get("slot_type"):
        book_body["slotType"] = pending["slot_type"]
    booked = await user_controller.book_appointment(user_id, book_body)
    if not booked.get("success", True) and booked.get("message"):
        return {"success": False, "message": booked.get("message")}

    real_appointment_id = (
        booked.get("appointmentId")
        or booked.get("appointment_id")
        or booked.get("id")
        or pending.get("appointment_id")
    )

    try:
        await appointment_model.update_appointment(
            int(real_appointment_id),
            {
                "payment": True,
                "paymentStatus": "paid",
                "transactionId": razorpay_payment_id,
                "paymentMethod": "razorpay",
            },
        )
    except Exception as e:
        print(f"[WARNING] Could not mark appointment paid: {e}")

    try:
        from app.controllers import consultation_controller
        await consultation_controller.ensure_consultation_for_appointment(
            user_id, int(real_appointment_id)
        )
    except Exception as consult_err:
        print(f"[WARNING] Video consultation session setup: {consult_err}")

    record = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "order_id": razorpay_order_id,
        "payment_id": razorpay_payment_id,
        "appointment_id": str(real_appointment_id),
        "doctor_name": pending.get("doctor_name"),
        "amount_paise": pending.get("amount_paise"),
        "amount_inr": round((pending.get("amount_paise") or 0) / 100, 2),
        "status": "paid",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    _payment_history.insert(0, record)
    _pending_orders.pop(razorpay_order_id, None)

    return {
        "success": True,
        "appointment_id": str(real_appointment_id),
        "appointmentId": real_appointment_id,
        "bookingId": booked.get("bookingId"),
        "tokenNumber": booked.get("tokenNumber"),
        "message": "Payment successful",
        "payment": record,
    }


async def verify_appointment_payment(
    user_id: int,
    razorpay_order_id: str,
    razorpay_payment_id: str,
    razorpay_signature: str,
    appointment_id: str | None = None,
):
    verified = await verify_signature(
        razorpay_order_id, razorpay_payment_id, razorpay_signature
    )
    if not verified.get("success"):
        return verified

    existing = _paid_record_for_order(razorpay_order_id)
    if existing:
        return {
            "success": True,
            "appointment_id": existing.get("appointment_id"),
            "appointmentId": existing.get("appointment_id"),
            "message": "Payment already processed",
        }

    pending = await _resolve_pending_order(razorpay_order_id)
    if not pending:
        return {"success": False, "message": "Order not found or already processed"}
    if pending.get("user_id") != user_id:
        return {"success": False, "message": "Unauthorized payment verification"}

    return await _book_after_payment(user_id, pending, razorpay_order_id, razorpay_payment_id)


async def get_order_status(user_id: int, order_id: str):
    """Check Razorpay order status (paid / pending / failed)."""
    pending = _pending_orders.get(order_id)
    if pending and pending.get("user_id") not in (None, user_id):
        return {"success": False, "message": "Unauthorized"}

    try:
        order = razorpay_client.order.fetch(order_id)
        payments_res = razorpay_client.order.payments(order_id)
        items = payments_res.get("items") or []
        captured = next((p for p in items if p.get("status") == "captured"), None)
        failed = next((p for p in items if p.get("status") == "failed"), None)
        order_status = order.get("status")
        amount_paid = int(order.get("amount_paid") or 0)
        amount_due = int(order.get("amount_due") or 0)
        paid = order_status == "paid" or captured is not None or amount_due == 0 and amount_paid > 0

        return {
            "success": True,
            "order_id": order_id,
            "order_status": order_status,
            "paid": paid,
            "failed": failed is not None and not paid,
            "amount_paise": int(order.get("amount") or 0),
            "amount_paid_paise": amount_paid,
            "payment_id": (captured or {}).get("id"),
            "pending_in_app": order_id in _pending_orders,
            "doctor_name": (pending or {}).get("doctor_name"),
        }
    except Exception as e:
        return {"success": False, "message": str(e)}


async def confirm_paid_order(user_id: int, order_id: str):
    """Complete booking when Razorpay confirms payment (no manual signature paste)."""
    status = await get_order_status(user_id, order_id)
    if not status.get("success"):
        return status
    if status.get("failed"):
        return {"success": False, "message": "Payment failed at Razorpay", "paid": False}
    if not status.get("paid"):
        return {
            "success": False,
            "message": "Payment not completed yet. Finish payment in Razorpay checkout.",
            "paid": False,
            "order_status": status.get("order_status"),
        }

    existing = _paid_record_for_order(order_id)
    if existing:
        return {
            "success": True,
            "paid": True,
            "appointment_id": existing.get("appointment_id"),
            "appointmentId": existing.get("appointment_id"),
            "message": "Appointment already booked for this payment",
        }

    pending = await _resolve_pending_order(order_id)
    if not pending:
        return {
            "success": False,
            "message": "Payment received but booking session expired. Tap 'I've paid' in the app or contact support with your order ID.",
            "paid": True,
        }
    if pending.get("user_id") != user_id:
        return {"success": False, "message": "Unauthorized"}

    payment_id = status.get("payment_id")
    if not payment_id:
        return {"success": False, "message": "Payment ID not found on Razorpay order"}

    result = await _book_after_payment(user_id, pending, order_id, payment_id)
    result["paid"] = True
    return result


async def complete_checkout_payment(
    checkout_token: str,
    razorpay_order_id: str,
    razorpay_payment_id: str,
    razorpay_signature: str,
):
    """Called from hosted checkout page right after Razorpay success."""
    meta = _checkout_tokens.get(checkout_token)
    if not meta or meta.get("order_id") != razorpay_order_id:
        return {"success": False, "message": "Invalid or expired checkout session"}

    verified = await verify_signature(
        razorpay_order_id, razorpay_payment_id, razorpay_signature
    )
    if not verified.get("success"):
        return verified

    user_id = int(meta.get("user_id") or 0)
    existing = _paid_record_for_order(razorpay_order_id)
    if existing:
        return {
            "success": True,
            "appointment_id": existing.get("appointment_id"),
            "appointmentId": existing.get("appointment_id"),
            "bookingId": None,
            "message": "Appointment already booked",
        }

    pending = await _resolve_pending_order(razorpay_order_id)
    if not pending:
        return {
            "success": False,
            "message": "Could not restore booking details. Return to the app and tap I've paid.",
        }

    return await _book_after_payment(
        user_id, pending, razorpay_order_id, razorpay_payment_id
    )


async def record_failed_payment(
    order_id: str,
    appointment_id: str | None,
    error: str,
    user_id: int | None = None,
):
    pending = _pending_orders.pop(order_id, None)
    record = {
        "id": str(uuid.uuid4()),
        "user_id": user_id or (pending or {}).get("user_id"),
        "order_id": order_id,
        "appointment_id": appointment_id or (pending or {}).get("appointment_id"),
        "doctor_name": (pending or {}).get("doctor_name"),
        "amount_paise": (pending or {}).get("amount_paise"),
        "amount_inr": round(((pending or {}).get("amount_paise") or 0) / 100, 2),
        "status": "failed",
        "error": error or "Payment failed",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    _payment_history.insert(0, record)
    return {"success": True, "message": "Payment failure recorded"}


def get_checkout_html(checkout_token: str) -> str | None:
    """Hosted Razorpay checkout page; books appointment on success via checkout-complete API."""
    meta = _checkout_tokens.get(checkout_token)
    if not meta:
        return None

    order_id = meta.get("order_id")
    pending = _pending_orders.get(order_id)
    if not pending or not settings.RAZORPAY_KEY_ID:
        return None

    key = settings.RAZORPAY_KEY_ID
    amount = pending.get("amount_paise", 0)
    doctor_name = pending.get("doctor_name", "Doctor")
    description = f"Consultation with {doctor_name}".replace('"', "&quot;")
    prefill_name = _js_str(pending.get("customer_name") or "")
    prefill_email = _js_str(pending.get("customer_email") or "")
    prefill_contact = _js_str(pending.get("customer_phone") or "")

    checkout_token_js = _js_str(checkout_token)

    return f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>MediChain+ Payment</title>
  <style>
    body {{ font-family: system-ui, sans-serif; background: #F0F4F8; margin: 0; padding: 24px; text-align: center; }}
    h1 {{ color: #0EA5E9; font-size: 22px; }}
    p {{ color: #64748B; }}
    .loader {{ margin: 40px auto; width: 48px; height: 48px; border: 4px solid #E2E8F0; border-top-color: #0EA5E9; border-radius: 50%; animation: spin 0.8s linear infinite; }}
    @keyframes spin {{ to {{ transform: rotate(360deg); }} }}
  </style>
</head>
<body>
  <h1>MediChain+</h1>
  <p id="status-msg">Opening secure Razorpay checkout…</p>
  {_razorpay_test_mode_banner_html()}
  <div class="loader" id="loader"></div>
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <script>
    var options = {{
      key: "{key}",
      amount: {amount},
      currency: "INR",
      name: "MediChain+",
      description: "{description}",
      order_id: "{order_id}",
      prefill: {{
        name: {prefill_name},
        email: {prefill_email},
        contact: {prefill_contact}
      }},
      handler: function (response) {{
        var token = {checkout_token_js};
        document.getElementById("loader").style.display = "none";
        document.getElementById("status-msg").textContent = "Payment received — confirming your appointment…";
        fetch("/api/payments/checkout-complete", {{
          method: "POST",
          headers: {{ "Content-Type": "application/json" }},
          body: JSON.stringify({{
            checkout_token: token,
            razorpay_order_id: response.razorpay_order_id,
            razorpay_payment_id: response.razorpay_payment_id,
            razorpay_signature: response.razorpay_signature
          }})
        }})
        .then(function (r) {{ return r.json(); }})
        .then(function (data) {{
          if (data.success) {{
            document.body.innerHTML =
              '<div style="max-width:480px;margin:40px auto;padding:24px;background:#ECFDF5;border:1px solid #86EFAC;border-radius:16px;">' +
              '<h1 style="color:#16A34A;margin:0 0 12px;">Payment &amp; booking successful</h1>' +
              '<p style="color:#166534;line-height:1.5;">Close this tab and return to <strong>MediChain+</strong>. Your appointment confirmation should appear automatically.</p>' +
              '<p style="font-size:12px;color:#64748B;margin-top:16px;">Order: ' + response.razorpay_order_id + '</p>' +
              (data.bookingId ? '<p style="font-size:12px;color:#64748B;">Booking ID: ' + data.bookingId + '</p>' : '') +
              '</div>';
          }} else {{
            document.getElementById("status-msg").textContent =
              (data.message || "Booking could not be confirmed") +
              " — return to the app and tap I've paid.";
          }}
        }})
        .catch(function () {{
          document.getElementById("status-msg").textContent =
            "Payment succeeded but booking confirm failed — return to the app and tap I've paid.";
        }});
      }},
      modal: {{
        ondismiss: function () {{
          document.body.innerHTML =
            '<h1>Payment cancelled</h1>' +
            '<p>Close this tab and tap <b>Cancel payment</b> in the app.</p>';
          try {{ window.location.href = "medichain://payment?cancelled=1"; }} catch (e) {{}}
          try {{ window.close(); }} catch (e) {{}}
        }}
      }},
      theme: {{ color: "#0EA5E9" }}
    }};
    var rzp = new Razorpay(options);
    rzp.on("payment.failed", function (resp) {{
      var msg = (resp && resp.error && resp.error.description) ? resp.error.description : "Payment failed";
      if (/international/i.test(msg)) {{
        msg += " — Use Indian test card 5267 3181 8797 5449 or UPI ID success@razorpay (test mode).";
      }}
      document.getElementById("loader").style.display = "none";
      document.getElementById("status-msg").textContent = msg;
      try {{ window.location.href = "medichain://payment?failed=1"; }} catch (e) {{}}
    }});
    rzp.open();
  </script>
</body>
</html>"""


async def get_payment_history(user_id: int | None = None):
    seen_orders: set[str] = set()
    items: list[dict] = []

    for p in _payment_history:
        if user_id is not None and p.get("user_id") not in (None, user_id):
            continue
        oid = p.get("order_id")
        if oid:
            seen_orders.add(oid)
        items.append(p)

    if user_id is not None:
        try:
            appts = await appointment_model.get_appointments_by_user_id(user_id)
            for apt in appts:
                method = (apt.get("payment_method") or "").lower()
                if not apt.get("payment") and method not in ("razorpay", "onlinepayment", "online"):
                    continue
                txn = apt.get("transaction_id") or f"apt_{apt['id']}"
                if txn in seen_orders:
                    continue
                seen_orders.add(txn)
                doc_data = apt.get("doctor_data")
                doctor_name = None
                if isinstance(doc_data, str):
                    try:
                        doctor_name = json.loads(doc_data).get("name")
                    except Exception:
                        pass
                elif isinstance(doc_data, dict):
                    doctor_name = doc_data.get("name")
                items.append({
                    "id": f"apt_{apt['id']}",
                    "user_id": user_id,
                    "order_id": txn,
                    "payment_id": apt.get("transaction_id"),
                    "appointment_id": str(apt["id"]),
                    "doctor_name": doctor_name,
                    "amount_inr": float(apt.get("amount") or 0),
                    "status": "paid" if apt.get("payment") else "pending",
                    "created_at": (
                        apt.get("created_at").isoformat()
                        if hasattr(apt.get("created_at"), "isoformat")
                        else str(apt.get("created_at") or "")
                    ),
                })
        except Exception as e:
            print(f"[WARNING] payment history DB merge: {e}")

    items.sort(key=lambda x: x.get("created_at") or "", reverse=True)
    return {"success": True, "payments": items[:50]}
