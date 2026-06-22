import React, { useContext } from 'react'
import { assets } from '../assets/assets'
import { NavLink, useLocation } from 'react-router-dom'
import { AdminContext } from '../context/AdminContext'
import { DoctorContext } from '../context/DoctorContext'
import { DeanContext } from '../context/DeanContext'
import { ReceptionContext } from '../context/ReceptionContext'
import { AppContext } from '../context/AppContext'

const RecIcon = ({ d }) => (
  <svg className='w-5 h-5 flex-shrink-0' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
    <path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d={d} />
  </svg>
)

// Consolidated front-desk navigation. Each group's `match` routes keep the
// item highlighted while the user moves between its secondary tabs.
const RECEPTION_LINKS = [
  { to: '/reception-dashboard', label: 'Dashboard', match: ['/reception-dashboard'], d: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6' },
  { to: '/reception-online', label: 'Check-In', match: ['/reception-online', '/reception-walkin', '/reception-checkin'], d: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4' },
  { to: '/reception-queue', label: 'Queue', match: ['/reception-queue', '/reception-noshows'], d: 'M4 6h16M4 10h16M4 14h16M4 18h16' },
  { to: '/reception-patients', label: 'Patients', match: ['/reception-patients', '/reception-followups'], d: 'M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m6-1.13a4 4 0 10-4-4 4 4 0 004 4z' },
  { to: '/reception-payments', label: 'Billing', match: ['/reception-payments', '/reception-refunds'], d: 'M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z' },
  { to: '/reception-reports', label: 'Reports', match: ['/reception-reports'], d: 'M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z' },
  { to: '/reception-settings', label: 'Settings', match: ['/reception-settings'], d: 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z M15 12a3 3 0 11-6 0 3 3 0 016 0z' },
]

const Sidebar = () => {

  const { aToken } = useContext(AdminContext)
  const { dToken } = useContext(DoctorContext)
  const { deanToken } = useContext(DeanContext)
  const { recToken, recInfo, logout: recLogout } = useContext(ReceptionContext)
  const { sidebarOpen, setSidebarOpen } = useContext(AppContext)
  const location = useLocation()

  const closeSidebar = () => {
    if (window.innerWidth < 1024) {
      setSidebarOpen(false)
    }
  }

  return (
    <div className={`
      fixed lg:static inset-y-0 left-0 z-30
      transition-transform duration-300 ease-out
      ${sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
      w-[min(280px,88vw)] lg:w-auto
      bg-mc-surface border-r border-mc-border
      h-full max-h-[100dvh] lg:min-h-screen
      flex flex-col overflow-hidden
      pt-[env(safe-area-inset-top)]
    `}>
      <div className='lg:hidden flex items-center justify-between px-4 py-3 border-b border-mc-border shrink-0'>
        <p className='text-sm font-bold text-mc-text'>Menu</p>
        <button
          type='button'
          onClick={() => setSidebarOpen(false)}
          className='p-2 rounded-lg hover:bg-mc-surface-elevated'
          aria-label='Close menu'
        >
          <svg className='w-5 h-5' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
            <path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M6 18L18 6M6 6l12 12' />
          </svg>
        </button>
      </div>

      <div className='flex-1 overflow-y-auto overflow-x-hidden overscroll-contain pb-[max(1.5rem,env(safe-area-inset-bottom))]'>
      {/* ── Admin Menu — (Super System Controller) ────────────────────────── */}
      {
        aToken && <ul className='text-[#515151] mt-5'>
          <NavLink onClick={closeSidebar} to={'/admin-dashboard'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.home_icon} alt="" />
            <p className='md:block'>Dashboard</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/revenue-analytics'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" /></svg>
            <p className='md:block'>Revenue Hub</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/all-appointments'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.appointment_icon} alt="" />
            <p className='md:block'>Appointments</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/doctor-list'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.people_icon} alt="" />
            <p className='md:block'>Doctors List</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/hospital-tieups'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" /></svg>
            <p className='md:block'>Hospital Tie ups</p>
          </NavLink>

          <div className='h-px bg-gray-100 my-2 mx-9 opacity-50' />

          <NavLink onClick={closeSidebar} to={'/manage-deans'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
             <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 14l9-5-9-5-9 5 9 5z" /><path d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14zm-4 6v-7.5l4-2.222" /></svg>
            <p className='md:block'>Manage Deans</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/manage-labs'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.list_icon} alt="" />
            <p className='md:block'>Labs</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/manage-blood-banks'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.doctor_icon} alt="" />
            <p className='md:block'>Blood Banks</p>
          </NavLink>


          <NavLink onClick={closeSidebar} to={'/manage-users'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.patients_icon} alt="" />
            <p className='md:block'>Users</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/manage-receptionists'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <svg className='w-5 h-5' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M3 21h18M3 10h18M5 6l7-3 7 3M4 10v11m16-11v11M8 14v3m4-3v3m4-3v3' /></svg>
            <p className='md:block'>Receptionists</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/refund-management'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" /></svg>
            <p className='md:block'>Refunds</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/manage-admins'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" /></svg>
            <p className='md:block'>Admins</p>
          </NavLink>

          <li onClick={() => { sessionStorage.clear(); window.location.reload(); }} className='flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer hover:bg-rose-50 text-rose-500 mt-10 transition-all font-bold text-xs uppercase tracking-widest'>
            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" /></svg>
            <p className='md:block'>Log Out</p>
          </li>
        </ul>
      }

      {/* ── DEAN Menu — (Hospital Specific Operations) ──────────────────── */}
      {
        deanToken && <ul className='text-slate-600 mt-5'>
          <NavLink onClick={closeSidebar} to={'/dean-dashboard'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0fdfa] border-r-4 border-dean text-dean font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.home_icon} alt="" />
            <p className='md:block'>Dashboard</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/dean-appointments'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0fdfa] border-r-4 border-dean text-dean font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.appointment_icon} alt="" />
            <p className='md:block'>Appointments</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/dean-doctors'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0fdfa] border-r-4 border-dean text-dean font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.people_icon} alt="" />
            <p className='md:block'>Doctors List</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/dean-patients'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0fdfa] border-r-4 border-dean text-dean font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.patients_icon} alt="" />
            <p className='md:block'>Patients</p>
          </NavLink>

          <div className='h-px bg-gray-100 my-2 mx-9 opacity-50' />

          <NavLink onClick={closeSidebar} to={'/dean-add-doctor'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0fdfa] border-r-4 border-dean text-dean font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.add_icon} alt="" />
            <p className='md:block'>Add Doctors</p>
          </NavLink>
          
          <NavLink onClick={closeSidebar} to={'/dean-hospital'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0fdfa] border-r-4 border-dean text-dean font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.home_icon} alt="" />
            <p className='md:block'>Hospital Tie ups</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/dean-receptionists'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0fdfa] border-r-4 border-dean text-dean font-bold' : 'hover:bg-slate-50'}`}>
            <svg className='w-5 h-5' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M3 21h18M3 10h18M5 6l7-3 7 3M4 10v11m16-11v11M8 14v3m4-3v3m4-3v3' /></svg>
            <p className='md:block'>Receptionists</p>
          </NavLink>
          <li onClick={() => { sessionStorage.clear(); window.location.reload(); closeSidebar(); }} className='flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer hover:bg-rose-50 text-rose-500 mt-10 transition-all font-bold text-xs uppercase tracking-widest'>
            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" /></svg>
            <p className='md:block'>Log Out</p>
          </li>
        </ul>
      }

      {/* ── Reception Menu — (Front Desk Operations) ────────────────────── */}
      {
        recToken && <ul className='text-slate-600 mt-5'>
          {RECEPTION_LINKS.map((link) => {
            const active = (link.match || [link.to]).some(
              (m) => location.pathname === m || location.pathname.startsWith(m + '/')
            )
            return (
              <NavLink
                key={link.to}
                onClick={closeSidebar}
                to={link.to}
                className={`flex items-center gap-3 py-3 px-3 md:px-8 md:min-w-64 cursor-pointer transition-all ${active ? 'bg-[#eff6ff] border-r-4 border-reception text-reception font-bold' : 'hover:bg-slate-50'}`}
              >
                <RecIcon d={link.d} />
                <p className='md:block text-sm'>{link.label}</p>
              </NavLink>
            )
          })}

          <div className='mx-4 mt-6 mb-2 p-3 rounded-2xl bg-gradient-to-br from-blue-50 to-indigo-50 border border-blue-100 flex items-center gap-3'>
            <div className='w-9 h-9 rounded-full bg-reception text-white flex items-center justify-center font-bold text-sm shrink-0'>
              {(recInfo?.name || 'R').charAt(0).toUpperCase()}
            </div>
            <div className='min-w-0'>
              <p className='text-sm font-bold text-slate-800 truncate'>{recInfo?.name || 'Receptionist'}</p>
              <p className='text-[11px] text-emerald-600 font-semibold flex items-center gap-1'>
                <span className='w-1.5 h-1.5 rounded-full bg-emerald-500' /> Online
              </p>
            </div>
          </div>

          <li onClick={() => { recLogout(); window.location.href = '/'; }} className='flex items-center gap-3 py-3.5 px-3 md:px-8 md:min-w-64 cursor-pointer hover:bg-rose-50 text-rose-500 transition-all font-bold text-xs uppercase tracking-widest'>
            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" /></svg>
            <p className='md:block'>Log Out</p>
          </li>
        </ul>
      }

      {/* ── Doctor Menu — (Clinical Operations) ─────────────────────────── */}
      {
        dToken && <ul className='text-slate-600 mt-5'>
          <NavLink onClick={closeSidebar} to={'/doctor-dashboard'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f5f3ff] border-r-4 border-doctor text-doctor font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.home_icon} alt="" />
            <p className='md:block'>Dashboard</p>
          </NavLink>
          <NavLink onClick={closeSidebar} to={'/doctor-appointments'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f5f3ff] border-r-4 border-doctor text-doctor font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.appointment_icon} alt="" />
            <p className='md:block'>Appointments</p>
          </NavLink>
          <NavLink onClick={closeSidebar} to={'/doctor-video-calls'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f5f3ff] border-r-4 border-doctor text-doctor font-bold' : 'hover:bg-slate-50'}`}>
            <svg className='w-5 h-5 flex-shrink-0' fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
            </svg>
            <p className='md:block'>Video Call</p>
          </NavLink>
          <NavLink onClick={closeSidebar} to={'/doctor-profile'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f5f3ff] border-r-4 border-doctor text-doctor font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.people_icon} alt="" />
            <p className='md:block'>Profile</p>
          </NavLink>
          <li onClick={() => { sessionStorage.clear(); window.location.reload(); closeSidebar(); }} className='flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer hover:bg-rose-50 text-rose-500 mt-10 transition-all font-bold text-xs uppercase tracking-widest'>
            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" /></svg>
            <p className='md:block'>Log Out</p>
          </li>
        </ul>
      }
      </div>
    </div>
  )
}

export default Sidebar
