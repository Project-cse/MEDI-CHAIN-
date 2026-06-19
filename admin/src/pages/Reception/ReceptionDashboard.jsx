import React, { useContext, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ReceptionContext } from '../../context/ReceptionContext'
import {
  PageWrap, RcHeader, KpiTile, Pill, Spinner, Avatar, EmptyState,
  fmtMoney, patientName, doctorName, tokenLabel,
} from './components'

const greeting = () => {
  const h = new Date().getHours()
  if (h < 12) return 'Good Morning'
  if (h < 17) return 'Good Afternoon'
  return 'Good Evening'
}

const Icon = ({ d }) => (
  <svg className='w-6 h-6' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={1.8} d={d} /></svg>
)

const QUICK_ACTIONS = [
  { label: 'New Walk-in', to: '/reception-walkin', d: 'M18 9v6m3-3h-6M9 12a4 4 0 100-8 4 4 0 000 8zm0 0a6 6 0 00-6 6v1h8' },
  { label: 'Scan QR', to: '/reception-checkin', d: 'M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z' },
  { label: 'Generate Token', to: '/reception-queue', d: 'M7 7h.01M7 3h5a1.99 1.99 0 011.414.586l7 7a2 2 0 010 2.828l-5 5a2 2 0 01-2.828 0l-7-7A1.99 1.99 0 013 7V5a2 2 0 012-2z' },
  { label: 'Verify Follow-up', to: '/reception-followups', d: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z' },
  { label: 'Check Payment', to: '/reception-payments', d: 'M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z' },
  { label: 'Search Patient', to: '/reception-patients', d: 'M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z' },
]

const ReceptionDashboard = () => {
  const { getDashboard, recInfo } = useContext(ReceptionContext)
  const navigate = useNavigate()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  const load = async () => {
    const res = await getDashboard()
    if (res?.success) setData(res)
    setLoading(false)
  }

  useEffect(() => { load() }, [])

  const s = data?.stats || {}
  const queue = data?.liveQueue || []

  return (
    <PageWrap>
      <RcHeader
        title={`${greeting()}, ${recInfo?.name || 'Receptionist'}`}
        subtitle={`Here's what's happening at ${recInfo?.hospitalName || 'your hospital'} today.`}
        right={
          <button onClick={load} className='px-3 py-2 rounded-xl bg-reception text-white text-sm font-semibold shadow-sm hover:bg-blue-700 transition-colors'>
            Refresh
          </button>
        }
      />

      {loading ? <Spinner /> : (
        <>
          <div className='grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4'>
            <KpiTile label='Online Patients' value={s.onlineToday ?? 0} sub='Today' tone='blue' icon={<Icon d='M21 12a9 9 0 11-18 0 9 9 0 0118 0z M3 12h18 M12 3a15 15 0 010 18 15 15 0 010-18z' />} />
            <KpiTile label='Walk-in Patients' value={s.walkInToday ?? 0} sub='Today' tone='green' icon={<Icon d='M13 5l7 7-7 7M5 5l7 7-7 7' />} />
            <KpiTile label='Waiting Queue' value={s.waitingQueue ?? 0} sub='Now' tone='amber' icon={<Icon d='M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z' />} />
            <KpiTile label='No Shows' value={s.noShows ?? 0} sub='Today' tone='rose' icon={<Icon d='M18.364 5.636L5.636 18.364m12.728 0L5.636 5.636' />} />
          </div>

          <div className='grid grid-cols-1 lg:grid-cols-3 gap-3 sm:gap-4 mt-3 sm:mt-4'>
            <KpiTile label='Follow-Ups' value={s.followUps ?? 0} sub='Today' tone='violet' icon={<Icon d='M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z' />} />
            <KpiTile label='Pending Refunds' value={s.pendingRefunds ?? 0} sub='Requests' tone='rose' icon={<Icon d='M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6' />} />
            <div className='bg-white rounded-2xl border border-slate-100 shadow-sm p-4 flex items-center justify-between'>
              <div>
                <p className='text-xs font-semibold text-slate-500'>Revenue Today</p>
                <p className='text-2xl font-black text-slate-800 mt-1'>{fmtMoney(s.revenueToday)}</p>
                <p className='text-[11px] text-emerald-600 font-semibold mt-0.5'>Collected at desk</p>
              </div>
              <svg className='w-24 h-12 text-emerald-500' viewBox='0 0 100 40' fill='none'>
                <path d='M0 32 L15 24 L30 28 L45 14 L60 18 L75 6 L100 10' stroke='currentColor' strokeWidth='2.5' strokeLinecap='round' strokeLinejoin='round' />
              </svg>
            </div>
          </div>

          <h2 className='text-sm font-black text-slate-700 uppercase tracking-wider mt-8 mb-3'>Quick Actions</h2>
          <div className='grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3'>
            {QUICK_ACTIONS.map((a) => (
              <button key={a.label} onClick={() => navigate(a.to)} className='bg-white rounded-2xl border border-slate-100 shadow-sm p-4 flex flex-col items-center gap-2 hover:border-reception hover:shadow-md transition-all group'>
                <div className='w-11 h-11 rounded-2xl bg-blue-50 text-reception flex items-center justify-center group-hover:bg-reception group-hover:text-white transition-colors'>
                  <Icon d={a.d} />
                </div>
                <span className='text-xs font-bold text-slate-600 text-center'>{a.label}</span>
              </button>
            ))}
          </div>

          <div className='bg-white rounded-2xl border border-slate-100 shadow-sm mt-8 overflow-hidden'>
            <div className='flex items-center justify-between px-5 py-4 border-b border-slate-100'>
              <h2 className='text-sm font-black text-slate-700'>Today's Queue (Live)</h2>
              <button onClick={() => navigate('/reception-queue')} className='text-xs font-bold text-reception hover:underline'>View Full Queue →</button>
            </div>
            {queue.length === 0 ? (
              <EmptyState title='Queue is empty' sub='Checked-in patients will appear here.' />
            ) : (
              <div className='overflow-x-auto'>
                <table className='w-full text-sm'>
                  <thead>
                    <tr className='text-left text-[11px] uppercase tracking-wider text-slate-400 border-b border-slate-100'>
                      <th className='px-5 py-3 font-bold'>Token</th>
                      <th className='px-5 py-3 font-bold'>Patient</th>
                      <th className='px-5 py-3 font-bold'>Type</th>
                      <th className='px-5 py-3 font-bold'>Doctor</th>
                      <th className='px-5 py-3 font-bold'>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {queue.map((a) => (
                      <tr key={a._id} className='border-b border-slate-50 hover:bg-slate-50/60'>
                        <td className='px-5 py-3 font-black text-reception'>{tokenLabel(a)}</td>
                        <td className='px-5 py-3'>
                          <div className='flex items-center gap-2'>
                            <Avatar name={patientName(a)} src={a.userData?.image} />
                            <span className='font-semibold text-slate-700'>{patientName(a)}</span>
                          </div>
                        </td>
                        <td className='px-5 py-3 text-slate-600'>{a.isOnline ? 'Online' : 'Walk-in'}</td>
                        <td className='px-5 py-3 text-slate-600'>{doctorName(a)}</td>
                        <td className='px-5 py-3'><Pill status={a.deskStatus} /></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </>
      )}
    </PageWrap>
  )
}

export default ReceptionDashboard
