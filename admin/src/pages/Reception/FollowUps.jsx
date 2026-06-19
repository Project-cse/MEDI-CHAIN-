import React, { useContext, useEffect, useState } from 'react'
import { ReceptionContext } from '../../context/ReceptionContext'
import { PageWrap, RcHeader, Pill, Spinner, Avatar, EmptyState, patientName, doctorName } from './components'

const FollowUps = () => {
  const { getFollowups, useFollowup } = useContext(ReceptionContext)
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(null)

  const load = async () => { const r = await getFollowups(); if (r?.success) setRows(r.appointments || []); setLoading(false) }
  useEffect(() => { load() }, [])

  const act = async (id) => { setBusy(id); const r = await useFollowup(id); if (r?.success) await load(); setBusy(null) }

  return (
    <PageWrap>
      <RcHeader title='Follow-Ups' subtitle='Patients eligible for a follow-up visit'
        right={<button onClick={load} className='px-3 py-2 rounded-xl bg-reception text-white text-sm font-semibold shadow-sm hover:bg-blue-700'>Refresh</button>} />
      <div className='bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden'>
        {loading ? <Spinner /> : rows.length === 0 ? <EmptyState title='No follow-ups available' /> : (
          <div className='overflow-x-auto'>
            <table className='w-full text-sm'>
              <thead><tr className='text-left text-[11px] uppercase tracking-wider text-slate-400 border-b border-slate-100 bg-slate-50/60'>
                <th className='px-5 py-3 font-bold'>Patient</th><th className='px-5 py-3 font-bold'>Doctor</th><th className='px-5 py-3 font-bold'>Remaining</th><th className='px-5 py-3 font-bold'>Status</th><th className='px-5 py-3 font-bold text-right'>Action</th>
              </tr></thead>
              <tbody>
                {rows.map((a) => {
                  const v = a.verification || {}
                  return (
                    <tr key={a._id} className='border-b border-slate-50 hover:bg-slate-50/60'>
                      <td className='px-5 py-3'><div className='flex items-center gap-2'><Avatar name={patientName(a)} src={a.userData?.image} /><span className='font-semibold text-slate-700'>{patientName(a)}</span></div></td>
                      <td className='px-5 py-3 text-slate-600'>{doctorName(a)}</td>
                      <td className='px-5 py-3 text-slate-600'>{v.followupRemaining ?? 0}</td>
                      <td className='px-5 py-3'><Pill status={v.followupAvailable ? 'ELIGIBLE' : 'USED'} /></td>
                      <td className='px-5 py-3 text-right'>
                        <button disabled={busy === a._id || !v.followupAvailable} onClick={() => act(a._id)} className='px-3 py-1.5 rounded-lg bg-reception text-white text-xs font-bold hover:bg-blue-700 disabled:opacity-40'>Use Follow-up</button>
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

export default FollowUps
