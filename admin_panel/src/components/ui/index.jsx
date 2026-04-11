import React, { useState } from 'react'
import { X, ChevronLeft, ChevronRight, Loader2 } from 'lucide-react'

/* ══════════════════════════════════════════════════════════════════
   StatCard — 4-up KPI cards matching dashboard screenshot
══════════════════════════════════════════════════════════════════ */
export function StatCard({ title, value, sub, trend, trendLabel, icon: Icon, iconColor = 'text-eco', iconBg = 'bg-eco-muted border-eco-border' }) {
  const up = typeof trend === 'number' ? trend >= 0 : true
  return (
    <div className="card p-5 flex flex-col gap-3 min-w-0 animate-fade-up">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="text-[0.78rem] text-ink-sub font-medium mb-1">{title}</p>
          <p className="text-[1.85rem] font-bold text-ink tracking-tight leading-none">{value}</p>
        </div>
        {Icon && (
          <div className={`w-11 h-11 rounded-xl border flex items-center justify-center flex-shrink-0 ${iconBg}`}>
            <Icon size={20} className={iconColor} />
          </div>
        )}
      </div>
      {(trend !== undefined || sub) && (
        <div className="flex items-center gap-1.5">
          {trend !== undefined && (
            <span className={`text-[0.72rem] font-semibold ${up ? 'text-eco' : 'text-red-400'}`}>
              {up ? '▲' : '▼'} {Math.abs(trend)}%
            </span>
          )}
          {trendLabel && <span className="text-[0.7rem] text-ink-muted">{trendLabel}</span>}
          {sub && trend === undefined && <span className="text-[0.72rem] text-ink-muted">{sub}</span>}
        </div>
      )}
    </div>
  )
}

/* ══════════════════════════════════════════════════════════════════
   CategoryBadge — waste category coloured pill
══════════════════════════════════════════════════════════════════ */
const CAT_CLASS = {
  PLASTIC:   'bg-eco-muted text-eco',
  PAPER:     'bg-yellow-500/15 text-yellow-400',
  METAL:     'bg-slate-500/15 text-slate-400',
  GLASS:     'bg-sky-500/15 text-sky-400',
  ORGANIC:   'bg-lime-500/15 text-lime-400',
  E_WASTE:   'bg-orange-500/15 text-orange-400',
  HAZARDOUS: 'bg-red-500/15 text-red-400',
  TEXTILE:   'bg-purple-500/15 text-purple-400',
  ACTIVE:    'bg-eco-muted text-eco',
  SUSPENDED: 'bg-red-500/15 text-red-400',
  DELETED:   'bg-red-500/15 text-red-400',
  ADMIN:     'bg-sky-500/15 text-sky-400',
  MODERATOR: 'bg-yellow-500/15 text-yellow-400',
  USER:      'bg-white/5 text-ink-sub',
  VERIFIED:  'bg-eco-muted text-eco',
  PENDING:   'bg-yellow-500/15 text-yellow-400',
}

export function Badge({ label, size = 'sm' }) {
  const cls = CAT_CLASS[label?.toString().toUpperCase().replace(/ /g, '_')] || 'bg-white/5 text-ink-sub'
  return (
    <span className={`badge ${size === 'lg' ? 'px-3 py-1 text-[0.8rem]' : ''} ${cls}`}>
      {label}
    </span>
  )
}

/* ══════════════════════════════════════════════════════════════════
   ConfidenceBar
══════════════════════════════════════════════════════════════════ */
export function ConfidenceBar({ value, showLabel = true }) {
  const pct   = Math.round((value ?? 0) * 100)
  const color = pct >= 80 ? 'bg-eco' : pct >= 60 ? 'bg-yellow-400' : 'bg-red-400'
  const text  = pct >= 80 ? 'text-eco' : pct >= 60 ? 'text-yellow-400' : 'text-red-400'
  return (
    <div className="flex items-center gap-2 min-w-0">
      <div className="conf-track flex-1">
        <div className={`conf-fill ${color}`} style={{ width: `${pct}%` }} />
      </div>
      {showLabel && (
        <span className={`text-[0.76rem] font-bold ${text} w-8 text-right flex-shrink-0`}>{pct}%</span>
      )}
    </div>
  )
}

/* ══════════════════════════════════════════════════════════════════
   DataTable — configurable columns, built-in pagination
══════════════════════════════════════════════════════════════════ */
export function DataTable({ columns, data = [], pageSize = 10, loading, emptyIcon = '🗃️', emptyMsg = 'No data found' }) {
  const [page, setPage] = useState(0)
  if (loading) return <Spinner />
  if (!data.length) return <EmptyState message={emptyMsg} icon={emptyIcon} />

  const pages  = Math.ceil(data.length / pageSize)
  const sliced = data.slice(page * pageSize, page * pageSize + pageSize)

  return (
    <div>
      <div className="overflow-x-auto">
        <table className="tbl">
          <thead>
            <tr>{columns.map(c => <th key={c.key}>{c.label}</th>)}</tr>
          </thead>
          <tbody>
            {sliced.map((row, i) => (
              <tr key={row.id || row._id || i}>
                {columns.map(c => (
                  <td key={c.key}>
                    {c.render ? c.render(row[c.key], row) : (row[c.key] ?? '—')}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {pages > 1 && (
        <div className="flex justify-between items-center mt-3.5 pt-3.5 border-t border-gb-border">
          <span className="text-[0.76rem] text-ink-muted">
            Showing {page * pageSize + 1}–{Math.min((page + 1) * pageSize, data.length)} of {data.length}
          </span>
          <div className="flex gap-1.5">
            <button className="btn btn-ghost btn-sm" onClick={() => setPage(p => Math.max(0, p - 1))} disabled={page === 0}>
              <ChevronLeft size={13} />
            </button>
            <button className="btn btn-ghost btn-sm" onClick={() => setPage(p => Math.min(pages - 1, p + 1))} disabled={page === pages - 1}>
              <ChevronRight size={13} />
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

/* ══════════════════════════════════════════════════════════════════
   Modal
══════════════════════════════════════════════════════════════════ */
export function Modal({ open, onClose, title, children, width = 'max-w-lg' }) {
  if (!open) return null
  return (
    <div
      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-[100] p-4 animate-fade-up"
      onClick={onClose}
    >
      <div
        className={`bg-gb-card border border-gb-border-strong rounded-xl2 shadow-modal w-full ${width} max-h-[90vh] flex flex-col overflow-hidden`}
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-5 py-4 border-b border-gb-border">
          <h3 className="text-[0.95rem] font-bold text-ink">{title}</h3>
          <button onClick={onClose} className="w-7 h-7 rounded-lg flex items-center justify-center text-ink-muted hover:text-ink hover:bg-white/5 cursor-pointer border-none bg-transparent">
            <X size={15} />
          </button>
        </div>
        <div className="p-5 overflow-y-auto">{children}</div>
      </div>
    </div>
  )
}

/* ══════════════════════════════════════════════════════════════════
   Spinner + EmptyState
══════════════════════════════════════════════════════════════════ */
export function Spinner({ size = 24 }) {
  return (
    <div className="flex flex-col items-center justify-center py-12 gap-3">
      <Loader2 size={size} className="text-eco animate-spin-slow" />
      <span className="text-[0.78rem] text-ink-muted">Loading…</span>
    </div>
  )
}

export function EmptyState({ message = 'No data', icon = '🗃️' }) {
  return (
    <div className="flex flex-col items-center justify-center py-12 gap-3 text-center">
      <span className="text-4xl">{icon}</span>
      <p className="text-ink-muted text-sm">{message}</p>
    </div>
  )
}

/* ══════════════════════════════════════════════════════════════════
   PageHeader — reusable page title + action button row
══════════════════════════════════════════════════════════════════ */
export function PageHeader({ title, subtitle, action }) {
  return (
    <div className="flex items-start justify-between gap-4 mb-6">
      <div>
        <h1 className="text-[1.5rem] font-bold text-ink tracking-tight">{title}</h1>
        {subtitle && <p className="text-[0.82rem] text-ink-muted mt-1">{subtitle}</p>}
      </div>
      {action && <div className="flex-shrink-0">{action}</div>}
    </div>
  )
}

/* ══════════════════════════════════════════════════════════════════
   SectionCard — titled card wrapper
══════════════════════════════════════════════════════════════════ */
export function SectionCard({ title, action, children, className = '' }) {
  return (
    <div className={`card p-5 ${className}`}>
      {(title || action) && (
        <div className="flex items-center justify-between mb-4">
          {title && <h3 className="section-title">{title}</h3>}
          {action}
        </div>
      )}
      {children}
    </div>
  )
}