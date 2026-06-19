import React, { useContext, useEffect, useState } from 'react'
import { ReceptionContext } from '../../context/ReceptionContext'
import { PageWrap, RcHeader, KpiTile, Spinner, fmtMoney } from './components'

const Icon = ({ d }) => (<svg className='w-6 h-6' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={1.8} d={d} /></svg>)

const Reports = () => {
  const { getDashboard } = useContext(ReceptionContext)
  const [s, setS] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => { (async () => { const r = await getDashboard(); if (r?.success) setS(r.stats); setLoading(false) })() }, [])

  return (
    <PageWrap>
      <RcHeader title='Reports' subtitle="Today's front-desk activity overview" />
      {loading ? <Spinner /> : (
        <>
          <div className='grid grid-cols-2 lg:grid-cols-4 gap-4'>
            <KpiTile label='Online Patients' value={s?.onlineToday ?? 0} tone='blue' icon={<Icon d='M21 12a9 9 0 11-18 0 9 9 0 0118 0z' />} />
            <KpiTile label='Walk-in Patients' value={s?.walkInToday ?? 0} tone='green' icon={<Icon d='M13 5l7 7-7 7' />} />
            <KpiTile label='No Shows' value={s?.noShows ?? 0} tone='rose' icon={<Icon d='M6 18L18 6M6 6l12 12' />} />
            <KpiTile label='Follow-Ups' value={s?.followUps ?? 0} tone='violet' icon={<Icon d='M8 7V3m8 4V3M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z' />} />
          </div>
          <div className='grid grid-cols-1 lg:grid-cols-3 gap-4 mt-4'>
            <KpiTile label='Waiting Queue' value={s?.waitingQueue ?? 0} tone='amber' icon={<Icon d='M12 8v4l3 3' />} />
            <KpiTile label='Pending Refunds' value={s?.pendingRefunds ?? 0} tone='rose' icon={<Icon d='M3 10h10a8 8 0 018 8' />} />
            <KpiTile label='Revenue Today' value={fmtMoney(s?.revenueToday)} tone='green' icon={<Icon d='M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8V6m0 12v-2' />} />
          </div>
        </>
      )}
    </PageWrap>
  )
}

export default Reports
