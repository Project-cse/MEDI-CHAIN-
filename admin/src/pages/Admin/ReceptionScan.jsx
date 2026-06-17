import React, { useContext, useState } from 'react'
import axios from 'axios'
import { toast } from 'react-toastify'
import { AdminContext } from '../../context/AdminContext'
import { AppContext } from '../../context/AppContext'

const ReceptionScan = () => {
    const { aToken } = useContext(AdminContext)
    const { backendUrl } = useContext(AppContext)
    const [bookingId, setBookingId] = useState('')
    const [hospitalId, setHospitalId] = useState('')
    const [result, setResult] = useState(null)
    const [loading, setLoading] = useState(false)

    const handleScan = async (e) => {
        e.preventDefault()
        if (!bookingId.trim()) {
            toast.error('Enter booking ID from QR')
            return
        }
        setLoading(true)
        setResult(null)
        try {
            const { data } = await axios.post(
                `${backendUrl}/api/reception/scan/admin`,
                { bookingId: bookingId.trim(), hospitalId: hospitalId || undefined },
                { headers: { atoken: aToken } }
            )
            setResult(data)
            if (data.success) toast.success(data.message)
            else toast.error(data.message || 'Scan failed')
        } catch (err) {
            toast.error(err?.response?.data?.message || 'Scan failed')
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="p-6 max-w-2xl">
            <h1 className="text-2xl font-bold mb-2">Reception QR Scan</h1>
            <p className="text-sm text-gray-500 mb-6">Scan or enter Booking ID (e.g. BK8X4P2)</p>
            <form onSubmit={handleScan} className="space-y-4 card p-4">
                <input
                    className="w-full border rounded-lg px-3 py-2"
                    placeholder="Booking ID"
                    value={bookingId}
                    onChange={(e) => setBookingId(e.target.value)}
                />
                <input
                    className="w-full border rounded-lg px-3 py-2"
                    placeholder="Hospital ID (optional strict match)"
                    value={hospitalId}
                    onChange={(e) => setHospitalId(e.target.value)}
                />
                <button type="submit" disabled={loading} className="btn-primary w-full">
                    {loading ? 'Validating…' : 'Check in patient'}
                </button>
            </form>
            {result && (
                <div className={`mt-6 card p-4 ${result.success ? 'border-green-400' : 'border-red-300'}`}>
                    <p className="font-semibold">{result.message}</p>
                    {result.appointment && (
                        <pre className="text-xs mt-2 overflow-auto">{JSON.stringify(result.appointment, null, 2)}</pre>
                    )}
                </div>
            )}
        </div>
    )
}

export default ReceptionScan
