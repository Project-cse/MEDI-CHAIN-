import React from 'react'
import LiveClock from './LiveClock'

const CheckIcon = () => (
  <svg className="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
  </svg>
)

/**
 * Gradient page banner matching MediChain mockups.
 * widget: { type: 'clock' } | { type: 'metric', label, value, sublabel? }
 */
const PageHero = ({
  title,
  subtitle,
  features = [],
  widget = { type: 'clock' },
  icon,
  className = '',
}) => (
  <section className={`mc-page-hero ${className}`}>
    <div className="mc-page-hero__bg" aria-hidden="true" />
    <div className="mc-page-hero__content">
      <div className="mc-page-hero__text">
        {icon && <div className="mc-page-hero__icon">{icon}</div>}
        <h1 className="mc-page-hero__title">{title}</h1>
        {subtitle && <p className="mc-page-hero__subtitle">{subtitle}</p>}
        {features.length > 0 && (
          <ul className="mc-page-hero__features">
            {features.map((f) => (
              <li key={f}>
                <CheckIcon />
                <span>{f}</span>
              </li>
            ))}
          </ul>
        )}
      </div>
      <div className="mc-page-hero__widget">
        {widget.type === 'metric' ? (
          <div className="mc-hero-metric">
            <div className="mc-hero-metric__header">
              <span className="mc-live-dot" />
              <span className="mc-live-label">{widget.label || 'LIVE'}</span>
            </div>
            <p className="mc-hero-metric__value">{widget.value}</p>
            {widget.sublabel && <p className="mc-hero-metric__sub">{widget.sublabel}</p>}
          </div>
        ) : (
          <LiveClock />
        )}
      </div>
    </div>
  </section>
)

export default PageHero
