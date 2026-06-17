import React, { useContext } from 'react'
import { assets } from '../assets/assets'
import { NavLink, useLocation } from 'react-router-dom'
import { AdminContext } from '../context/AdminContext'
import { DoctorContext } from '../context/DoctorContext'
import { DeanContext } from '../context/DeanContext'
import { AppContext } from '../context/AppContext'

const Sidebar = () => {

  const { aToken } = useContext(AdminContext)
  const { dToken } = useContext(DoctorContext)
  const { deanToken } = useContext(DeanContext)
  const { sidebarOpen, setSidebarOpen } = useContext(AppContext)

  const location = useLocation()
  const [dashDropdown, setDashDropdown] = React.useState(
    ['/admin-dashboard', '/revenue-analytics', '/all-appointments', '/doctor-list', '/hospital-tieups', '/dean-dashboard', '/dean-appointments', '/dean-doctors', '/dean-patients'].includes(location.pathname)
  )

  const closeSidebar = () => {
    if (window.innerWidth < 1024) {
      setSidebarOpen(false)
    }
  }

  // Update dropdown state when location changes to keep it open if on a sub-page
  React.useEffect(() => {
    if (['/admin-dashboard', '/revenue-analytics', '/all-appointments', '/doctor-list', '/hospital-tieups', '/dean-dashboard', '/dean-appointments', '/dean-doctors', '/dean-patients'].includes(location.pathname)) {
      setDashDropdown(true)
    }
  }, [location.pathname])

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
          {/* Dashboard Toggle + Main Link */}
          <NavLink 
            to={'/admin-dashboard'}
            onClick={(e) => {
              // Toggle dropdown but allow navigation
              setDashDropdown(!dashDropdown)
              if (window.innerWidth < 1024) setSidebarOpen(false)
            }}
            className={({ isActive }) => `flex items-center justify-between py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}
          >
            <div className='flex items-center gap-3'>
              <img className='w-5' src={assets.home_icon} alt="" />
              <p className='md:block'>Dashboard</p>
            </div>
            <div onClick={(e) => { e.preventDefault(); e.stopPropagation(); setDashDropdown(!dashDropdown); }}>
               <svg className={`w-4 h-4 transition-transform ${dashDropdown ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
            </div>
          </NavLink>

          {/* Dashboard Submenu */}
          {dashDropdown && (
            <div className='bg-slate-50/50 border-b border-gray-100 animate-fade-in'>
              <NavLink onClick={closeSidebar} to={'/revenue-analytics'} className={({ isActive }) => `flex items-center gap-3 py-2.5 px-3 md:px-12 cursor-pointer transition-all ${isActive ? 'text-admin font-bold bg-white shadow-sm' : 'hover:text-admin'}`}>
                <div className='w-1 h-1 rounded-full bg-current opacity-50' />
                <p className='text-xs'>Revenue Hub</p>
              </NavLink>
              <NavLink onClick={closeSidebar} to={'/all-appointments'} className={({ isActive }) => `flex items-center gap-3 py-2.5 px-3 md:px-12 cursor-pointer transition-all ${isActive ? 'text-admin font-bold bg-white shadow-sm' : 'hover:text-admin'}`}>
                <div className='w-1 h-1 rounded-full bg-current opacity-50' />
                <p className='text-xs'>Appointments</p>
              </NavLink>
              <NavLink onClick={closeSidebar} to={'/doctor-list'} className={({ isActive }) => `flex items-center gap-3 py-2.5 px-3 md:px-12 cursor-pointer transition-all ${isActive ? 'text-admin font-bold bg-white shadow-sm' : 'hover:text-admin'}`}>
                <div className='w-1 h-1 rounded-full bg-current opacity-50' />
                <p className='text-xs'>Doctors List</p>
              </NavLink>
              <NavLink onClick={closeSidebar} to={'/hospital-tieups'} className={({ isActive }) => `flex items-center gap-3 py-2.5 px-3 md:px-12 cursor-pointer transition-all ${isActive ? 'text-admin font-bold bg-white shadow-sm' : 'hover:text-admin'}`}>
                <div className='w-1 h-1 rounded-full bg-current opacity-50' />
                <p className='text-xs'>Hospital Tie ups</p>
              </NavLink>
            </div>
          )}

          <div className='h-px bg-gray-100 my-2 mx-9 opacity-50' />

          <NavLink onClick={closeSidebar} to={'/manage-deans'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
             <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 14l9-5-9-5-9 5 9 5z" /><path d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14zm-4 6v-7.5l4-2.222" /></svg>
            <p className='md:block'>Manage Deans</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/add-doctor'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.add_icon} alt="" />
            <p className='md:block'>Add Doctors</p>
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

          <NavLink onClick={closeSidebar} to={'/reception-scan'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" /></svg>
            <p className='md:block'>Reception Scan</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/refund-management'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" /></svg>
            <p className='md:block'>Refunds</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/manage-admins'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" /></svg>
            <p className='md:block'>Admins</p>
          </NavLink>

          <NavLink onClick={closeSidebar} to={'/revenue-analytics'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0f9ff] border-r-4 border-admin text-admin font-bold' : 'hover:bg-slate-50'}`}>
            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
            <p className='md:block'>Revenue Hub</p>
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
          {/* Dashboard Toggle + Main Link */}
          <NavLink 
            to={'/dean-dashboard'}
            onClick={(e) => {
              setDashDropdown(!dashDropdown)
              if (window.innerWidth < 1024) setSidebarOpen(false)
            }}
            className={({ isActive }) => `flex items-center justify-between py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0fdfa] border-r-4 border-dean text-dean font-bold' : 'hover:bg-slate-50'}`}
          >
            <div className='flex items-center gap-3'>
              <img className='w-5' src={assets.home_icon} alt="" />
              <p className='md:block'>Dashboard</p>
            </div>
            <div onClick={(e) => { e.preventDefault(); e.stopPropagation(); setDashDropdown(!dashDropdown); }}>
               <svg className={`w-4 h-4 transition-transform ${dashDropdown ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
            </div>
          </NavLink>

          {/* Dashboard Submenu */}
          {dashDropdown && (
            <div className='bg-emerald-50/30 border-b border-gray-100 animate-fade-in'>
              <NavLink onClick={closeSidebar} to={'/dean-dashboard'} className={({ isActive }) => `flex items-center gap-3 py-2.5 px-3 md:px-12 cursor-pointer transition-all ${isActive ? 'text-dean font-bold bg-white shadow-sm' : 'hover:text-dean'}`}>
                <div className='w-1 h-1 rounded-full bg-current opacity-50' />
                <p className='text-xs'>Analytics Hub</p>
              </NavLink>
              <NavLink onClick={closeSidebar} to={'/dean-appointments'} className={({ isActive }) => `flex items-center gap-3 py-2.5 px-3 md:px-12 cursor-pointer transition-all ${isActive ? 'text-dean font-bold bg-white shadow-sm' : 'hover:text-dean'}`}>
                <div className='w-1 h-1 rounded-full bg-current opacity-50' />
                <p className='text-xs'>Appointments</p>
              </NavLink>
              <NavLink onClick={closeSidebar} to={'/dean-doctors'} className={({ isActive }) => `flex items-center gap-3 py-2.5 px-3 md:px-12 cursor-pointer transition-all ${isActive ? 'text-dean font-bold bg-white shadow-sm' : 'hover:text-dean'}`}>
                <div className='w-1 h-1 rounded-full bg-current opacity-50' />
                <p className='text-xs'>Doctors List</p>
              </NavLink>
              <NavLink onClick={closeSidebar} to={'/dean-patients'} className={({ isActive }) => `flex items-center gap-3 py-2.5 px-3 md:px-12 cursor-pointer transition-all ${isActive ? 'text-dean font-bold bg-white shadow-sm' : 'hover:text-dean'}`}>
                <div className='w-1 h-1 rounded-full bg-current opacity-50' />
                <p className='text-xs'>Patients</p>
              </NavLink>
            </div>
          )}

          <div className='h-px bg-gray-100 my-2 mx-9 opacity-50' />

          <NavLink onClick={closeSidebar} to={'/dean-add-doctor'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0fdfa] border-r-4 border-dean text-dean font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.add_icon} alt="" />
            <p className='md:block'>Add Doctors</p>
          </NavLink>
          
          <NavLink onClick={closeSidebar} to={'/dean-hospital'} className={({ isActive }) => `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer transition-all ${isActive ? 'bg-[#f0fdfa] border-r-4 border-dean text-dean font-bold' : 'hover:bg-slate-50'}`}>
            <img className='w-5' src={assets.home_icon} alt="" />
            <p className='md:block'>Hospital Tie ups</p>
          </NavLink>
          <li onClick={() => { sessionStorage.clear(); window.location.reload(); closeSidebar(); }} className='flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-64 cursor-pointer hover:bg-rose-50 text-rose-500 mt-10 transition-all font-bold text-xs uppercase tracking-widest'>
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
