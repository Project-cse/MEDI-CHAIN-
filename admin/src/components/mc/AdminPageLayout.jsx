import React from 'react'
import PageShell from '../PageShell'

const AdminPageLayout = ({ children, className = '', maxWidth = 'max-w-[1400px] mx-auto' }) => (
  <PageShell className={`mc-admin-page ${className}`} maxWidth={maxWidth}>
    <div className="mc-admin-page__inner space-y-5 sm:space-y-6">
      {children}
    </div>
  </PageShell>
)

export default AdminPageLayout
