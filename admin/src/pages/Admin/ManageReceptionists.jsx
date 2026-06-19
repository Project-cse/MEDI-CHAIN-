import React, { useContext, useEffect, useMemo, useState } from 'react'
import { AdminContext } from '../../context/AdminContext'
import { toast } from 'react-toastify'

const Stat = ({ label, value, tone }) => {
  const tones = { sky: 'bg-sky-50 text-sky-600', emerald: 'bg-emerald-50 text-emerald-600', slate: 'bg-slate-100 text-slate-500' }
  return (
    <div className='bg-white rounded-2xl border border-slate-100 shadow-sm p-4 flex items-center gap-4'>
      <div className={`w-12 h-12 rounded-2xl flex items-center justify-center font-black text-lg ${tones[tone]}`}>{value}</div>
      <p className='text-sm font-semibold text-slate-500'>{label}</p>
    </div>
  )
}

const inputCls = 'w-full px-3.5 py-2.5 rounded-xl border border-slate-200 bg-slate-50 focus:bg-white focus:border-admin outline-none text-sm font-medium text-slate-700'

const ManageReceptionists = () => {
  const {
    receptionists, getReceptionists, addReceptionist, toggleReceptionist, resetReceptionistPassword, deleteReceptionist,
    hospitals, getAllHospitals,
  } = useContext(AdminContext)
  const [form, setForm] = useState({ name: '', email: '', phone: '', password: '', hospitalId: '' })
  const [saving, setSaving] = useState(false)
  const [showForm, setShowForm] = useState(false)
  const [filterHospital, setFilterHospital] = useState('')

  useEffect(() => { getReceptionists(); getAllHospitals() }, [])

  const hospitalName = (id) => hospitals.find((h) => String(h._id || h.id) === String(id))?.name || '—'

  const filtered = useMemo(() => (
    filterHospital ? receptionists.filter((r) => String(r.hospital_id) === String(filterHospital)) : receptionists
  ), [receptionists, filterHospital])

  const stats = useMemo(() => ({
    total: filtered.length,
    active: filtered.filter((r) => r.is_active).length,
    disabled: filtered.filter((r) => !r.is_active).length,
  }), [filtered])

  const submit = async (e) => {
    e.preventDefault()
    if (!form.name || !form.email || !form.password || !form.hospitalId) return toast.error('Name, email, password and hospital are required')
    setSaving(true)
    const ok = await addReceptionist(form)
    setSaving(false)
    if (ok) { setForm({ name: '', email: '', phone: '', password: '', hospitalId: '' }); setShowForm(false) }
  }

  const onReset = async (r) => { const pw = window.prompt(`New password for ${r.name}:`); if (pw) await resetReceptionistPassword(r.id, pw) }
  const onDelete = async (r) => { if (window.confirm(`Remove receptionist "${r.name}"?`)) await deleteReceptionist(r.id) }

  return (
    <div className='p-4 sm:p-6 lg:p-8 max-w-[1300px] mx-auto w-full'>
      <div className='flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-6'>
        <div>
          <h1 className='text-2xl font-black text-slate-800 tracking-tight'>Manage Receptionists</h1>
          <p className='text-sm text-slate-500 mt-0.5'>Front-desk staff across all hospitals. Each receptionist is scoped to one hospital.</p>
        </div>
        <div className='flex items-center gap-2'>
          <select value={filterHospital} onChange={(e) => setFilterHospital(e.target.value)} className='px-3 py-2.5 rounded-xl bg-white border border-slate-200 text-sm font-semibold text-slate-600'>
            <option value=''>All Hospitals</option>
            {hospitals.map((h) => <option key={h._id || h.id} value={h._id || h.id}>{h.name}</option>)}
          </select>
          <button onClick={() => setShowForm((s) => !s)} className='px-4 py-2.5 rounded-xl bg-admin text-white text-sm font-bold shadow-sm hover:opacity-90 flex items-center gap-2'>
            <svg className='w-4 h-4' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M12 4v16m8-8H4' /></svg>
            Add
          </button>
        </div>
      </div>

      <div className='grid grid-cols-3 gap-3 sm:gap-4 mb-5'>
        <Stat label='Total' value={stats.total} tone='sky' />
        <Stat label='Active' value={stats.active} tone='emerald' />
        <Stat label='Disabled' value={stats.disabled} tone='slate' />
      </div>

      {showForm && (
        <form onSubmit={submit} className='bg-white rounded-2xl border border-slate-100 shadow-sm p-5 mb-5'>
          <p className='text-sm font-black text-slate-700 mb-4'>New Receptionist</p>
          <div className='grid sm:grid-cols-2 lg:grid-cols-3 gap-4'>
            <div className='space-y-1.5'><label className='text-xs font-bold text-slate-500'>Full Name *</label><input className={inputCls} value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder='Anita Sharma' /></div>
            <div className='space-y-1.5'><label className='text-xs font-bold text-slate-500'>Email *</label><input className={inputCls} type='email' value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} placeholder='reception@hospital.com' /></div>
            <div className='space-y-1.5'><label className='text-xs font-bold text-slate-500'>Hospital *</label>
              <select className={inputCls} value={form.hospitalId} onChange={(e) => setForm({ ...form, hospitalId: e.target.value })}>
                <option value=''>Select hospital…</option>
                {hospitals.map((h) => <option key={h._id || h.id} value={h._id || h.id}>{h.name}</option>)}
              </select>
            </div>
            <div className='space-y-1.5'><label className='text-xs font-bold text-slate-500'>Phone</label><input className={inputCls} value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} placeholder='9876543210' /></div>
            <div className='space-y-1.5'><label className='text-xs font-bold text-slate-500'>Password *</label><input className={inputCls} value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} placeholder='Min 6 characters' /></div>
          </div>
          <div className='flex justify-end gap-2 mt-4'>
            <button type='button' onClick={() => setShowForm(false)} className='px-4 py-2 rounded-xl border border-slate-200 text-slate-600 text-sm font-bold hover:bg-slate-50'>Cancel</button>
            <button type='submit' disabled={saving} className='px-5 py-2 rounded-xl bg-admin text-white text-sm font-bold hover:opacity-90 disabled:opacity-50'>{saving ? 'Creating…' : 'Create Receptionist'}</button>
          </div>
        </form>
      )}

      <div className='bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden'>
        {filtered.length === 0 ? (
          <div className='py-16 text-center'><p className='text-sm font-bold text-slate-600'>No receptionists found</p></div>
        ) : (
          <div className='overflow-x-auto'>
            <table className='w-full text-sm'>
              <thead><tr className='text-left text-[11px] uppercase tracking-wider text-slate-400 border-b border-slate-100 bg-slate-50/60'>
                <th className='px-5 py-3 font-bold'>Name</th><th className='px-5 py-3 font-bold'>Email</th><th className='px-5 py-3 font-bold'>Hospital</th><th className='px-5 py-3 font-bold'>Status</th><th className='px-5 py-3 font-bold text-right'>Actions</th>
              </tr></thead>
              <tbody>
                {filtered.map((r) => (
                  <tr key={r.id} className='border-b border-slate-50 hover:bg-slate-50/60'>
                    <td className='px-5 py-3'>
                      <div className='flex items-center gap-2'>
                        <div className='w-8 h-8 rounded-full bg-gradient-to-br from-sky-500 to-blue-500 text-white flex items-center justify-center font-bold text-xs'>{(r.name || '?').charAt(0).toUpperCase()}</div>
                        <span className='font-semibold text-slate-700'>{r.name}</span>
                      </div>
                    </td>
                    <td className='px-5 py-3 text-slate-600'>{r.email}</td>
                    <td className='px-5 py-3 text-slate-600'>{r.hospital_name || hospitalName(r.hospital_id)}</td>
                    <td className='px-5 py-3'>
                      <button onClick={() => toggleReceptionist(r.id, !r.is_active)} className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold ${r.is_active ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-500'}`}>
                        <span className={`w-1.5 h-1.5 rounded-full ${r.is_active ? 'bg-emerald-500' : 'bg-slate-400'}`} />
                        {r.is_active ? 'Active' : 'Disabled'}
                      </button>
                    </td>
                    <td className='px-5 py-3'>
                      <div className='flex items-center justify-end gap-2'>
                        <button onClick={() => onReset(r)} className='px-3 py-1.5 rounded-lg border border-slate-200 text-slate-600 text-xs font-bold hover:bg-slate-50'>Reset Password</button>
                        <button onClick={() => onDelete(r)} className='px-3 py-1.5 rounded-lg border border-rose-200 text-rose-600 text-xs font-bold hover:bg-rose-50'>Remove</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}

export default ManageReceptionists
