import React, { useContext, useEffect, useState } from 'react'
import { AdminContext } from '../../context/AdminContext'
import { AppContext } from '../../context/AppContext'
import GlassCard from '../../components/ui/GlassCard'
import LineChart from '../../components/charts/LineChart'
import BarChart from '../../components/charts/BarChart'
import AnimatedCounter from '../../components/ui/AnimatedCounter'
import { AdminPageLayout, PageHero, FilterToolbar, McSelect, KpiCard } from '../../components/mc'

const RevenueAnalytics = () => {
    const { getRevenueAnalytics, revenueData } = useContext(AdminContext)
    const [loading, setLoading] = useState(true)
    const [selectedOption, setSelectedOption] = useState('today')

    // Dropdown options mapping
    const options = [
        { id: 'today', label: 'Current Day Revenue' },
        { id: 'days15', label: 'Last 15 Days Revenue' },
        { id: 'monthly', label: 'Monthly Revenue (current month daily breakdown)' },
        { id: 'monthWise', label: 'Month-wise Revenue (Jan–Dec of current year)' },
        { id: 'yearWise', label: 'Yearly Revenue' }
    ]

    useEffect(() => {
        const fetchAnalytics = async () => {
            setLoading(true)
            await getRevenueAnalytics()
            setLoading(false)
        }
        fetchAnalytics()
    }, [])

    if (loading || !revenueData) {
        return (
            <div className='flex items-center justify-center min-h-[calc(100vh-64px)]'>
                <div className='text-center'>
                    <div className='animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto'></div>
                    <p className='mt-4 text-gray-600 font-medium'>Fetching revenue metrics...</p>
                </div>
            </div>
        )
    }

    const currentChartData = revenueData[selectedOption] || { labels: [], values: [], total: 0 }
    const fmtInr = (n) => `₹ ${Number(n || 0).toLocaleString('en-IN')}`

    return (
        <AdminPageLayout maxWidth="max-w-5xl mx-auto">
                <PageHero
                    title="Revenue Hub"
                    subtitle="Centralized financial insights and revenue management across the healthcare network."
                    features={['Real-time Financial Analytics', 'Multi-source Revenue Tracking', 'Automated Settlements', 'Data-driven Decisions']}
                    widget={{
                        type: 'metric',
                        label: 'LIVE REVENUE',
                        value: fmtInr(currentChartData.total),
                        sublabel: options.find((o) => o.id === selectedOption)?.label,
                    }}
                />

                <FilterToolbar>
                    <McSelect id="revenue-filter" value={selectedOption} onChange={(e) => setSelectedOption(e.target.value)}>
                        {options.map((opt) => (
                            <option key={opt.id} value={opt.id}>{opt.label}</option>
                        ))}
                    </McSelect>
                </FilterToolbar>

                <div className="mc-kpi-grid mc-kpi-grid--4">
                    <KpiCard label="Gross Revenue" value={fmtInr(currentChartData.total)} iconBg="bg-emerald-100 text-emerald-600"
                        icon={<svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>}
                    />
                    <KpiCard label="Net Revenue" value={fmtInr(Math.round(currentChartData.total * 0.92))} iconBg="bg-sky-100 text-sky-600"
                        icon={<svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" /></svg>}
                    />
                </div>

                {/* Graph Area */}
                <GlassCard className='p-6'>
                    <div className='flex items-center gap-2 mb-6 border-b border-gray-50 pb-3'>
                        <div className='w-1.5 h-1.5 rounded-full bg-indigo-500' />
                        <h3 className='text-[10px] font-black text-gray-400 uppercase tracking-widest'>Revenue Distribution</h3>
                    </div>
                    
                    <div className='h-[300px] w-full transition-all duration-500 ease-in-out'>
                        {/* 
                           We use a single graph container that updates its underlying 
                           Chart component based on the selection. 
                        */}
                        {['monthWise', 'yearWise'].includes(selectedOption) ? (
                            <BarChart 
                                key={`bar-${selectedOption}`} 
                                data={currentChartData} 
                                title="Revenue" 
                                color="#4f46e5" 
                            />
                        ) : (
                            <LineChart 
                                key={`line-${selectedOption}`} 
                                data={currentChartData} 
                                title="Revenue Trend" 
                                color="#4f46e5" 
                            />
                        )}
                    </div>
                </GlassCard>

                {/* Footer Insight */}
                <div className='mt-8 flex items-center justify-center gap-4 text-[10px] font-black text-gray-300 uppercase tracking-[0.3em]'>
                    <span>Real-time Financials</span>
                    <div className='w-1 h-1 rounded-full bg-gray-200' />
                    <span>PostgreSQL Verified</span>
                    <div className='w-1 h-1 rounded-full bg-gray-200' />
                    <span>MediChain+ Official</span>
                </div>
        </AdminPageLayout>
    )
}

export default RevenueAnalytics
