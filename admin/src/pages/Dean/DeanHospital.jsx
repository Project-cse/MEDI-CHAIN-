import React, { useContext, useEffect, useRef, useState } from 'react'
import { DeanContext } from '../../context/DeanContext'
import { toast } from 'react-toastify'
import { AdminPageLayout, PageHero, McCard } from '../../components/mc'

const inputCls = 'w-full px-4 py-2.5 border border-slate-200 rounded-lg text-sm bg-white focus:ring-2 focus:ring-sky-500 focus:border-sky-500 outline-none transition'

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp']
const MAX_SIZE = 2 * 1024 * 1024 // 2 MB

const readFileAsDataUrl = (file) => new Promise((resolve, reject) => {
  const reader = new FileReader()
  reader.onload = () => resolve(reader.result)
  reader.onerror = reject
  reader.readAsDataURL(file)
})

const DeanHospital = () => {
  const { deanToken, hospital, getHospital, updateHospital } = useContext(DeanContext)
  const [editing, setEditing] = useState(false)
  const [form, setForm] = useState({})
  const [saving, setSaving] = useState(false)
  // undefined = unchanged, '' = remove, dataURL string = new upload
  const [bannerChange, setBannerChange] = useState(undefined)
  const fileRef = useRef(null)

  useEffect(() => {
    if (deanToken) getHospital()
  }, [deanToken])

  useEffect(() => {
    if (hospital) setForm({
      name: hospital.name || '',
      address: hospital.address || '',
      contact: hospital.contact || '',
      specialization: hospital.specialization || '',
    })
  }, [hospital])

  const existingBanner = hospital?.background_image || hospital?.backgroundImage || null
  const bannerUrl = bannerChange !== undefined ? (bannerChange || null) : existingBanner

  const handleSelectImage = async (e) => {
    const file = e.target.files?.[0]
    e.target.value = '' // allow re-selecting same file
    if (!file) return
    if (!ALLOWED_TYPES.includes(file.type)) {
      toast.error('Unsupported file type. Use JPG, PNG, JPEG or WEBP.')
      return
    }
    if (file.size > MAX_SIZE) {
      toast.error('Image is too large. Maximum size is 2 MB.')
      return
    }
    try {
      const dataUrl = await readFileAsDataUrl(file)
      setBannerChange(dataUrl)
    } catch {
      toast.error('Could not read the selected image.')
    }
  }

  const handleRemoveImage = () => setBannerChange('')

  const startEditing = () => {
    setBannerChange(undefined)
    setEditing(true)
  }

  const cancelEditing = () => {
    setBannerChange(undefined)
    setEditing(false)
    if (hospital) setForm({
      name: hospital.name || '',
      address: hospital.address || '',
      contact: hospital.contact || '',
      specialization: hospital.specialization || '',
    })
  }

  const handleSave = async () => {
    setSaving(true)
    const payload = { ...form }
    if (bannerChange !== undefined) payload.backgroundImage = bannerChange
    const ok = await updateHospital(payload)
    if (ok) {
      setEditing(false)
      setBannerChange(undefined)
    }
    setSaving(false)
  }

  if (!hospital) return (
    <AdminPageLayout>
      <div className='flex items-center justify-center min-h-[60vh]'>
        <div className='animate-spin rounded-full h-10 w-10 border-b-2 border-sky-600' />
      </div>
    </AdminPageLayout>
  )

  const field = (label, key, placeholder = '') => (
    <div>
      <p className='text-[11px] font-bold uppercase tracking-wider text-sky-600 mb-1'>{label}</p>
      {editing ? (
        <input value={form[key] || ''} onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
          placeholder={placeholder} className={inputCls} />
      ) : (
        <p className='text-slate-800 text-sm font-medium py-1 break-words'>{hospital[key] || '—'}</p>
      )}
    </div>
  )

  const editAction = !editing ? (
    <button onClick={startEditing}
      className='px-4 py-2 bg-gradient-to-r from-sky-500 to-teal-500 text-white text-sm font-semibold rounded-lg shadow hover:shadow-lg transition'>
      Edit details
    </button>
  ) : (
    <div className='flex gap-2'>
      <button onClick={cancelEditing}
        className='px-4 py-2 bg-white border border-slate-200 text-slate-600 text-sm font-semibold rounded-lg hover:bg-slate-50 transition'>
        Cancel
      </button>
      <button onClick={handleSave} disabled={saving}
        className='px-4 py-2 bg-gradient-to-r from-sky-500 to-teal-500 text-white text-sm font-semibold rounded-lg shadow hover:shadow-lg transition disabled:opacity-50'>
        {saving ? 'Saving…' : 'Save Changes'}
      </button>
    </div>
  )

  return (
    <AdminPageLayout>
      <PageHero
        title="Hospital Tie ups"
        subtitle="Manage your hospital's information"
        features={['Verified Partner', 'Live Profile', 'Secure Records']}
      />

      {/* Hospital account banner — uses uploaded image, falls back to teal/blue gradient */}
      <div className='relative overflow-hidden rounded-2xl shadow-lg min-h-[150px] flex items-end'>
        {bannerUrl ? (
          <>
            <img src={bannerUrl} alt='Hospital banner' className='absolute inset-0 w-full h-full object-cover' />
            <div className='absolute inset-0 bg-gradient-to-r from-slate-900/85 via-slate-900/55 to-slate-900/20' />
          </>
        ) : (
          <div className='absolute inset-0 bg-gradient-to-r from-emerald-600 to-teal-600' />
        )}
        <div className='relative z-10 flex items-center gap-4 p-5 w-full'>
          <div className='w-14 h-14 bg-white/20 backdrop-blur rounded-xl flex items-center justify-center text-white shrink-0'>
            <svg className='w-7 h-7' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4' /></svg>
          </div>
          <div className='min-w-0 text-white'>
            <p className='text-[11px] font-semibold uppercase tracking-widest text-white/80'>Hospital Account</p>
            <h2 className='text-xl font-bold truncate drop-shadow'>{hospital.name}</h2>
            <p className='text-sm text-white/90 truncate'>{hospital.specialization}</p>
          </div>
        </div>
      </div>

      {/* Background image upload (edit mode only) */}
      {editing && (
        <McCard title="Hospital Background Image">
          <div className='flex flex-col sm:flex-row gap-5'>
            <div className='w-full sm:w-72 shrink-0'>
              <div className='aspect-[3/1] rounded-xl border border-slate-200 bg-slate-50 overflow-hidden flex items-center justify-center'>
                {bannerUrl ? (
                  <img src={bannerUrl} alt='Banner preview' className='w-full h-full object-cover' />
                ) : (
                  <div className='flex flex-col items-center gap-1 text-slate-400'>
                    <svg className='w-7 h-7' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z' /></svg>
                    <span className='text-[11px] font-medium'>No banner uploaded</span>
                  </div>
                )}
              </div>
            </div>

            <div className='flex-1 flex flex-col justify-center gap-3'>
              <div className='flex flex-wrap gap-2'>
                <button type='button' onClick={() => fileRef.current?.click()}
                  className='inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-gradient-to-r from-sky-500 to-teal-500 text-white text-sm font-semibold shadow hover:shadow-lg transition'>
                  <svg className='w-4 h-4' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12' /></svg>
                  {bannerUrl ? 'Change Image' : 'Upload Image'}
                </button>
                {bannerUrl && (
                  <button type='button' onClick={handleRemoveImage}
                    className='inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-white border border-rose-200 text-rose-600 text-sm font-semibold hover:bg-rose-50 transition'>
                    <svg className='w-4 h-4' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16' /></svg>
                    Remove
                  </button>
                )}
              </div>
              <p className='text-[11px] text-slate-400'>Recommended: 1200 × 400 px, JPG/PNG/WebP. Max size 2 MB.</p>
              <input ref={fileRef} type='file' accept='image/jpeg,image/png,image/webp' hidden onChange={handleSelectImage} />
            </div>
          </div>
        </McCard>
      )}

      {/* Details card */}
      <McCard title="Hospital Information" action={editAction}>
        <div className='space-y-5'>
          {field('Hospital Name', 'name', 'Enter hospital name')}
          {field('Address', 'address', 'Full address')}
          {field('Contact Number', 'contact', 'Phone number')}
          {field('Specialization', 'specialization', 'E.g. Cardiology, General Medicine')}

          <div className='pt-3 border-t border-slate-100 flex flex-wrap gap-x-6 gap-y-1'>
            <p className='text-xs text-slate-400'>Hospital Type: <span className='font-semibold text-slate-600'>{hospital.type || '—'}</span></p>
            <p className='text-xs text-slate-400'>Hospital ID: <span className='font-semibold text-slate-600'>{hospital.id}</span></p>
          </div>
        </div>
      </McCard>
    </AdminPageLayout>
  )
}

export default DeanHospital
