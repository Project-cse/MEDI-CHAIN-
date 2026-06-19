import React, { useContext, useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ReceptionContext } from '../../context/ReceptionContext'
import { PageWrap, RcHeader, Pill, Spinner, Avatar, fmtMoney, patientName, doctorName, tokenLabel } from './components'

const Box = ({ title, children, className = '' }) => (
  <div className={`bg-white rounded-2xl border border-slate-100 shadow-sm p-5 ${className}`}>
    <p className='text-xs font-black text-slate-500 uppercase tracking-wider mb-3'>{title}</p>
    {children}
  </div>
)

const Row = ({ label, value }) => (
  <div className='flex items-center justify-between py-1.5 text-sm'>
    <span className='text-slate-400'>{label}</span>
    <span className='font-bold text-slate-700 text-right'>{value || '—'}</span>
  </div>
)

const ConsultationSummary = () => {
  const { appointmentId } = useParams()
  const { getConsultationSummary, generateToken } = useContext(ReceptionContext)
  const navigate = useNavigate()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [sending, setSending] = useState(false)

  useEffect(() => { (async () => { const r = await getConsultationSummary(appointmentId); if (r?.success) setData(r); setLoading(false) })() }, [appointmentId])

  const send = async () => {
    setSending(true)
    const res = await generateToken(appointmentId)
    setSending(false)
    if (res?.success) navigate('/reception-queue')
  }

  if (loading) return <PageWrap><Spinner /></PageWrap>
  if (!data?.appointment) return <PageWrap><p className='text-slate-500'>Appointment not found.</p></PageWrap>

  const a = data.appointment
  const v = a.verification || {}
  const symptoms = a.selectedSymptoms || []
  const validUntil = a.validUntil ? new Date(a.validUntil).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : null

  return (
    <PageWrap>
      <RcHeader title='Consultation Ready Summary' subtitle='Review patient details before sending to doctor'
        right={<span className='px-3 py-2 rounded-xl bg-white border border-slate-200 text-xs font-bold text-slate-500'>APT #{a._id}</span>} />

      <div className='grid lg:grid-cols-3 gap-5'>
        <div className='lg:col-span-2 space-y-5'>
          <Box title='Patient Information'>
            <div className='flex items-center gap-4'>
              <Avatar name={patientName(a)} src={a.userData?.image} className='w-14 h-14' />
              <div>
                <p className='text-lg font-black text-slate-800'>{patientName(a)}</p>
                <p className='text-sm text-slate-500'>{a.patientAge ? `${a.patientAge} yrs` : ''} {a.actualPatient?.gender || a.userData?.gender || ''}</p>
                <p className='text-xs text-slate-400 font-mono'>{a.userData?.publicId || a.publicId || ''}</p>
              </div>
            </div>
          </Box>

          <Box title='Appointment Details'>
            <Row label='Type' value={a.isOnline ? 'Online' : 'Walk-in'} />
            <Row label='Booking ID' value={a.bookingId} />
            <Row label='Date & Time' value={`${a.slotDate || ''} ${a.slotTime || ''}`} />
            <Row label='Doctor' value={doctorName(a)} />
            <Row label='Token' value={tokenLabel(a)} />
          </Box>

          {data.previousVisits?.length > 0 && (
            <Box title='Previous Visits'>
              {data.previousVisits.map((p) => (
                <Row key={p.id} label={p.slotDate} value={`${p.doctorName || 'Doctor'} · ${(p.status || '').replace(/_/g, ' ')}`} />
              ))}
            </Box>
          )}
        </div>

        <div className='space-y-5'>
          <Box title='Current Complaint'>
            {symptoms.length ? (
              <div className='flex flex-wrap gap-2'>
                {symptoms.map((s, i) => <span key={i} className='px-2.5 py-1 rounded-lg bg-blue-50 text-reception text-xs font-semibold'>{s}</span>)}
              </div>
            ) : <p className='text-sm text-slate-400'>No complaint recorded.</p>}
          </Box>

          <Box title='Payment Status'>
            <div className='flex items-center justify-between'>
              <Pill status={v.paymentOk ? 'PAID' : 'UNPAID'} />
              <span className='font-black text-slate-800'>{fmtMoney(a.amount)}</span>
            </div>
          </Box>

          <Box title='Validity Status'>
            <div className='flex items-center justify-between mb-2'><Pill status={v.validityOk ? 'VALID' : 'EXPIRED'} /></div>
            {validUntil && <p className='text-xs text-slate-500'>Valid until {validUntil}</p>}
            {v.visitsRemaining != null && <p className='text-xs text-slate-500 mt-1'>Visits remaining: {v.visitsRemaining}</p>}
          </Box>

          <Box title='Follow-Up Status'>
            <Pill status={v.followupAvailable ? 'ELIGIBLE' : 'USED'} />
            {v.followupRemaining != null && <p className='text-xs text-slate-500 mt-2'>Remaining: {v.followupRemaining}</p>}
          </Box>

          <Box title={`Uploaded Reports`}>
            {v.reportUrl ? (
              <a href={v.reportUrl} target='_blank' rel='noreferrer' className='flex items-center gap-2 p-3 rounded-xl bg-slate-50 hover:bg-blue-50 text-sm font-semibold text-reception'>
                <svg className='w-5 h-5' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4' /></svg>
                Download Report
              </a>
            ) : <p className='text-sm text-slate-400'>No reports uploaded.</p>}
          </Box>
        </div>
      </div>

      <div className='flex justify-end mt-6'>
        <button disabled={sending} onClick={send} className='px-6 py-3 rounded-xl bg-reception text-white text-sm font-black hover:bg-blue-700 disabled:opacity-50 shadow-sm flex items-center gap-2'>
          <svg className='w-5 h-5' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M5 12h14M12 5l7 7-7 7' /></svg>
          {sending ? 'Sending…' : 'Send to Doctor Queue'}
        </button>
      </div>
    </PageWrap>
  )
}

export default ConsultationSummary
