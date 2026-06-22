import React, { useContext, useEffect, useState } from 'react'
import { ReceptionContext } from '../../context/ReceptionContext'
import { PageWrap, RcHeader, Pill, Spinner, Avatar, EmptyState, fmtMoney, patientName, doctorName, ReceptionTabs, RECEPTION_TAB_GROUPS } from './components'
import { ExportMenu } from '../../components/mc'

const Payments = () => {
  const { getPayments, collectPayment, requestRefund } = useContext(ReceptionContext)
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(null)

  const load = async () => { const r = await getPayments(); if (r?.success) setRows(r.appointments || []); setLoading(false) }
  useEffect(() => { load() }, [])

  const collect = async (id) => { setBusy(id); const r = await collectPayment(id, 'cash'); if (r?.success) await load(); setBusy(null) }
  const refund = async (id) => { setBusy(id); const r = await requestRefund(id); if (r?.success) await load(); setBusy(null) }

  const collected = rows.filter((r) => r.verification?.paymentOk).reduce((s, r) => s + Number(r.amount || 0), 0)

  const exportColumns = [
    { key: (a) => a.bookingId || `#${a._id}`, label: 'Booking' },
    { key: (a) => patientName(a), label: 'Patient' },
    { key: (a) => doctorName(a), label: 'Doctor' },
    { key: (a) => a.amount, label: 'Amount', format: (v) => fmtMoney(v) },
    { key: 'paymentMethod', label: 'Method' },
    { key: (a) => (a.verification?.paymentOk ? 'Paid' : 'Unpaid'), label: 'Status' },
  ]

  return (
    <PageWrap>
      <RcHeader title='Billing' subtitle="Today's payment collection"
        right={
          <div className='flex items-center gap-2'>
            <span className='px-3 py-2 rounded-xl bg-emerald-50 text-emerald-700 text-sm font-bold'>Collected: {fmtMoney(collected)}</span>
            <ExportMenu
              columns={exportColumns}
              rows={() => rows}
              filename='reception_billing'
              title='Reception · Billing'
              subtitle={`Collected ${fmtMoney(collected)} · ${rows.length} record(s)`}
              orientation='portrait'
            />
          </div>
        } />
      <ReceptionTabs items={RECEPTION_TAB_GROUPS.billing} />
      <div className='bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden'>
        {loading ? <Spinner /> : rows.length === 0 ? <EmptyState title='No payments today' /> : (
          <div className='overflow-x-auto'>
            <table className='w-full text-sm'>
              <thead><tr className='text-left text-[11px] uppercase tracking-wider text-slate-400 border-b border-slate-100 bg-slate-50/60'>
                <th className='px-4 py-3 font-bold'>Booking</th><th className='px-4 py-3 font-bold'>Patient</th><th className='px-4 py-3 font-bold'>Doctor</th><th className='px-4 py-3 font-bold'>Amount</th><th className='px-4 py-3 font-bold'>Method</th><th className='px-4 py-3 font-bold'>Status</th><th className='px-4 py-3 font-bold text-right'>Action</th>
              </tr></thead>
              <tbody>
                {rows.map((a) => {
                  const paid = a.verification?.paymentOk
                  return (
                    <tr key={a._id} className='border-b border-slate-50 hover:bg-slate-50/60'>
                      <td className='px-4 py-3 font-mono text-xs text-slate-500'>{a.bookingId || `#${a._id}`}</td>
                      <td className='px-4 py-3'><div className='flex items-center gap-2'><Avatar name={patientName(a)} src={a.userData?.image} /><span className='font-semibold text-slate-700'>{patientName(a)}</span></div></td>
                      <td className='px-4 py-3 text-slate-600'>{doctorName(a)}</td>
                      <td className='px-4 py-3 font-bold text-slate-700'>{fmtMoney(a.amount)}</td>
                      <td className='px-4 py-3 text-slate-600 capitalize'>{a.paymentMethod || '—'}</td>
                      <td className='px-4 py-3'><Pill status={paid ? 'PAID' : 'UNPAID'} /></td>
                      <td className='px-4 py-3 text-right'>
                        {paid ? (
                          <button disabled={busy === a._id} onClick={() => refund(a._id)} className='px-3 py-1.5 rounded-lg border border-rose-200 text-rose-600 text-xs font-bold hover:bg-rose-50 disabled:opacity-40'>Refund</button>
                        ) : (
                          <button disabled={busy === a._id} onClick={() => collect(a._id)} className='px-3 py-1.5 rounded-lg bg-emerald-500 text-white text-xs font-bold hover:bg-emerald-600 disabled:opacity-50'>Collect</button>
                        )}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </PageWrap>
  )
}

export default Payments
