import socketio

# Initialize Socket.IO server
# async_mode='asgi' is required for FastAPI integration
sio = socketio.AsyncServer(async_mode='asgi', cors_allowed_origins='*')
sio_app = socketio.ASGIApp(sio)

@sio.event
async def connect(sid, environ):
    print(f"✅ Client connected: {sid}")
    await sio.emit('connection-response', {'status': 'connected', 'sid': sid}, to=sid)

@sio.event
async def disconnect(sid):
    print(f"❌ Client disconnected: {sid}")

@sio.event
async def message(sid, data):
    print(f"📩 Message from {sid}: {data}")

# Helper functions to emit events from controllers
async def emit_new_appointment(appointment_data):
    """Notify admins of a new appointment"""
    await sio.emit('new-appointment', appointment_data)

async def emit_revenue_update(revenue_data):
    """Notify admins of revenue changes"""
    await sio.emit('revenue-updated', revenue_data)

async def emit_doctor_status(doctor_data):
    """Notify admins of doctor availability changes"""
    await sio.emit('doctor-status-changed', doctor_data)
