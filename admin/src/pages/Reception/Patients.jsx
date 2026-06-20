import React, { useContext, useEffect, useMemo, useState } from 'react'
import { ReceptionContext } from '../../context/ReceptionContext'
import { PageWrap, RcHeader, Avatar, EmptyState, Spinner } from './components'

const TYPE_STYLES = {
  Online: 'bg-indigo-50 text-indigo-700 ring-indigo-200',
  'Walk-in': 'bg-amber-50 text-amber-700 ring-amber-200',
}
const TYPE_DOT = {
  Online: 'bg-indigo-500',
  'Walk-in': 'bg-amber-500',
}

const TypeBadge = ({ type }) => (
  <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-semibold ring-1 ${TYPE_STYLES[type] || 'bg-slate-50 text-slate-600 ring-slate-200'}`}>
    <span className={`w-1.5 h-1.5 rounded-full ${TYPE_DOT[type] || 'bg-slate-400'}`} />
    {type || '—'}
  </span>
)

const PaidBadge = ({ paid }) => (
  <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-semibold ring-1 ${paid ? 'bg-emerald-50 text-emerald-700 ring-emerald-200' : 'bg-rose-50 text-rose-600 ring-rose-200'}`}>
    <span className={`w-1.5 h-1.5 rounded-full ${paid ? 'bg-emerald-500' : 'bg-rose-500'}`} />
    {paid ? 'Paid' : 'Unpaid'}
  </span>
)

const BookingBadge = ({ cancelled }) => (
  <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-semibold ring-1 ${cancelled ? 'bg-rose-50 text-rose-600 ring-rose-200' : 'bg-emerald-50 text-emerald-700 ring-emerald-200'}`}>
    <span className={`w-1.5 h-1.5 rounded-full ${cancelled ? 'bg-rose-500' : 'bg-emerald-500'}`} />
    {cancelled ? 'Cancelled' : 'Active'}
  </span>
)

const fmtDate = (iso, fallback) => {
  if (iso) {
    const d = new Date(iso)
    if (!isNaN(d)) return d.toLocaleDateString('en-US', { day: '2-digit', month: 'short', year: 'numeric' })
  }
  return fallback ? String(fallback).replace(/_/g, '/') : '—'
}

const fmtPayMethod = (m) => {
  const k = String(m || '').toLowerCase()
  if (!k) return '—'
  if (['razorpay', 'online', 'onlinepayment'].includes(k)) return 'Online'
  if (k === 'cash') return 'Cash'
  if (k === 'card') return 'Card'
  if (k === 'upi') return 'UPI'
  if (['payonvisit', 'pay_on_visit', 'payatdesk', 'offline'].includes(k)) return 'Pay at desk'
  return k.charAt(0).toUpperCase() + k.slice(1)
}

const Stat = ({ label, value, accent }) => (
  <div className='flex-1 min-w-[120px] px-5 py-4'>
    <div className='flex items-center gap-2'>
      <span className={`w-2 h-2 rounded-full ${accent}`} />
      <p className='text-[11px] font-semibold uppercase tracking-wider text-slate-400'>{label}</p>
    </div>
    <p className='text-2xl font-bold text-slate-800 mt-1.5 tabular-nums'>{value}</p>
  </div>
)

const Patients = () => {
  const { getPatients } = useContext(ReceptionContext)
  const [query, setQuery] = useState('')
  const [date, setDate] = useState('')
  const [all, setAll] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let active = true
    ;(async () => {
      setLoading(true)
      const r = await getPatients(date || undefined)
      if (active && r?.success) setAll(r.patients || [])
      if (active) setLoading(false)
    })()
    return () => { active = false }
  }, [date])

  const stats = useMemo(() => ({
    total: all.length,
    online: all.filter((p) => p.type === 'Online' && !p.cancelled).length,
    walkIn: all.filter((p) => p.type === 'Walk-in' && !p.cancelled).length,
    cancelled: all.filter((p) => p.cancelled).length,
  }), [all])

  const rows = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return all
    return all.filter((p) =>
      [p.name, p.phone, p.email, p.publicId]
        .filter(Boolean)
        .some((v) => String(v).toLowerCase().includes(q))
    )
  }, [all, query])

  const prettyDate = date
    ? new Date(date).toLocaleDateString('en-US', { day: '2-digit', month: 'short', year: 'numeric' })
    : 'All dates'

  return (
    <PageWrap>
      <RcHeader title='Patients' subtitle='All patients registered at your hospital' />

      {/* Corporate stat strip */}
      <div className='bg-white rounded-xl border border-slate-200 shadow-sm mb-5 flex flex-wrap divide-x divide-slate-100'>
        <Stat label='Total Patients' value={stats.total} accent='bg-slate-400' />
        <Stat label='Online (App)' value={stats.online} accent='bg-indigo-500' />
        <Stat label='Walk-in (Desk)' value={stats.walkIn} accent='bg-amber-500' />
        <Stat label='Cancelled' value={stats.cancelled} accent='bg-rose-500' />
      </div>

      {/* Table card */}
      <div className='bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden'>
        <div className='px-5 py-4 border-b border-slate-100 flex flex-col lg:flex-row lg:items-center justify-between gap-3'>
          <div>
            <h2 className='text-sm font-bold text-slate-700'>Patient Directory</h2>
            <p className='text-xs text-slate-400 mt-0.5'>
              {prettyDate} · {rows.length} of {all.length} {all.length === 1 ? 'patient' : 'patients'}
            </p>
          </div>
          <div className='flex flex-col sm:flex-row items-stretch sm:items-center gap-2'>
            {/* Calendar date filter */}
            <div className='flex items-center gap-1.5 rounded-lg border border-slate-200 bg-slate-50 px-2.5 py-1.5'>
              <svg className='w-4 h-4 text-reception shrink-0' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z' /></svg>
              <input type='date' value={date} onChange={(e) => setDate(e.target.value)}
                className='bg-transparent outline-none text-sm text-slate-700 w-[140px]' />
              {date && (
                <button onClick={() => setDate('')} title='Show all dates'
                  className='text-slate-400 hover:text-rose-500 transition-colors'>
                  <svg className='w-4 h-4' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M6 18L18 6M6 6l12 12' /></svg>
                </button>
              )}
            </div>
            {/* Search */}
            <div className='relative w-full sm:w-72'>
              <svg className='w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M21 21l-4.35-4.35M11 19a8 8 0 100-16 8 8 0 000 16z' /></svg>
              <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder='Search name, mobile, email or ID'
                className='w-full pl-9 pr-3 py-2 rounded-lg border border-slate-200 bg-slate-50 focus:bg-white focus:border-reception outline-none text-sm' />
            </div>
          </div>
        </div>

        {loading ? <Spinner /> : rows.length === 0 ? (
          <EmptyState
            title={all.length === 0 ? (date ? 'No patients on this date' : 'No patients yet') : 'No matches'}
            sub={all.length === 0
              ? (date ? 'Try another date or clear the filter to see everyone.' : 'Patients appear here after their first appointment at your hospital.')
              : 'Try a different search.'} />
        ) : (
          <div className='overflow-x-auto'>
            <table className='w-full text-sm border-collapse'>
              <thead>
                <tr className='text-left text-[11px] uppercase tracking-wider text-slate-400 bg-slate-50 border-b border-slate-200'>
                  <th className='px-5 py-3 font-semibold'>Patient</th>
                  <th className='px-5 py-3 font-semibold'>Patient ID</th>
                  <th className='px-5 py-3 font-semibold'>Mobile</th>
                  <th className='px-5 py-3 font-semibold'>Gender / Age</th>
                  <th className='px-5 py-3 font-semibold'>Email</th>
                  <th className='px-5 py-3 font-semibold'>Type</th>
                  <th className='px-5 py-3 font-semibold'>Payment</th>
                  <th className='px-5 py-3 font-semibold'>Paid</th>
                  <th className='px-5 py-3 font-semibold'>Booking</th>
                  <th className='px-5 py-3 font-semibold text-center'>Appointments</th>
                  <th className='px-5 py-3 font-semibold'>Last Visit</th>
                </tr>
              </thead>
              <tbody className='divide-y divide-slate-100'>
                {rows.map((p) => (
                  <tr key={p._id} className={`transition-colors ${p.cancelled ? 'bg-rose-50/30 hover:bg-rose-50/60' : 'hover:bg-slate-50/70'}`}>
                    <td className='px-5 py-3'>
                      <div className='flex items-center gap-3'>
                        <Avatar name={p.name} src={p.image} />
                        <span className={`font-semibold ${p.cancelled ? 'text-slate-500' : 'text-slate-700'}`}>{p.name}</span>
                      </div>
                    </td>
                    <td className='px-5 py-3 font-mono text-xs text-slate-400'>{p.publicId || '—'}</td>
                    <td className='px-5 py-3 text-slate-600 tabular-nums'>{p.phone || '—'}</td>
                    <td className='px-5 py-3 text-slate-600'>{[p.gender, p.age].filter((v) => v && v !== 'Not Selected').join(' · ') || '—'}</td>
                    <td className='px-5 py-3 text-slate-500'>{p.email || '—'}</td>
                    <td className='px-5 py-3'><TypeBadge type={p.type} /></td>
                    <td className='px-5 py-3 text-slate-600'>{fmtPayMethod(p.paymentMethod)}</td>
                    <td className='px-5 py-3'><PaidBadge paid={p.paid} /></td>
                    <td className='px-5 py-3'><BookingBadge cancelled={p.cancelled} /></td>
                    <td className='px-5 py-3 text-center font-semibold text-slate-700 tabular-nums'>{p.appointments ?? p.visits ?? 0}</td>
                    <td className='px-5 py-3 text-slate-500 text-xs whitespace-nowrap'>{fmtDate(p.lastVisit, p.lastVisitDate)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </PageWrap>
  )
}

export default Patients
