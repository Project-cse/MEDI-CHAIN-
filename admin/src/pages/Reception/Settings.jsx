import React, { useContext } from 'react'
import { ReceptionContext } from '../../context/ReceptionContext'
import { PageWrap, RcHeader, Avatar } from './components'

const Field = ({ label, value }) => (
  <div className='py-3 border-b border-slate-50 flex items-center justify-between'>
    <span className='text-sm text-slate-400'>{label}</span>
    <span className='text-sm font-bold text-slate-700'>{value || '—'}</span>
  </div>
)

const Settings = () => {
  const { recInfo, logout } = useContext(ReceptionContext)
  return (
    <PageWrap>
      <RcHeader title='Settings' subtitle='Your reception desk account' />
      <div className='max-w-xl bg-white rounded-2xl border border-slate-100 shadow-sm p-6'>
        <div className='flex items-center gap-4 mb-5'>
          <Avatar name={recInfo?.name} className='w-16 h-16' />
          <div>
            <p className='text-lg font-black text-slate-800'>{recInfo?.name || 'Receptionist'}</p>
            <p className='text-sm text-slate-500'>Front Office · {recInfo?.hospitalName || 'Hospital'}</p>
          </div>
        </div>
        <Field label='Email' value={recInfo?.email} />
        <Field label='Hospital' value={recInfo?.hospitalName} />
        <Field label='Role' value='Receptionist' />
        <button onClick={() => { logout(); window.location.href = '/' }} className='mt-6 w-full py-3 rounded-xl bg-rose-50 text-rose-600 text-sm font-bold hover:bg-rose-100'>Log Out</button>
      </div>
    </PageWrap>
  )
}

export default Settings
