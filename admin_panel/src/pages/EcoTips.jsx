import React, { useEffect, useState, useCallback } from 'react'
import {
  Search, Plus, Pencil, Calendar, Bell, MessageSquare,
  CheckCircle2, Clock, X,
} from 'lucide-react'
import Layout from '../components/layout/Layout'
import { Modal, Spinner, EmptyState } from '../components/ui/index.jsx'
import { tipsApi, notificationsApi } from '../api'

const STATUS_STYLE = {
  Published: 'bg-gb-base/80 text-ink border-white/20',
  Draft:     'bg-yellow-500/80 text-gb-base border-yellow-600/50',
  Scheduled: 'bg-gb-base/80 text-ink border-white/20',
}

/* ── Tip Card ─────────────────────────────────────────────────────────────── */
function TipCard({ tip, onEdit }) {
  const status  = tip.status || 'Published'
  const emoji   = { PLASTIC:'🧴',PAPER:'📄',ORGANIC:'🌱',GLASS:'🫙',METAL:'🥫',E_WASTE:'💻',HAZARDOUS:'⚠️',TEXTILE:'👕',OTHER:'♻️' }
  const catEmoji= emoji[tip.waste_category] || '♻️'

  return (
    <div className="card overflow-hidden flex flex-col group">
      {/* Image area */}
      <div className="relative h-44 bg-gb-surface overflow-hidden">
        <div className="w-full h-full flex items-center justify-center text-6xl bg-gradient-to-br from-gb-surface to-gb-card group-hover:scale-110 transition-transform duration-500">
          {catEmoji}
        </div>
        {/* Status badge */}
        <span className={`absolute top-2.5 right-2.5 text-[0.68rem] font-bold px-2.5 py-1 rounded-lg border ${STATUS_STYLE[status] || STATUS_STYLE.Published}`}>
          {status}
        </span>
      </div>
      {/* Body */}
      <div className="p-4 flex flex-col gap-2 flex-1">
        <h3 className="text-[0.92rem] font-bold text-ink leading-snug">{tip.tip_english || tip.title || 'Eco Tip'}</h3>
        <p className="text-[0.72rem] text-ink-muted leading-relaxed line-clamp-2">{tip.tip_urdu || tip.description || ''}</p>
        <div className="flex gap-2 mt-auto pt-2">
          <button onClick={() => onEdit(tip)}
            className="btn btn-ghost btn-sm flex-1 justify-center gap-1.5 text-[0.76rem]">
            <Pencil size={12}/> Edit
          </button>
          <button className="btn btn-ghost btn-sm flex-1 justify-center gap-1.5 text-[0.76rem]">
            <Calendar size={12}/> Schedule
          </button>
        </div>
      </div>
    </div>
  )
}

/* ── Create/Edit Tip Modal ─────────────────────────────────────────────────── */
function TipModal({ open, tip, onClose, onSave }) {
  const [form, setForm] = useState({ waste_category:'PLASTIC', tip_english:'', tip_urdu:'', category:'AWARENESS', priority:1 })
  useEffect(() => { if (tip) setForm({ ...form, ...tip }) }, [tip])
  const set = (k,v) => setForm(p=>({...p,[k]:v}))

  return (
    <Modal open={open} onClose={onClose} title={tip?.id ? 'Edit Eco Tip' : 'Create New Tip'} width="max-w-lg">
      <div className="space-y-3">
        <div>
          <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Waste Category</label>
          <select value={form.waste_category} onChange={e=>set('waste_category',e.target.value)} className="input text-[0.82rem] py-2">
            {['PLASTIC','PAPER','METAL','GLASS','ORGANIC','E_WASTE','HAZARDOUS','TEXTILE','OTHER'].map(c=>(
              <option key={c}>{c}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Tip (English)</label>
          <textarea value={form.tip_english} onChange={e=>set('tip_english',e.target.value)}
            rows={3} placeholder="Enter eco tip in English..."
            className="input text-[0.82rem] py-2 resize-none"/>
        </div>
        <div>
          <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Tip (اردو)</label>
          <textarea value={form.tip_urdu} onChange={e=>set('tip_urdu',e.target.value)}
            rows={3} placeholder="اردو میں ٹپ درج کریں..." dir="rtl"
            className="input text-[0.82rem] py-2 resize-none text-right"/>
        </div>
        <div className="flex gap-2 justify-end pt-1">
          <button className="btn btn-ghost btn-sm" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary btn-sm" onClick={() => { onSave(form); onClose() }}>
            {tip?.id ? 'Update Tip' : 'Create Tip'}
          </button>
        </div>
      </div>
    </Modal>
  )
}

export default function EcoTips() {
  const [tips,         setTips]         = useState([])
  const [search,       setSearch]       = useState('')
  const [loading,      setLoading]      = useState(true)
  const [tipModal,     setTipModal]     = useState(false)
  const [editTip,      setEditTip]      = useState(null)
  const [notifType,    setNotifType]    = useState('Push')
  const [audience,     setAudience]     = useState('All Users')
  const [msgTitle,     setMsgTitle]     = useState('')
  const [msgBody,      setMsgBody]      = useState('')
  const [sending,      setSending]      = useState(false)
  const [recentActivity, setRecent]     = useState([
    { icon:'✓', label:'Weekly Recycling Reminder', meta:'Sent to All Users • 2h ago', color:'bg-eco' },
    { icon:'◷', label:'Event: Beach Cleanup',      meta:'Scheduled for Tomorrow • Karachi', color:'bg-sky-500' },
  ])

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await tipsApi.getAll({ limit: 8 })
      const data = Array.isArray(res.data) ? res.data : []
      setTips(data.length ? data : MOCK_TIPS)
    } catch { setTips(MOCK_TIPS) }
    finally { setLoading(false) }
  }, [])

  useEffect(() => { load() }, [load])

  const handleSave = async (form) => {
    try {
      if (form.id) await tipsApi.update(form.id, form)
      else         await tipsApi.create(form)
      load()
    } catch(e) { console.error(e) }
  }

  const handleBroadcast = async () => {
    if (!msgTitle.trim() || !msgBody.trim()) return
    setSending(true)
    try {
      await notificationsApi.createCampaign({
        title_english: msgTitle, title_urdu: msgTitle,
        message_english: msgBody, message_urdu: msgBody,
        target_audience: audience === 'All Users' ? 'ALL' : 'ACTIVE_USERS',
      })
      setRecent(p => [{ icon:'✓', label:msgTitle, meta:`Sent to ${audience} • Just now`, color:'bg-eco' }, ...p.slice(0,3)])
      setMsgTitle(''); setMsgBody('')
    } catch(e) { console.error(e) }
    finally { setSending(false) }
  }

  const filtered = tips.filter(t =>
    !search || (t.tip_english||t.title||'').toLowerCase().includes(search.toLowerCase())
  )

  return (
    <Layout title="Eco-Tips & Notification Management" subtitle="Manage educational content and broadcast alerts">
      {/* Header actions */}
      <div className="flex items-center justify-between mb-5">
        <div/>
        <div className="flex items-center gap-3">
          <div className="flex bg-gb-card border border-gb-border rounded-lg overflow-hidden">
            {['English','Urdu'].map(l => (
              <button key={l}
                className={`px-4 py-1.5 text-[0.78rem] font-semibold transition-all cursor-pointer border-none font-sans
                  ${l==='English' ? 'bg-eco text-ink-inverse' : 'bg-transparent text-ink-muted hover:text-ink'}`}>
                {l}
              </button>
            ))}
          </div>
          <button onClick={() => { setEditTip(null); setTipModal(true) }}
            className="btn btn-primary gap-2 text-[0.82rem]">
            <Plus size={14}/> Create New Tip
          </button>
        </div>
      </div>

      <div className="flex gap-6">
        {/* ── Left: Educational Content ────────────────────────── */}
        <div className="flex-1 min-w-0">
          {/* Section header + search */}
          <div className="flex items-center justify-between mb-4">
            <h3 className="flex items-center gap-2 text-[0.95rem] font-bold text-ink">
              🎓 Educational Content
            </h3>
            <div className="relative">
              <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-muted pointer-events-none"/>
              <input value={search} onChange={e=>setSearch(e.target.value)}
                placeholder="Search tips..."
                className="input pl-9 w-52 text-[0.8rem] py-2"/>
            </div>
          </div>

          {loading ? <Spinner/> : filtered.length === 0 ? <EmptyState icon="💡" message="No tips found"/> : (
            <div className="grid grid-cols-2 gap-4">
              {filtered.map((tip, i) => (
                <TipCard key={tip.id||i} tip={tip} onEdit={(t) => { setEditTip(t); setTipModal(true) }}/>
              ))}
            </div>
          )}
        </div>

        {/* ── Right: Broadcast panel ────────────────────────────── */}
        <div className="w-72 flex-shrink-0">
          <div className="card p-5 space-y-4">
            <h3 className="flex items-center gap-2 text-[0.95rem] font-bold text-ink">
              📢 Broadcast Notifications
            </h3>

            {/* Compose */}
            <div className="space-y-2.5">
              <p className="text-[0.66rem] font-bold tracking-[0.1em] uppercase text-ink-muted">Compose Message</p>
              <input value={msgTitle} onChange={e=>setMsgTitle(e.target.value)}
                placeholder="Title (e.g., Collection Day Alert)"
                className="input text-[0.8rem] py-2"/>
              <textarea value={msgBody} onChange={e=>setMsgBody(e.target.value)}
                placeholder="Type your notification message here..."
                rows={4} className="input text-[0.8rem] py-2 resize-none"/>
            </div>

            {/* Target audience */}
            <div className="space-y-2">
              <p className="text-[0.66rem] font-bold tracking-[0.1em] uppercase text-ink-muted">Target Audience</p>
              <select value={audience} onChange={e=>setAudience(e.target.value)}
                className="input text-[0.8rem] py-2 bg-gb-input">
                <option>All Users</option>
                <option>Active Users</option>
              </select>
              <div className="flex items-center gap-2 flex-wrap">
                <span className="flex items-center gap-1.5 text-[0.72rem] bg-gb-surface border border-gb-border rounded-full px-2.5 py-1 text-ink-sub">
                  Lahore <button className="ml-0.5 hover:text-red-400"><X size={10}/></button>
                </span>
                <button className="text-[0.72rem] text-eco font-medium hover:underline bg-transparent border-none cursor-pointer">
                  + Add Filter
                </button>
              </div>
            </div>

            {/* Notification type */}
            <div className="space-y-2">
              <p className="text-[0.66rem] font-bold tracking-[0.1em] uppercase text-ink-muted">Notification Type</p>
              <div className="grid grid-cols-2 gap-2">
                {[
                  { label:'Push',   icon:'🔔' },
                  { label:'In-App', icon:'💬' },
                ].map(({ label, icon }) => (
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

            {/* Send buttons */}
            <button onClick={handleBroadcast} disabled={sending||!msgTitle.trim()||!msgBody.trim()}
              className="btn btn-primary w-full justify-center gap-2 py-3 text-[0.85rem] disabled:opacity-50">
              ▶ {sending ? 'Sending…' : 'Send Broadcast'}
            </button>
            <button className="w-full py-2.5 rounded-xl border border-gb-border bg-transparent text-ink-sub text-[0.82rem] font-semibold hover:border-eco-border hover:text-eco transition-all cursor-pointer">
              Save as Draft
            </button>

            {/* Recent activity */}
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

      <TipModal open={tipModal} tip={editTip} onClose={() => setTipModal(false)} onSave={handleSave}/>
    </Layout>
  )
}

const MOCK_TIPS = [
  { id:'1', waste_category:'PLASTIC',  tip_english:'The Impact of Microplastics', tip_urdu:'Microplastics are tiny plastic particles less than 5mm in diamet...', status:'Published' },
  { id:'2', waste_category:'ORGANIC',  tip_english:'Composting 101: Basics',      tip_urdu:'Turn your kitchen scraps into gold for your garden. A beginner\'s gui...', status:'Draft' },
  { id:'3', waste_category:'PLASTIC',  tip_english:'Sorting Guide: Plastics',     tip_urdu:'Not all plastics are created equal. Understand the numbers 1-7 on...', status:'Scheduled' },
  { id:'4', waste_category:'TEXTILE',  tip_english:'Zero Waste Shopping',         tip_urdu:'Simple swaps you can make at the grocery store to reduce your...', status:'Published' },
]