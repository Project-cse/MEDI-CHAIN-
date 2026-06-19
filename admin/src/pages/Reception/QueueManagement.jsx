import React, { useContext, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ReceptionContext } from '../../context/ReceptionContext'
import {
  PageWrap, RcHeader, Pill, Spinner, Avatar, EmptyState,
  patientName, doctorName, tokenLabel,
} from './components'

const TABS = [
  { id: 'waiting', label: 'Waiting' },
  { id: 'ready', label: 'Ready' },
  { id: 'inConsultation', label: 'In Consultation' },
  { id: 'completed', label: 'Completed' },
]

const QueueManagement = () => {
  const { getQueue, queueAction, getDoctors } = useContext(ReceptionContext)
  const navigate = useNavigate()
  const [groups, setGroups] = useState({})
  const [loading, setLoading] = useState(true)
  const [tab, setTab] = useState('waiting')
  const [doctors, setDoctors] = useState([])
  const [docFilter, setDocFilter] = useState('')
  const [busy, setBusy] = useState(null)

  const load = async () => {
    setLoading(true)
    const res = await getQueue(docFilter || undefined)
    if (res?.success) setGroups(res.groups || {})
    setLoading(false)
  }
  useEffect(() => { load() }, [docFilter])
  useEffect(() => { (async () => { const r = await getDoctors(); if (r?.success) setDoctors(r.doctors || []) })() }, [])

  const rows = groups[tab] || []

  const act = async (id, action) => {
    setBusy(id)
    const res = await queueAction(id, action)
    if (res?.success) await load()
    setBusy(null)
  }

  return (
    <PageWrap>
      <RcHeader title='Queue Management' subtitle="Manage today's patient queue"
        right={
          <select value={docFilter} onChange={(e) => setDocFilter(e.target.value)} className='px-3 py-2 rounded-xl bg-white border border-slate-200 text-sm font-semibold text-slate-600 shadow-sm'>
            <option value=''>All Doctors</option>
            {doctors.map((d) => <option key={d._id} value={d._id}>{d.name}</option>)}
          </select>
        } />

      <div className='flex items-center gap-2 mb-4 flex-wrap'>
        {TABS.map((t) => (
          <button key={t.id} onClick={() => setTab(t.id)}
            className={`px-4 py-2 rounded-xl text-sm font-bold transition-all ${tab === t.id ? 'bg-reception text-white shadow-sm' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'}`}>
            {t.label} <span className='opacity-70'>({(groups[t.id] || []).length})</span>
          </button>
        ))}
      </div>

      <div className='bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden'>
        {loading ? <Spinner /> : rows.length === 0 ? <EmptyState title='No patients in this stage' /> : (
          <div className='overflow-x-auto'>
            <table className='w-full text-sm'>
              <thead><tr className='text-left text-[11px] uppercase tracking-wider text-slate-400 border-b border-slate-100 bg-slate-50/60'>
                <th className='px-4 py-3 font-bold'>Token</th>
                <th className='px-4 py-3 font-bold'>Patient</th>
                <th className='px-4 py-3 font-bold'>Type</th>
                <th className='px-4 py-3 font-bold'>Doctor</th>
                <th className='px-4 py-3 font-bold'>Status</th>
                <th className='px-4 py-3 font-bold text-right'>Actions</th>
              </tr></thead>
              <tbody>
                {rows.map((a) => (
                  <tr key={a._id} className='border-b border-slate-50 hover:bg-slate-50/60'>
                    <td className='px-4 py-3 font-black text-reception'>{tokenLabel(a)}</td>
                    <td className='px-4 py-3'><div className='flex items-center gap-2'><Avatar name={patientName(a)} src={a.userData?.image} /><span className='font-semibold text-slate-700'>{patientName(a)}</span></div></td>
                    <td className='px-4 py-3 text-slate-600'>{a.isOnline ? 'Online' : 'Walk-in'}</td>
                    <td className='px-4 py-3 text-slate-600'>{doctorName(a)}</td>
                    <td className='px-4 py-3'><Pill status={a.deskStatus} /></td>
                    <td className='px-4 py-3'>
                      <div className='flex items-center justify-end gap-2'>
                        {tab === 'waiting' && (
                          <button disabled={busy === a._id} onClick={() => act(a._id, 'ready')} className='px-3 py-1.5 rounded-lg bg-emerald-500 text-white text-xs font-bold hover:bg-emerald-600 disabled:opacity-50'>Mark Ready</button>
                        )}
                        {(tab === 'waiting' || tab === 'ready') && (
                          <button disabled={busy === a._id} onClick={() => act(a._id, 'no-show')} className='px-3 py-1.5 rounded-lg bg-orange-500 text-white text-xs font-bold hover:bg-orange-600 disabled:opacity-50'>No-Show</button>
                        )}
                        <button onClick={() => navigate(`/reception-summary/${a._id}`)} className='px-3 py-1.5 rounded-lg border border-slate-200 text-slate-500 text-xs font-bold hover:bg-slate-50'>Summary</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        <div className='flex items-center gap-3 px-4 py-4 border-t border-slate-100 flex-wrap'>
          <button onClick={load} className='px-4 py-2 rounded-xl bg-reception text-white text-sm font-bold hover:bg-blue-700'>Refresh Queue</button>
          <span className='text-xs text-slate-400'>Mark patients ready when their token is called by the doctor.</span>
        </div>
      </div>
    </PageWrap>
  )
}

export default QueueManagement
