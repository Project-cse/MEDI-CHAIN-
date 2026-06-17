import React, { useContext, useState } from 'react'
import axios from 'axios'
import { toast } from 'react-toastify'
import { AdminContext } from '../../context/AdminContext'
import { AppContext } from '../../context/AppContext'
import PageShell from '../../components/PageShell'

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
        <PageShell maxWidth='max-w-2xl mx-auto'>
            <h1 className="text-xl sm:text-2xl font-bold mb-2">Reception QR Scan</h1>
            <p className="text-sm text-gray-500 mb-6">Scan or enter Booking ID (e.g. BK8X4P2)</p>
            <form onSubmit={handleScan} className="space-y-4 bg-white rounded-2xl border border-slate-200 p-4 sm:p-5 shadow-sm">
                <input
                    className="w-full border border-slate-200 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-sky-500/20 focus:border-sky-400 outline-none"
                    placeholder="Booking ID"
                    value={bookingId}
                    onChange={(e) => setBookingId(e.target.value)}
                />
                <input
                    className="w-full border border-slate-200 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-sky-500/20 focus:border-sky-400 outline-none"
                    placeholder="Hospital ID (optional)"
                    value={hospitalId}
                    onChange={(e) => setHospitalId(e.target.value)}
                />
                <button type="submit" disabled={loading} className="w-full py-3 rounded-xl bg-sky-600 hover:bg-sky-700 text-white font-semibold text-sm disabled:opacity-60">
                    {loading ? 'Validating…' : 'Check in patient'}
                </button>
            </form>
            {result && (
                <div className={`mt-6 bg-white rounded-2xl border p-4 sm:p-5 ${result.success ? 'border-green-400' : 'border-red-300'}`}>
                    <p className="font-semibold text-sm sm:text-base">{result.message}</p>
                    {result.appointment && (
                        <pre className="text-xs mt-3 overflow-x-auto responsive-table-wrap p-3 bg-slate-50 rounded-lg">{JSON.stringify(result.appointment, null, 2)}</pre>
                    )}
                </div>
            )}
        </PageShell>
    )
}

export default ReceptionScan
