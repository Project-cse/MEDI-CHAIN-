import React, { useContext, useEffect, useState } from 'react'
import axios from 'axios'
import { AdminContext } from '../../context/AdminContext'
import { toast } from 'react-toastify'
import GlassCard from '../../components/ui/GlassCard'
import { formatPublicId, publicIdBadgeClass } from '../../utils/publicIdDisplay'

const ManageAdmins = () => {
    const { aToken } = useContext(AdminContext)
    const backendUrl = import.meta.env.VITE_BACKEND_URL
    const [admins, setAdmins] = useState([])
    const [loading, setLoading] = useState(true)

    const fetchAdmins = async () => {
        setLoading(true)
        try {
            const { data } = await axios.get(`${backendUrl}/api/admin/admins`, {
                headers: { aToken }
            })
            if (data.success) setAdmins(data.admins || [])
            else toast.error(data.message)
        } catch (err) {
            toast.error(err.message)
        } finally {
            setLoading(false)
        }
    }

    useEffect(() => {
        if (aToken) fetchAdmins()
    }, [aToken])

    return (
        <div className='w-full bg-gradient-to-br from-indigo-50 via-white to-violet-50/30 p-4 sm:p-6 min-h-screen'>
            <div className='max-w-5xl mx-auto space-y-6'>
                <div>
                    <h2 className='text-2xl font-bold bg-gradient-to-r from-violet-600 to-indigo-600 bg-clip-text text-transparent'>
                        Platform Admins
                    </h2>
                    <p className='text-sm text-gray-500 mt-1'>Super-admin accounts with global MEDCLUES access</p>
                </div>

                {loading ? (
                    <div className='py-20 flex justify-center'>
                        <div className='animate-spin h-12 w-12 border-4 border-indigo-100 border-t-indigo-600 rounded-full' />
                    </div>
                ) : admins.length === 0 ? (
                    <GlassCard className='p-10 text-center text-gray-500'>
                        No admin records in database yet. Env-based login may still work via `.env`.
                    </GlassCard>
                ) : (
                    <GlassCard className='overflow-hidden border-none shadow-md'>
                        <table className='w-full text-sm'>
                            <thead className='bg-gray-50/80 text-gray-400 font-bold uppercase text-[10px] tracking-widest'>
                                <tr>
                                    <th className='px-6 py-4 text-left'>Admin ID</th>
                                    <th className='px-6 py-4 text-left'>Email</th>
                                    <th className='px-6 py-4 text-right'>Created</th>
                                </tr>
                            </thead>
                            <tbody className='divide-y divide-gray-50 bg-white/40'>
                                {admins.map((admin) => (
                                    <tr key={admin.id} className='hover:bg-indigo-50/40'>
                                        <td className='px-6 py-4'>
                                            <span className={publicIdBadgeClass('slate')}>
                                                {formatPublicId(admin, 'ADM', admin.id)}
                                            </span>
                                        </td>
                                        <td className='px-6 py-4 font-medium text-gray-800'>{admin.email}</td>
                                        <td className='px-6 py-4 text-right text-gray-500 text-xs'>
                                            {admin.createdAt
                                                ? new Date(admin.createdAt).toLocaleDateString('en-IN', {
                                                    day: '2-digit',
                                                    month: 'short',
                                                    year: 'numeric',
                                                })
                                                : '—'}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </GlassCard>
                )}
            </div>
        </div>
    )
}

export default ManageAdmins
