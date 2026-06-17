import React, { useContext, useEffect, useState } from 'react'
import axios from 'axios'
import { toast } from 'react-toastify'
import { AdminContext } from '../../context/AdminContext'
import { AppContext } from '../../context/AppContext'
import PageShell from '../../components/PageShell'

const RefundManagement = () => {
    const { aToken } = useContext(AdminContext)
    const { backendUrl } = useContext(AppContext)
    const [refunds, setRefunds] = useState([])
    const [loading, setLoading] = useState(true)

    const load = async () => {
        setLoading(true)
        try {
            const { data } = await axios.get(`${backendUrl}/api/admin/refunds/pending`, {
                headers: { atoken: aToken },
            })
            if (data.success) setRefunds(data.refunds || [])
        } catch {
            toast.error('Could not load refunds')
        } finally {
            setLoading(false)
        }
    }

    useEffect(() => { load() }, [])

    const complete = async (id) => {
        try {
            await axios.post(`${backendUrl}/api/admin/refunds/${id}/complete`, {}, {
                headers: { atoken: aToken },
            })
            toast.success('Refund marked completed')
            load()
        } catch {
            toast.error('Failed to update refund')
        }
    }

    return (
        <PageShell>
            <h1 className="text-xl sm:text-2xl font-bold mb-4">Refund Queue</h1>
            {loading ? (
                <div className="flex justify-center py-12">
                    <div className="w-8 h-8 border-2 border-sky-200 border-t-sky-600 rounded-full animate-spin" />
                </div>
            ) : refunds.length === 0 ? (
                <p className="text-gray-500 text-sm sm:text-base">No pending refunds</p>
            ) : (
                <div className="space-y-3">
                    {refunds.map((r) => (
                        <div key={r.id} className="bg-white rounded-2xl border border-slate-200 p-4 flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4 shadow-sm">
                            <div className="min-w-0">
                                <p className="font-medium truncate">{r.patient_name || `User #${r.user_id}`}</p>
                                <p className="text-sm text-gray-500">
                                    ₹{(r.refund_amount_paise / 100).toFixed(2)} · {r.public_id || r.booking_id}
                                </p>
                                <p className="text-xs text-gray-400 break-words">{r.refund_reason}</p>
                            </div>
                            <button
                                type="button"
                                className="w-full sm:w-auto shrink-0 px-4 py-2.5 rounded-xl bg-sky-600 hover:bg-sky-700 text-white text-sm font-semibold"
                                onClick={() => complete(r.id)}
                            >
                                Mark refunded
                            </button>
                        </div>
                    ))}
                </div>
            )}
        </PageShell>
    )
}

export default RefundManagement
