import React, { useContext, useEffect, useState } from 'react'
import { ReceptionContext } from '../../context/ReceptionContext'
import { PageWrap, RcHeader, Avatar, EmptyState, Spinner } from './components'

const Patients = () => {
  const { searchPatients } = useContext(ReceptionContext)
  const [query, setQuery] = useState('')
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    const t = setTimeout(async () => {
      if (query.trim().length < 2) { setRows([]); return }
      setLoading(true)
      const r = await searchPatients(query.trim())
      if (r?.success) setRows(r.patients || [])
      setLoading(false)
    }, 350)
    return () => clearTimeout(t)
  }, [query])

  return (
    <PageWrap>
      <RcHeader title='Patients' subtitle='Search and look up patient records' />
      <div className='bg-white rounded-2xl border border-slate-100 shadow-sm p-4 mb-5'>
        <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder='Search by name, mobile, email or patient ID…'
          className='w-full px-4 py-3 rounded-xl border border-slate-200 bg-slate-50 focus:bg-white focus:border-reception outline-none text-sm font-medium' />
      </div>

      <div className='bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden'>
        {loading ? <Spinner /> : rows.length === 0 ? <EmptyState title='Search for a patient' sub='Type at least 2 characters to begin.' /> : (
          <div className='overflow-x-auto'>
            <table className='w-full text-sm'>
              <thead><tr className='text-left text-[11px] uppercase tracking-wider text-slate-400 border-b border-slate-100 bg-slate-50/60'>
                <th className='px-5 py-3 font-bold'>Patient</th><th className='px-5 py-3 font-bold'>Patient ID</th><th className='px-5 py-3 font-bold'>Mobile</th><th className='px-5 py-3 font-bold'>Gender / Age</th><th className='px-5 py-3 font-bold'>Email</th>
              </tr></thead>
              <tbody>
                {rows.map((p) => (
                  <tr key={p._id} className='border-b border-slate-50 hover:bg-slate-50/60'>
                    <td className='px-5 py-3'><div className='flex items-center gap-2'><Avatar name={p.name} src={p.image} /><span className='font-semibold text-slate-700'>{p.name}</span></div></td>
                    <td className='px-5 py-3 font-mono text-xs text-slate-500'>{p.publicId || '—'}</td>
                    <td className='px-5 py-3 text-slate-600'>{p.phone || '—'}</td>
                    <td className='px-5 py-3 text-slate-600'>{[p.gender, p.age].filter(Boolean).join(' · ') || '—'}</td>
                    <td className='px-5 py-3 text-slate-600'>{p.email || '—'}</td>
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
