import React, { useEffect, useState, useCallback } from 'react'
import {
  Search, Plus, Pencil, Trash2, Bell, ChevronDown, ChevronUp,
  CheckCircle2, X, RefreshCw, Save,
} from 'lucide-react'
import Layout from '../components/layout/Layout'
import { Modal, Spinner, EmptyState } from '../components/ui/index.jsx'
import { tipsApi, notificationsApi } from '../api'

// ── Emoji / colour maps ────────────────────────────────────────────────────────
const CAT_EMOJI = {
  PLASTIC: '🧴', PAPER: '📄', ORGANIC: '🌱', GLASS: '🫙',
  METAL: '🥫', E_WASTE: '💻', HAZARDOUS: '⚠️', TEXTILE: '👕',
  WOOD: '🪵', FOOD_WASTE: '🌱', NOT_FOOD_WASTE: '🗑️', OTHER: '♻️',
}

const BIN_COLOR_HEX = {
  Blue: '#2196F3', Green: '#4CAF50', Yellow: '#FFC107', Red: '#F44336',
  Purple: '#9C27B0', Brown: '#795548', Black: '#424242', Orange: '#FF9800',
}

const CATEGORIES = [
  'PLASTIC', 'GLASS', 'METAL', 'E_WASTE', 'TEXTILE',
  'WOOD', 'FOOD_WASTE', 'NOT_FOOD_WASTE', 'OTHER',
]

const BIN_COLORS = ['Blue', 'Green', 'Yellow', 'Red', 'Purple', 'Brown', 'Black', 'Orange']

// ── List editor component ──────────────────────────────────────────────────────
function ListEditor({ label, items = [], onChange }) {
  const update = (i, val) => { const a = [...items]; a[i] = val; onChange(a) }
  const add    = ()       => onChange([...items, ''])
  const remove = (i)      => onChange(items.filter((_, j) => j !== i))

  return (
    <div className="space-y-1.5">
      <label className="text-[0.74rem] font-semibold text-ink-sub block">{label}</label>
      {items.map((item, i) => (
        <div key={i} className="flex gap-2 items-center">
          <input
            value={item}
            onChange={e => update(i, e.target.value)}
            className="input text-[0.8rem] py-1.5 flex-1"
            placeholder={`Item ${i + 1}`}
          />
          <button onClick={() => remove(i)} className="text-red-400 hover:text-red-500">
            <X size={14} />
          </button>
        </div>
      ))}
      <button onClick={add} className="text-[0.75rem] text-eco font-semibold hover:underline cursor-pointer bg-transparent border-none">
        + Add item
      </button>
    </div>
  )
}

// ── Tip Card ──────────────────────────────────────────────────────────────────
function TipCard({ tip, onEdit, onDelete }) {
  const [expanded, setExpanded] = useState(false)
  const emoji     = tip.icon || CAT_EMOJI[tip.waste_category] || '♻️'
  const binColor  = BIN_COLOR_HEX[tip.bin_color] || '#424242'
  const stepCount = tip.steps?.length || 0

  return (
    <div className="card overflow-hidden flex flex-col group">
      {/* Hero */}
      <div className="relative h-40 flex items-center justify-center text-5xl bg-gradient-to-br from-gb-surface to-gb-card group-hover:scale-105 transition-transform duration-500">
        {emoji}
        {/* Bin colour dot */}
        <span
          className="absolute top-3 left-3 w-3 h-3 rounded-full border-2 border-white/30"
          style={{ backgroundColor: binColor }}
          title={`${tip.bin_color} bin`}
        />
        {/* Active badge */}
        <span className={`absolute top-2.5 right-2.5 text-[0.65rem] font-bold px-2 py-0.5 rounded-md border
          ${tip.is_active ? 'bg-eco/20 text-eco border-eco/30' : 'bg-red-500/20 text-red-400 border-red-400/30'}`}>
          {tip.is_active ? 'Active' : 'Inactive'}
        </span>
      </div>

      {/* Body */}
      <div className="p-4 flex flex-col gap-2 flex-1">
        <div className="flex items-center gap-2">
          <span className="text-[0.68rem] font-bold uppercase tracking-widest text-ink-muted">{tip.waste_category}</span>
          {tip.bin_color && (
            <span className="text-[0.65rem] px-1.5 py-0.5 rounded font-semibold" style={{ backgroundColor: `${binColor}22`, color: binColor }}>
              {tip.bin_color} Bin
            </span>
          )}
        </div>

        <p className="text-[0.86rem] font-semibold text-ink leading-snug line-clamp-2">{tip.tip_english}</p>
        <p className="text-[0.75rem] text-ink-muted line-clamp-1 text-right" dir="rtl">{tip.tip_urdu}</p>

        {stepCount > 0 && (
          <button
            onClick={() => setExpanded(e => !e)}
            className="flex items-center gap-1 text-[0.74rem] text-eco font-semibold hover:underline cursor-pointer bg-transparent border-none mt-1"
          >
            {stepCount} steps {expanded ? <ChevronUp size={12} /> : <ChevronDown size={12} />}
          </button>
        )}

        {expanded && (
          <ol className="space-y-1 list-decimal list-inside mt-1">
            {tip.steps?.map((s, i) => (
              <li key={i} className="text-[0.74rem] text-ink-sub leading-relaxed">{s}</li>
            ))}
          </ol>
        )}

        {/* Actions */}
        <div className="flex gap-2 mt-auto pt-2">
          <button onClick={() => onEdit(tip)}
            className="btn btn-ghost btn-sm flex-1 justify-center gap-1.5 text-[0.76rem]">
            <Pencil size={12} /> Edit
          </button>
          <button onClick={() => onDelete(tip.id)}
            className="btn btn-ghost btn-sm flex-1 justify-center gap-1.5 text-[0.76rem] text-red-400 hover:text-red-500">
            <Trash2 size={12} /> Delete
          </button>
        </div>
      </div>
    </div>
  )
}

// ── Create / Edit Tip Modal ───────────────────────────────────────────────────
const EMPTY_FORM = {
  waste_category: 'PLASTIC',
  tip_english:    '',
  tip_urdu:       '',
  bin_color:      'Blue',
  icon:           '♻️',
  steps:          [''],
  steps_ur:       [''],
  do_list:        [''],
  dont_list:      [''],
  is_active:      true,
}

function TipModal({ open, tip, onClose, onSave }) {
  const [form, setForm] = useState(EMPTY_FORM)
  const [saving, setSaving] = useState(false)
  const [tab, setTab] = useState('basic') // 'basic' | 'steps' | 'lists'

  useEffect(() => {
    if (open) {
      setForm(tip ? { ...EMPTY_FORM, ...tip } : EMPTY_FORM)
      setTab('basic')
    }
  }, [tip, open])

  const set = (k, v) => setForm(p => ({ ...p, [k]: v }))

  const handleSave = async () => {
    setSaving(true)
    try { await onSave(form); onClose() }
    catch (e) { console.error(e) }
    finally { setSaving(false) }
  }

  return (
    <Modal open={open} onClose={onClose} title={tip?.id ? `Edit Tip — ${tip.waste_category}` : 'Create New Eco Tip'} width="max-w-2xl">
      {/* Tabs */}
      <div className="flex gap-1 mb-4 border-b border-gb-border pb-2">
        {['basic', 'steps', 'lists'].map(t => (
          <button key={t} onClick={() => setTab(t)}
            className={`px-3 py-1.5 text-[0.78rem] font-semibold rounded-lg capitalize transition-all cursor-pointer border-none
              ${tab === t ? 'bg-eco text-ink-inverse' : 'bg-transparent text-ink-muted hover:text-ink'}`}>
            {t === 'basic' ? '📋 Basic Info' : t === 'steps' ? '📝 Steps' : '✅ Do / ❌ Don\'t'}
          </button>
        ))}
      </div>

      {tab === 'basic' && (
        <div className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Waste Category</label>
              <select value={form.waste_category} onChange={e => set('waste_category', e.target.value)} className="input text-[0.82rem] py-2">
                {CATEGORIES.map(c => <option key={c}>{c}</option>)}
              </select>
            </div>
            <div>
              <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Bin Colour</label>
              <select value={form.bin_color} onChange={e => set('bin_color', e.target.value)} className="input text-[0.82rem] py-2">
                {BIN_COLORS.map(c => <option key={c}>{c}</option>)}
              </select>
            </div>
          </div>
          <div>
            <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Icon (emoji)</label>
            <input value={form.icon} onChange={e => set('icon', e.target.value)} className="input text-[0.82rem] py-2 w-24" />
          </div>
          <div>
            <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Tip (English)</label>
            <textarea value={form.tip_english} onChange={e => set('tip_english', e.target.value)}
              rows={3} placeholder="Short disposal tip in English..."
              className="input text-[0.82rem] py-2 resize-none" />
          </div>
          <div>
            <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Tip (اردو)</label>
            <textarea value={form.tip_urdu} onChange={e => set('tip_urdu', e.target.value)}
              rows={3} placeholder="اردو میں مختصر ٹپ..." dir="rtl"
              className="input text-[0.82rem] py-2 resize-none text-right" />
          </div>
          <div className="flex items-center gap-2">
            <input type="checkbox" id="is_active" checked={form.is_active} onChange={e => set('is_active', e.target.checked)} className="w-4 h-4" />
            <label htmlFor="is_active" className="text-[0.82rem] text-ink-sub">Active (visible to app users)</label>
          </div>
        </div>
      )}

      {tab === 'steps' && (
        <div className="space-y-4">
          <ListEditor label="Steps (English) — 6–8 detailed action steps" items={form.steps} onChange={v => set('steps', v)} />
          <ListEditor label="Steps (اردو)" items={form.steps_ur} onChange={v => set('steps_ur', v)} />
        </div>
      )}

      {tab === 'lists' && (
        <div className="space-y-4">
          <ListEditor label="✅ Do List" items={form.do_list} onChange={v => set('do_list', v)} />
          <ListEditor label="❌ Don't List" items={form.dont_list} onChange={v => set('dont_list', v)} />
        </div>
      )}

      <div className="flex gap-2 justify-end pt-4 border-t border-gb-border mt-4">
        <button className="btn btn-ghost btn-sm" onClick={onClose}>Cancel</button>
        <button className="btn btn-primary btn-sm gap-1.5" onClick={handleSave} disabled={saving}>
          {saving ? <RefreshCw size={12} className="animate-spin" /> : <Save size={12} />}
          {tip?.id ? 'Update Tip' : 'Create Tip'}
        </button>
      </div>
    </Modal>
  )
}

// ── Main Page ─────────────────────────────────────────────────────────────────
export default function EcoTips() {
  const [tips,       setTips]    = useState([])
  const [search,     setSearch]  = useState('')
  const [loading,    setLoading] = useState(true)
  const [tipModal,   setTipModal] = useState(false)
  const [editTip,    setEditTip]  = useState(null)

  // Notification panel
  const [notifType,  setNotifType]  = useState('Push')
  const [audience,   setAudience]   = useState('All Users')
  const [msgTitle,   setMsgTitle]   = useState('')
  const [msgBody,    setMsgBody]    = useState('')
  const [sending,    setSending]    = useState(false)
  const [recentActivity, setRecent] = useState([
    { icon: '✓', label: 'Weekly Recycling Reminder', meta: 'Sent to All Users • 2h ago', color: 'bg-eco' },
    { icon: '◷', label: 'Event: Beach Cleanup',      meta: 'Scheduled for Tomorrow',    color: 'bg-sky-500' },
  ])

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res  = await tipsApi.getAll({ limit: 50 })
      const data = Array.isArray(res.data?.data) ? res.data.data : Array.isArray(res.data) ? res.data : []
      setTips(data)
    } catch { setTips([]) }
    finally { setLoading(false) }
  }, [])

  useEffect(() => { load() }, [load])

  const handleSave = async (form) => {
    if (form.id) await tipsApi.update(form.id, form)
    else         await tipsApi.create(form)
    load()
  }

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this eco tip?')) return
    try { await tipsApi.delete(id); load() } catch (e) { console.error(e) }
  }

  const handleSeed = async () => {
    if (!window.confirm('Re-seed all tips from defaults? This will clear existing tips.')) return
    try { await tipsApi.seed(); load() } catch (e) { console.error(e) }
  }

  const handleBroadcast = async () => {
    if (!msgTitle.trim() || !msgBody.trim()) return
    setSending(true)
    try {
      await notificationsApi.createCampaign({
        title_english:   msgTitle, title_urdu:   msgTitle,
        message_english: msgBody,  message_urdu: msgBody,
        target_audience: audience === 'All Users' ? 'ALL' : 'ACTIVE_USERS',
      })
      setRecent(p => [{ icon: '✓', label: msgTitle, meta: `Sent to ${audience} • Just now`, color: 'bg-eco' }, ...p.slice(0, 3)])
      setMsgTitle(''); setMsgBody('')
    } catch (e) { console.error(e) }
    finally { setSending(false) }
  }

  const filtered = tips.filter(t =>
    !search ||
    (t.tip_english || '').toLowerCase().includes(search.toLowerCase()) ||
    (t.waste_category || '').toLowerCase().includes(search.toLowerCase())
  )

  return (
    <Layout title="Eco-Tips & Notification Management" subtitle="Manage disposal guidance and broadcast alerts to users">
      {/* Header */}
      <div className="flex items-center justify-between mb-5">
        <div className="flex items-center gap-3">
          <button onClick={handleSeed} className="btn btn-ghost btn-sm gap-1.5 text-[0.78rem]">
            <RefreshCw size={13} /> Seed Defaults
          </button>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={() => { setEditTip(null); setTipModal(true) }}
            className="btn btn-primary gap-2 text-[0.82rem]">
            <Plus size={14} /> Create New Tip
          </button>
        </div>
      </div>

      <div className="flex gap-6">
        {/* ── Left: Tip Cards Grid ─────────────────────────────── */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between mb-4">
            <h3 className="flex items-center gap-2 text-[0.95rem] font-bold text-ink">
              🎓 Disposal Guidance Tips <span className="text-[0.78rem] text-ink-muted font-normal">({filtered.length})</span>
            </h3>
            <div className="relative">
              <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-muted pointer-events-none" />
              <input value={search} onChange={e => setSearch(e.target.value)}
                placeholder="Search tips..."
                className="input pl-9 w-52 text-[0.8rem] py-2" />
            </div>
          </div>

          {loading ? <Spinner /> : filtered.length === 0
            ? <EmptyState icon="💡" message="No tips found. Click 'Create New Tip' or 'Seed Defaults'." />
            : (
              <div className="grid grid-cols-2 xl:grid-cols-3 gap-4">
                {filtered.map((tip, i) => (
                  <TipCard
                    key={tip.id || i}
                    tip={tip}
                    onEdit={t  => { setEditTip(t); setTipModal(true) }}
                    onDelete={handleDelete}
                  />
                ))}
              </div>
            )}
        </div>

        {/* ── Right: Broadcast Panel ────────────────────────────── */}
        <div className="w-72 flex-shrink-0">
          <div className="card p-5 space-y-4">
            <h3 className="flex items-center gap-2 text-[0.95rem] font-bold text-ink">
              📢 Broadcast Notifications
            </h3>

            <div className="space-y-2.5">
              <p className="text-[0.66rem] font-bold tracking-[0.1em] uppercase text-ink-muted">Compose Message</p>
              <input value={msgTitle} onChange={e => setMsgTitle(e.target.value)}
                placeholder="Title (e.g., Collection Day Alert)"
                className="input text-[0.8rem] py-2" />
              <textarea value={msgBody} onChange={e => setMsgBody(e.target.value)}
                placeholder="Type your notification message here..."
                rows={4} className="input text-[0.8rem] py-2 resize-none" />
            </div>

            <div className="space-y-2">
              <p className="text-[0.66rem] font-bold tracking-[0.1em] uppercase text-ink-muted">Target Audience</p>
              <select value={audience} onChange={e => setAudience(e.target.value)}
                className="input text-[0.8rem] py-2 bg-gb-input">
                <option>All Users</option>
                <option>Active Users</option>
              </select>
            </div>

            <div className="space-y-2">
              <p className="text-[0.66rem] font-bold tracking-[0.1em] uppercase text-ink-muted">Notification Type</p>
              <div className="grid grid-cols-2 gap-2">
                {[{ label: 'Push', icon: '🔔' }, { label: 'In-App', icon: '💬' }].map(({ label, icon }) => (
                  <button key={label} onClick={() => setNotifType(label)}
                    className={`flex flex-col items-center gap-1.5 py-3 rounded-xl border text-[0.78rem] font-semibold cursor-pointer transition-all
                      ${notifType === label
                        ? 'bg-eco text-ink-inverse border-eco'
                        : 'bg-gb-surface border-gb-border text-ink-sub hover:border-eco-border hover:text-eco'}`}>
                    <span className="text-lg">{icon}</span>
                    {label}
                  </button>
                ))}
              </div>
            </div>

            <button onClick={handleBroadcast} disabled={sending || !msgTitle.trim() || !msgBody.trim()}
              className="btn btn-primary w-full justify-center gap-2 py-3 text-[0.85rem] disabled:opacity-50">
              {sending ? <RefreshCw size={14} className="animate-spin" /> : '▶'} {sending ? 'Sending…' : 'Send Broadcast'}
            </button>

            <div className="space-y-2.5 pt-2 border-t border-gb-border">
              <p className="text-[0.66rem] font-bold tracking-[0.1em] uppercase text-ink-muted">Recent Activity</p>
              {recentActivity.map((a, i) => (
                <div key={i} className="flex items-start gap-3">
                  <div className={`w-5 h-5 rounded-full ${a.color} flex items-center justify-center text-white text-[0.6rem] font-bold flex-shrink-0 mt-0.5`}>
                    {a.icon}
                  </div>
                  <div>
                    <p className="text-[0.78rem] font-semibold text-ink">{a.label}</p>
                    <p className="text-[0.68rem] text-ink-muted">{a.meta}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <TipModal
        open={tipModal}
        tip={editTip}
        onClose={() => setTipModal(false)}
        onSave={handleSave}
      />
    </Layout>
  )
}