import axios from 'axios'
import React, { useContext, useEffect, useMemo, useState } from 'react'
import { saveAuthTokens } from '../services/authApi'
import { DoctorContext } from '../context/DoctorContext'
import { AdminContext } from '../context/AdminContext'
import { DeanContext } from '../context/DeanContext'
import { toast } from 'react-toastify'
import { useNavigate } from 'react-router-dom'

const ROLE_OPTIONS = [
  {
    id: 'doctor',
    label: 'Doctor',
    title: 'Doctor Portal',
    sub: 'CLINICAL EXPERT',
    placeholder: 'doc@id.com',
    btnText: 'Professional Login',
    endpoint: '/api/doctor/login',
    dashboard: '/doctor-dashboard',
    tokenKey: 'doctor',
    colorClass: {
      icon: 'from-indigo-400 to-indigo-600',
      btn: 'bg-[#6366f1] hover:bg-[#4f46e5]',
      textLabel: 'text-indigo-600',
      ring: 'focus:border-indigo-400',
      select: 'border-indigo-200 text-indigo-700',
    },
    icon: (
      <svg className='w-8 h-8' fill='none' stroke='currentColor' strokeWidth='2' viewBox='0 0 24 24'>
        <path strokeLinecap='round' strokeLinejoin='round' d='M9 12h6m-3-3v6m-3-9a11.955 11.955 0 018.618 3.04A12.02 12.02 0 0121 9c0 5.591-3.824 10.29-9 11.622-5.176-1.332-9-6.03-9-11.622 0-1.042-.133-2.052-.382-3.016z' />
      </svg>
    ),
    showForgot: true,
  },
  {
    id: 'dean',
    label: 'Dean',
    title: 'DEAN Portal',
    sub: 'OPERATIONS HEAD',
    placeholder: 'dean@id.com',
    btnText: 'Controller Login',
    endpoint: '/api/dean/login',
    dashboard: '/dean-dashboard',
    tokenKey: 'dean',
    colorClass: {
      icon: 'from-teal-400 to-teal-600',
      btn: 'bg-[#14b8a6] hover:bg-[#0d9488]',
      textLabel: 'text-teal-600',
      ring: 'focus:border-teal-400',
      select: 'border-teal-200 text-teal-700',
    },
    icon: (
      <svg className='w-8 h-8' fill='none' stroke='currentColor' strokeWidth='2' viewBox='0 0 24 24'>
        <path strokeLinecap='round' strokeLinejoin='round' d='M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4' />
      </svg>
    ),
    showForgot: false,
  },
  {
    id: 'admin',
    label: 'Admin',
    title: 'Super Admin',
    sub: 'SYSTEM MASTER',
    placeholder: 'admin@id.com',
    btnText: 'Master Login',
    endpoint: '/api/admin/login',
    dashboard: '/admin-dashboard',
    tokenKey: 'admin',
    colorClass: {
      icon: 'from-sky-400 to-sky-600',
      btn: 'bg-[#0ea5e9] hover:bg-[#0284c7]',
      textLabel: 'text-sky-600',
      ring: 'focus:border-sky-400',
      select: 'border-sky-200 text-sky-700',
    },
    icon: (
      <svg className='w-8 h-8' fill='none' stroke='currentColor' strokeWidth='2' viewBox='0 0 24 24'>
        <path strokeLinecap='round' strokeLinejoin='round' d='M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z' />
      </svg>
    ),
    showForgot: false,
  },
]

const PortalCard = ({
  title,
  sub,
  icon,
  email,
  setEmail,
  password,
  setPassword,
  onSubmit,
  loading,
  showPwd,
  setShowPwd,
  colorClass,
  btnText,
  placeholder,
  isDoctor,
  navigate,
}) => (
  <div className='flex-1 flex flex-col items-center justify-center p-4 sm:p-6 transition-all duration-500 min-h-0'>
    <div className='w-full max-w-[360px] bg-white/95 backdrop-blur-2xl rounded-[2.5rem] p-6 sm:p-10 shadow-[0_30px_70px_rgba(0,0,0,0.06)] border border-white/50 flex flex-col gap-6 animate-portal-in'>
      <div className='text-center'>
        <div className={`mx-auto mb-5 w-14 h-14 rounded-2xl bg-gradient-to-br ${colorClass.icon} flex items-center justify-center shadow-xl shadow-blue-100/50 text-white`}>
          {icon}
        </div>
        <h1 className='text-2xl font-black text-gray-900 tracking-tight font-outfit mb-2'>{title}</h1>
        <div className='inline-block px-4 py-1.5 bg-gray-50 rounded-full'>
          <p className='text-[10px] text-gray-500 font-black uppercase tracking-[0.2em]'>{sub}</p>
        </div>
      </div>

      <form onSubmit={onSubmit} className='space-y-5'>
        <div className='space-y-2'>
          <label className={`block text-[11px] font-black uppercase tracking-widest ${colorClass.textLabel} ml-2`}>Email</label>
          <input
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            type='email'
            required
            autoComplete='username'
            placeholder={placeholder}
            className={`w-full px-5 py-3.5 rounded-[1.25rem] border-2 border-slate-100 bg-slate-50/50 focus:bg-white ${colorClass.ring} outline-none transition-all text-sm font-bold text-gray-800 placeholder:text-slate-300`}
          />
        </div>

        <div className='space-y-2'>
          <div className='flex justify-between items-center ml-2'>
            <label className={`block text-[11px] font-black uppercase tracking-widest ${colorClass.textLabel}`}>Password</label>
            {isDoctor && (
              <button
                type='button'
                onClick={() => navigate('/doctor-forgot-password')}
                className='text-[10px] font-black text-slate-400 hover:text-indigo-600 transition-colors tracking-wider'
              >
                RECOVER?
              </button>
            )}
          </div>
          <div className='relative'>
            <input
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              type={showPwd ? 'text' : 'password'}
              required
              autoComplete='current-password'
              placeholder='••••••••'
              className={`w-full px-5 py-3.5 pr-12 rounded-[1.25rem] border-2 border-slate-100 bg-slate-50/50 focus:bg-white ${colorClass.ring} outline-none transition-all text-sm font-bold text-gray-800 placeholder:text-slate-300`}
            />
            <button type='button' onClick={() => setShowPwd(!showPwd)} className='absolute right-4 top-3.5 text-slate-300 hover:text-indigo-500 transition-colors' aria-label={showPwd ? 'Hide password' : 'Show password'}>
              {showPwd ? (
                <svg className='w-5 h-5' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2.5} d='M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.29 3.29m13.42 13.42l-3.29-3.29M3 3l18 18' /></svg>
              ) : (
                <svg className='w-5 h-5' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2.5} d='M15 12a3 3 0 11-6 0 3 3 0 016 0z' /><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2.5} d='M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z' /></svg>
              )}
            </button>
          </div>
        </div>

        <button type='submit' disabled={loading} className={`group w-full py-4 sm:py-5 rounded-[1.5rem] font-black text-white ${colorClass.btn} shadow-lg active:scale-[0.98] hover:shadow-xl transition-all text-xs uppercase tracking-[0.2em] flex items-center justify-center gap-3`}>
          {loading ? <div className='w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin' /> : null}
          <span>{loading ? 'Validating...' : btnText}</span>
        </button>
      </form>
    </div>
  </div>
)

const MobileUnifiedLogin = ({
  roleId,
  setRoleId,
  email,
  setEmail,
  password,
  setPassword,
  showPwd,
  setShowPwd,
  loading,
  onSubmit,
  navigate,
}) => {
  const role = useMemo(() => ROLE_OPTIONS.find((r) => r.id === roleId) || ROLE_OPTIONS[0], [roleId])

  return (
    <div className='lg:hidden min-h-[100dvh] w-full flex flex-col items-center justify-center px-4 py-8 bg-gradient-to-b from-slate-50 via-white to-slate-100 font-inter safe-area-inset'>
      <div className='w-full max-w-md'>
        <div className='text-center mb-6'>
          <div className='inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-blue-600 to-teal-500 text-white font-black text-xl shadow-lg mb-4'>
            MC
          </div>
          <h1 className='text-2xl font-black text-gray-900 font-outfit'>MediChain Portal</h1>
          <p className='text-sm text-gray-500 mt-1'>Sign in to your workspace</p>
        </div>

        <div className='bg-white rounded-3xl shadow-xl border border-slate-100 p-5 sm:p-7 animate-portal-in'>
          <form onSubmit={onSubmit} className='space-y-4'>
            <div className='space-y-2'>
              <label htmlFor='login-role' className='block text-[11px] font-black uppercase tracking-widest text-slate-500 ml-1'>
                Login as
              </label>
              <div className='relative'>
                <select
                  id='login-role'
                  value={roleId}
                  onChange={(e) => setRoleId(e.target.value)}
                  className={`w-full appearance-none px-4 py-3.5 pr-10 rounded-2xl border-2 bg-slate-50 font-bold text-sm outline-none transition-all ${role.colorClass.select} ${role.colorClass.ring}`}
                >
                  {ROLE_OPTIONS.map((opt) => (
                    <option key={opt.id} value={opt.id}>
                      {opt.label}
                    </option>
                  ))}
                </select>
                <svg className='pointer-events-none absolute right-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
                  <path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M19 9l-7 7-7-7' />
                </svg>
              </div>
            </div>

            <div className={`flex items-center gap-3 p-3 rounded-2xl bg-gradient-to-r ${role.colorClass.icon} text-white`}>
              <div className='w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center shrink-0'>
                {React.cloneElement(role.icon, { className: 'w-5 h-5' })}
              </div>
              <div className='min-w-0'>
                <p className='font-bold text-sm truncate'>{role.title}</p>
                <p className='text-[10px] uppercase tracking-wider opacity-80'>{role.sub}</p>
              </div>
            </div>

            <div className='space-y-2'>
              <label className={`block text-[11px] font-black uppercase tracking-widest ${role.colorClass.textLabel} ml-1`}>Email</label>
              <input
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                type='email'
                required
                autoComplete='username'
                placeholder={role.placeholder}
                className={`w-full px-4 py-3.5 rounded-2xl border-2 border-slate-100 bg-slate-50 focus:bg-white ${role.colorClass.ring} outline-none text-sm font-semibold`}
              />
            </div>

            <div className='space-y-2'>
              <div className='flex justify-between items-center ml-1'>
                <label className={`block text-[11px] font-black uppercase tracking-widest ${role.colorClass.textLabel}`}>Password</label>
                {role.showForgot && (
                  <button type='button' onClick={() => navigate('/doctor-forgot-password')} className='text-[10px] font-bold text-slate-400 hover:text-indigo-600'>
                    Forgot?
                  </button>
                )}
              </div>
              <div className='relative'>
                <input
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  type={showPwd ? 'text' : 'password'}
                  required
                  autoComplete='current-password'
                  placeholder='••••••••'
                  className={`w-full px-4 py-3.5 pr-12 rounded-2xl border-2 border-slate-100 bg-slate-50 focus:bg-white ${role.colorClass.ring} outline-none text-sm font-semibold`}
                />
                <button type='button' onClick={() => setShowPwd(!showPwd)} className='absolute right-3 top-3 text-slate-400' aria-label='Toggle password'>
                  {showPwd ? 'Hide' : 'Show'}
                </button>
              </div>
            </div>

            <button type='submit' disabled={loading} className={`w-full py-4 rounded-2xl font-black text-white text-sm uppercase tracking-wider ${role.colorClass.btn} shadow-md disabled:opacity-60`}>
              {loading ? 'Signing in…' : role.btnText}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}

const Login = () => {
  const [adminEmail, setAdminEmail] = useState('')
  const [adminPassword, setAdminPassword] = useState('')
  const [doctorEmail, setDoctorEmail] = useState('')
  const [doctorPassword, setDoctorPassword] = useState('')
  const [deanEmail, setDeanEmail] = useState('')
  const [deanPassword, setDeanPassword] = useState('')

  const [mobileRole, setMobileRole] = useState('doctor')
  const [mobileEmail, setMobileEmail] = useState('')
  const [mobilePassword, setMobilePassword] = useState('')
  const [mobileShowPwd, setMobileShowPwd] = useState(false)

  const [isAdminLoading, setIsAdminLoading] = useState(false)
  const [isDoctorLoading, setIsDoctorLoading] = useState(false)
  const [isDeanLoading, setIsDeanLoading] = useState(false)
  const [isMobileLoading, setIsMobileLoading] = useState(false)

  const [showAdminPwd, setShowAdminPwd] = useState(false)
  const [showDoctorPwd, setShowDoctorPwd] = useState(false)
  const [showDeanPwd, setShowDeanPwd] = useState(false)

  const backendUrl = import.meta.env.VITE_BACKEND_URL
  const { setDToken } = useContext(DoctorContext)
  const { setAToken } = useContext(AdminContext)
  const { setDeanToken, setDeanInfo } = useContext(DeanContext)
  const navigate = useNavigate()

  useEffect(() => {
    document.body.classList.add('login-route-active')
    return () => document.body.classList.remove('login-route-active')
  }, [])

  const loginWithRole = async (roleConfig, email, password, setLoading) => {
    setLoading(true)
    try {
      const { data } = await axios.post(
        backendUrl + roleConfig.endpoint,
        { email, password },
        { withCredentials: true }
      )
      if (!data.success) {
        toast.error(data.message)
        return
      }

      if (roleConfig.tokenKey === 'admin') {
        setAToken(data.token)
        saveAuthTokens('admin', data.token)
        toast.success('Admin login successful!')
        navigate(roleConfig.dashboard)
      } else if (roleConfig.tokenKey === 'dean') {
        setDeanToken(data.token)
        setDeanInfo(data.dean)
        saveAuthTokens('dean', data.token)
        sessionStorage.setItem('deanInfo', JSON.stringify(data.dean))
        toast.success('DEAN login successful!')
        navigate(roleConfig.dashboard)
      } else {
        setDToken(data.token)
        saveAuthTokens('doctor', data.token)
        toast.success('Doctor login successful!')
        navigate(roleConfig.dashboard)
      }
    } catch (err) {
      if (!err.response) {
        toast.error('Cannot reach backend. Check VITE_BACKEND_URL and that the API is running.')
      } else {
        toast.error(err.response?.data?.message || 'Login failed')
      }
    } finally {
      setLoading(false)
    }
  }

  const onAdminSubmit = (e) => {
    e.preventDefault()
    loginWithRole(ROLE_OPTIONS.find((r) => r.id === 'admin'), adminEmail, adminPassword, setIsAdminLoading)
  }

  const onDeanSubmit = (e) => {
    e.preventDefault()
    loginWithRole(ROLE_OPTIONS.find((r) => r.id === 'dean'), deanEmail, deanPassword, setIsDeanLoading)
  }

  const onDoctorSubmit = (e) => {
    e.preventDefault()
    loginWithRole(ROLE_OPTIONS.find((r) => r.id === 'doctor'), doctorEmail, doctorPassword, setIsDoctorLoading)
  }

  const onMobileSubmit = (e) => {
    e.preventDefault()
    const role = ROLE_OPTIONS.find((r) => r.id === mobileRole) || ROLE_OPTIONS[0]
    loginWithRole(role, mobileEmail, mobilePassword, setIsMobileLoading)
  }

  const adminRole = ROLE_OPTIONS.find((r) => r.id === 'admin')
  const deanRole = ROLE_OPTIONS.find((r) => r.id === 'dean')
  const doctorRole = ROLE_OPTIONS.find((r) => r.id === 'doctor')

  return (
    <div className='min-h-[100dvh] w-full font-inter bg-slate-50'>
      <MobileUnifiedLogin
        roleId={mobileRole}
        setRoleId={setMobileRole}
        email={mobileEmail}
        setEmail={setMobileEmail}
        password={mobilePassword}
        setPassword={setMobilePassword}
        showPwd={mobileShowPwd}
        setShowPwd={setMobileShowPwd}
        loading={isMobileLoading}
        onSubmit={onMobileSubmit}
        navigate={navigate}
      />

      <div className='hidden lg:flex min-h-[100dvh] w-full flex-row overflow-hidden'>
        <div className='flex-1 h-screen bg-white flex flex-col items-center justify-center relative overflow-hidden'>
          <div className='absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(56,189,248,0.08),transparent_50%)]' />
          <PortalCard
            title={adminRole.title}
            sub={adminRole.sub}
            icon={adminRole.icon}
            email={adminEmail}
            setEmail={setAdminEmail}
            password={adminPassword}
            setPassword={setAdminPassword}
            onSubmit={onAdminSubmit}
            loading={isAdminLoading}
            showPwd={showAdminPwd}
            setShowPwd={setShowAdminPwd}
            colorClass={adminRole.colorClass}
            btnText={adminRole.btnText}
            placeholder={adminRole.placeholder}
            navigate={navigate}
          />
        </div>

        <div className='w-px h-2/3 self-center bg-slate-100' />

        <div className='flex-1 h-screen bg-slate-50 flex flex-col items-center justify-center relative overflow-hidden'>
          <div className='absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(20,184,166,0.08),transparent_50%)]' />
          <PortalCard
            title={deanRole.title}
            sub={deanRole.sub}
            icon={deanRole.icon}
            email={deanEmail}
            setEmail={setDeanEmail}
            password={deanPassword}
            setPassword={setDeanPassword}
            onSubmit={onDeanSubmit}
            loading={isDeanLoading}
            showPwd={showDeanPwd}
            setShowPwd={setShowDeanPwd}
            colorClass={deanRole.colorClass}
            btnText={deanRole.btnText}
            placeholder={deanRole.placeholder}
            navigate={navigate}
          />
        </div>

        <div className='w-px h-2/3 self-center bg-slate-100' />

        <div className='flex-1 h-screen bg-white flex flex-col items-center justify-center relative overflow-hidden'>
          <div className='absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(99,102,241,0.08),transparent_50%)]' />
          <PortalCard
            title={doctorRole.title}
            sub={doctorRole.sub}
            icon={doctorRole.icon}
            email={doctorEmail}
            setEmail={setDoctorEmail}
            password={doctorPassword}
            setPassword={setDoctorPassword}
            onSubmit={onDoctorSubmit}
            loading={isDoctorLoading}
            showPwd={showDoctorPwd}
            setShowPwd={setShowDoctorPwd}
            colorClass={doctorRole.colorClass}
            btnText={doctorRole.btnText}
            placeholder={doctorRole.placeholder}
            isDoctor
            navigate={navigate}
          />
        </div>
      </div>

      <style>{`
        .font-outfit { font-family: 'Outfit', sans-serif !important; }
        .font-inter { font-family: 'Inter', sans-serif !important; }
        .safe-area-inset {
          padding-top: max(1rem, env(safe-area-inset-top));
          padding-bottom: max(1rem, env(safe-area-inset-bottom));
        }
        @keyframes portalIn { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
        .animate-portal-in { animation: portalIn 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
      `}</style>
    </div>
  )
}

export default Login
