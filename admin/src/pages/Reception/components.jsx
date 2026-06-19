import React from 'react'

export const fmtMoney = (n) => `₹${Number(n || 0).toLocaleString('en-IN')}`

export const patientName = (a) =>
  a?.actualPatient?.name || a?.userData?.name || 'Patient'

export const patientPhone = (a) => a?.userData?.phone || a?.actualPatient?.phone || ''

export const patientImage = (a) => a?.userData?.image || null

export const doctorName = (a) => {
  const n = a?.docData?.name || 'Doctor'
  return n.startsWith('Dr') ? n : `Dr. ${n}`
}

export const tokenLabel = (a) => {
  const t = a?.todayToken || a?.tokenNumber
  return t ? `T-${String(t).padStart(3, '0')}` : '—'
}

export const todayLabel = () =>
  new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })

export const PageWrap = ({ children }) => (
  <div className='p-4 sm:p-6 lg:p-8 max-w-[1500px] mx-auto w-full'>{children}</div>
)

export const RcHeader = ({ title, subtitle, right }) => (
  <div className='flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-6'>
    <div>
      <h1 className='text-2xl font-black text-slate-800 tracking-tight'>{title}</h1>
      {subtitle && <p className='text-sm text-slate-500 mt-0.5'>{subtitle}</p>}
    </div>
    <div className='flex items-center gap-2 flex-wrap'>
      <span className='inline-flex items-center gap-2 px-3 py-2 rounded-xl bg-white border border-slate-200 text-sm font-semibold text-slate-600 shadow-sm'>
        <svg className='w-4 h-4 text-reception' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z' /></svg>
        {todayLabel()}
      </span>
      {right}
    </div>
  </div>
)

export const KpiTile = ({ label, value, sub, icon, tone = 'blue' }) => {
  const tones = {
    blue: 'bg-blue-50 text-blue-600',
    green: 'bg-emerald-50 text-emerald-600',
    amber: 'bg-amber-50 text-amber-600',
    rose: 'bg-rose-50 text-rose-600',
    violet: 'bg-violet-50 text-violet-600',
    cyan: 'bg-cyan-50 text-cyan-600',
  }
  return (
    <div className='bg-white rounded-2xl border border-slate-100 shadow-sm p-4 flex items-center gap-4'>
      <div className={`w-12 h-12 rounded-2xl flex items-center justify-center ${tones[tone] || tones.blue}`}>
        {icon}
      </div>
      <div className='min-w-0'>
        <p className='text-2xl font-black text-slate-800 leading-none'>{value}</p>
        <p className='text-xs font-semibold text-slate-500 mt-1 truncate'>{label}</p>
        {sub && <p className='text-[11px] text-slate-400 mt-0.5'>{sub}</p>}
      </div>
    </div>
  )
}

const PILL_STYLES = {
  ARRIVED: 'bg-emerald-100 text-emerald-700',
  VERIFIED: 'bg-emerald-100 text-emerald-700',
  PENDING: 'bg-amber-100 text-amber-700',
  IN_QUEUE: 'bg-blue-100 text-blue-700',
  READY: 'bg-emerald-100 text-emerald-700',
  READY_FOR_DOCTOR: 'bg-emerald-100 text-emerald-700',
  WAITING: 'bg-amber-100 text-amber-700',
  IN_CONSULTATION: 'bg-violet-100 text-violet-700',
  IN_PROGRESS: 'bg-violet-100 text-violet-700',
  COMPLETED: 'bg-slate-100 text-slate-600',
  NO_SHOW: 'bg-rose-100 text-rose-700',
  INVALID: 'bg-rose-100 text-rose-700',
  CANCELLED: 'bg-rose-100 text-rose-700',
  PAID: 'bg-emerald-100 text-emerald-700',
  UNPAID: 'bg-rose-100 text-rose-700',
  VALID: 'bg-emerald-100 text-emerald-700',
  EXPIRED: 'bg-rose-100 text-rose-700',
  ELIGIBLE: 'bg-emerald-100 text-emerald-700',
  USED: 'bg-slate-100 text-slate-600',
}

export const Pill = ({ status, label }) => (
  <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wide ${PILL_STYLES[status] || 'bg-slate-100 text-slate-600'}`}>
    {(label || status || '').toString().replace(/_/g, ' ')}
  </span>
)

export const EmptyState = ({ title = 'Nothing here yet', sub }) => (
  <div className='py-16 text-center'>
    <div className='mx-auto w-14 h-14 rounded-2xl bg-slate-100 flex items-center justify-center mb-3'>
      <svg className='w-7 h-7 text-slate-400' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={1.5} d='M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4' /></svg>
    </div>
    <p className='text-sm font-bold text-slate-600'>{title}</p>
    {sub && <p className='text-xs text-slate-400 mt-1'>{sub}</p>}
  </div>
)

export const Spinner = () => (
  <div className='py-20 flex items-center justify-center'>
    <div className='w-8 h-8 border-3 border-blue-200 border-t-reception rounded-full animate-spin' />
  </div>
)

export const Avatar = ({ name, src, className = 'w-9 h-9' }) => {
  if (src)
    return <img src={src} alt='' className={`${className} rounded-full object-cover bg-slate-100`} />
  return (
    <div className={`${className} rounded-full bg-gradient-to-br from-blue-500 to-indigo-500 text-white flex items-center justify-center font-bold text-sm`}>
      {(name || '?').charAt(0).toUpperCase()}
    </div>
  )
}
