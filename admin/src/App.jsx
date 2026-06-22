import React, { useContext, useEffect } from 'react'
import { DoctorContext } from './context/DoctorContext';
import { AdminContext } from './context/AdminContext';
import { DeanContext } from './context/DeanContext';
import { ReceptionContext } from './context/ReceptionContext';
import { AppContext } from './context/AppContext';
import { Route, Routes, useLocation, Navigate } from 'react-router-dom'
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import Navbar from './components/Navbar'
import Sidebar from './components/Sidebar'
import ScrollToTop from './components/ScrollToTop'
import LiveTips from './components/LiveTips'
import AnimatedQuotes from './components/AnimatedQuotes'
import BackgroundFX from './components/BackgroundFX'

// Admin pages
import Dashboard from './pages/Admin/Dashboard';
import HospitalTieUps from './pages/Admin/HospitalTieUps';
import ManageDeans from './pages/Admin/ManageDeans';
import ManageLabs from './pages/Admin/ManageLabs';
import ManageBloodBanks from './pages/Admin/ManageBloodBanks';
import ManageUsers from './pages/Admin/ManageUsers';
import ManageAdmins from './pages/Admin/ManageAdmins';
import SystemSettings from './pages/Admin/SystemSettings';
import AllAppointments from './pages/Admin/AllAppointments';
import DoctorsList from './pages/Admin/DoctorsList';
import RevenueAnalytics from './pages/Admin/RevenueAnalytics';
import RefundManagement from './pages/Admin/RefundManagement';
import DeanPortals from './pages/Admin/DeanPortals';
import AdminManageReceptionists from './pages/Admin/ManageReceptionists';

// Doctor pages
import DoctorAppointments from './pages/Doctor/DoctorAppointments';
import DoctorDashboard from './pages/Doctor/DoctorDashboard';
import DoctorProfile from './pages/Doctor/DoctorProfile';
import QueueManagement from './pages/Doctor/QueueManagement';
import DoctorVideoConsult from './pages/Doctor/DoctorVideoConsult';
import DoctorVideoCalls from './pages/Doctor/DoctorVideoCalls';
import IncomingVideoCallModal from './components/IncomingVideoCallModal';

// Dean pages
import DeanDashboard from './pages/Dean/DeanDashboard';
import DeanDoctors from './pages/Dean/DeanDoctors';
import DeanAddDoctor from './pages/Dean/DeanAddDoctor';
import DeanPatients from './pages/Dean/DeanPatients';
import DeanAppointments from './pages/Dean/DeanAppointments';
import DeanHospital from './pages/Dean/DeanHospital';
import DeanManageReceptionists from './pages/Dean/ManageReceptionists';

// Reception pages
import ReceptionDashboard from './pages/Reception/ReceptionDashboard';
import OnlineBookings from './pages/Reception/OnlineBookings';
import WalkInRegistration from './pages/Reception/WalkInRegistration';
import QRCheckIn from './pages/Reception/QRCheckIn';
import ReceptionQueue from './pages/Reception/QueueManagement';
import ConsultationSummary from './pages/Reception/ConsultationSummary';
import ReceptionPatients from './pages/Reception/Patients';
import ReceptionFollowUps from './pages/Reception/FollowUps';
import ReceptionPayments from './pages/Reception/Payments';
import ReceptionRefunds from './pages/Reception/RefundRequests';
import ReceptionNoShows from './pages/Reception/NoShows';
import ReceptionReports from './pages/Reception/Reports';
import ReceptionSettings from './pages/Reception/Settings';

// Auth pages
import Login from './pages/Login';
import DoctorForgotPassword from './pages/DoctorForgotPassword';

const App = () => {
  const { dToken } = useContext(DoctorContext)
  const { aToken } = useContext(AdminContext)
  const { deanToken } = useContext(DeanContext)
  const { recToken } = useContext(ReceptionContext)
  const { sidebarOpen, setSidebarOpen, darkMode } = useContext(AppContext)
  const location = useLocation()

  const isAuthenticated = dToken || aToken || deanToken || recToken

  // Login/auth screens are always light; dashboard respects user toggle (default light)
  useEffect(() => {
    const root = document.documentElement
    if (!isAuthenticated) {
      root.classList.remove('dark')
      root.classList.add('login-light')
      return () => root.classList.remove('login-light')
    }
    root.classList.remove('login-light')
    root.classList.toggle('dark', darkMode)
  }, [isAuthenticated, darkMode])

  return isAuthenticated ? (
    <div className='relative w-full h-screen h-dvh medical-bg text-mc-text flex flex-col overflow-hidden'>
      <ToastContainer />
      <Navbar />
      <div key={location.pathname} className='flex items-start relative z-10 animate-route-in flex-1 min-h-0 overflow-hidden'>
        {/* Mobile Overlay */}
        {sidebarOpen && (
          <div
            onClick={() => setSidebarOpen(false)}
            className='fixed inset-0 bg-black/40 backdrop-blur-sm z-20 lg:hidden transition-opacity'
          />
        )}
        <Sidebar />
        <div className='flex-1 min-w-0 w-full pt-0 overflow-y-auto overflow-x-hidden main-content-area bg-mc-bg'>
          <Routes>
            <Route path='/' element={
              aToken ? <Navigate to='/admin-dashboard' /> :
                dToken ? <Navigate to='/doctor-dashboard' /> :
                  deanToken ? <Navigate to='/dean-dashboard' /> :
                    recToken ? <Navigate to='/reception-dashboard' /> :
                      <Navigate to='/login' />
            } />

            {/* ── Admin Routes ────────────────────────────────── */}
            <Route path='/admin-dashboard' element={<Dashboard />} />
            <Route path='/hospital-tieups' element={<HospitalTieUps />} />
            <Route path='/manage-deans' element={<ManageDeans />} />
            <Route path='/manage-labs' element={<ManageLabs />} />
            <Route path='/manage-blood-banks' element={<ManageBloodBanks />} />
            <Route path='/manage-users' element={<ManageUsers />} />
            <Route path='/manage-admins' element={<ManageAdmins />} />
            <Route path='/system-settings' element={<SystemSettings />} />
            <Route path='/all-appointments' element={<AllAppointments />} />
            <Route path='/doctor-list' element={<DoctorsList />} />
            <Route path='/revenue-analytics' element={<RevenueAnalytics />} />
            <Route path='/manage-receptionists' element={<AdminManageReceptionists />} />
            <Route path='/refund-management' element={<RefundManagement />} />

            {/* ── Doctor Routes ────────────────────────────────── */}
            <Route path='/doctor-dashboard' element={<DoctorDashboard />} />
            <Route path='/doctor-appointments' element={<DoctorAppointments />} />
            <Route path='/doctor-video-calls' element={<DoctorVideoCalls />} />
            <Route path='/doctor-profile' element={<DoctorProfile />} />
            <Route path='/queue-management' element={<QueueManagement />} />
            <Route path='/doctor-video/:appointmentId' element={<DoctorVideoConsult />} />

            {/* ── Dean Routes ──────────────────────────────────── */}
            <Route path='/dean-dashboard' element={<DeanDashboard />} />
            <Route path='/dean-add-doctor' element={<DeanAddDoctor />} />
            <Route path='/dean-doctors' element={<DeanDoctors />} />
            <Route path='/dean-appointments' element={<DeanAppointments />} />
            <Route path='/dean-patients' element={<DeanPatients />} />
            <Route path='/dean-hospital' element={<DeanHospital />} />
            <Route path='/dean-receptionists' element={<DeanManageReceptionists />} />

            {/* ── Reception Routes ─────────────────────────────── */}
            <Route path='/reception-dashboard' element={<ReceptionDashboard />} />
            <Route path='/reception-online' element={<OnlineBookings />} />
            <Route path='/reception-walkin' element={<WalkInRegistration />} />
            <Route path='/reception-checkin' element={<QRCheckIn />} />
            <Route path='/reception-queue' element={<ReceptionQueue />} />
            <Route path='/reception-summary/:appointmentId' element={<ConsultationSummary />} />
            <Route path='/reception-patients' element={<ReceptionPatients />} />
            <Route path='/reception-followups' element={<ReceptionFollowUps />} />
            <Route path='/reception-payments' element={<ReceptionPayments />} />
            <Route path='/reception-refunds' element={<ReceptionRefunds />} />
            <Route path='/reception-noshows' element={<ReceptionNoShows />} />
            <Route path='/reception-reports' element={<ReceptionReports />} />
            <Route path='/reception-settings' element={<ReceptionSettings />} />

            <Route path='*' element={<Navigate to='/' />} />
          </Routes>
        </div>
      </div>
      <ScrollToTop />
      {dToken ? <IncomingVideoCallModal /> : null}
      <style>{`@keyframes pan {0%{background-position:0% 0%}50%{background-position:100% 100%}100%{background-position:0% 0%}}
      @keyframes routeIn {0%{opacity:0; transform: translateY(12px) scale(.98)} 100%{opacity:1; transform: translateY(0) scale(1)}}
      .animate-route-in{animation: routeIn .5s ease forwards}
      `}</style>
    </div>
  ) : (
    <>
      <ToastContainer />
      <Routes>
        <Route path='/' element={<Login />} />
        <Route path='/login' element={<Login />} />
        <Route path='/doctor-forgot-password' element={<DoctorForgotPassword />} />
        <Route path='*' element={<Navigate to='/' />} />
      </Routes>
    </>
  )
}

export default App