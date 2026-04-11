import React, { useEffect, useState, useCallback } from 'react'
import {
  User, Shield, UserCog, History,
  Pencil, Trash2, Plus, CheckCircle2,
  BrainCircuit, MapPin, UserPlus, ArrowRight,
} from 'lucide-react'
import Layout from '../components/layout/Layout'
import { Badge, Modal, Spinner } from '../components/ui/index.jsx'
import useAuthStore from '../store/authStore'
import useAppStore from '../store/appStore'
import { adminApi, userApi } from '../api'

/* ── Role badge ───────────────────────────────────────────────────────────── */
const ROLE_BADGE = {
  'Super Admin': 'bg-sky-500/15 text-sky-400 border-sky-500/20',
  'ADMIN':       'bg-sky-500/15 text-sky-400 border-sky-500/20',
  'Editor':      'bg-eco-muted text-eco border-eco/20',
  'MODERATOR':   'bg-eco-muted text-eco border-eco/20',
  'Viewer':      'bg-white/5 text-ink-sub border-gb-border',
  'USER':        'bg-white/5 text-ink-sub border-gb-border',
}

/* ── Log action icon ──────────────────────────────────────────────────────── */
const LOG_ICONS = {
  'Model Retrained':  { icon:BrainCircuit, bg:'bg-purple-500/15 text-purple-400' },
  'New Bin Added':    { icon:MapPin,       bg:'bg-eco-muted text-eco'            },
  'Route Optimized':  { icon:ArrowRight,   bg:'bg-yellow-500/15 text-yellow-400' },
  'User Invite Sent': { icon:UserPlus,     bg:'bg-sky-500/15 text-sky-400'       },
}

function LogIcon({ action }) {
  const match = Object.entries(LOG_ICONS).find(([k]) => action?.includes(k))
  if (!match) return <div className="w-7 h-7 rounded-full bg-gb-surface border border-gb-border flex items-center justify-center text-ink-muted text-[0.65rem]">•</div>
  const [, { icon:Icon, bg }] = match
  return (
    <div className={`w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 ${bg}`}>
      <Icon size={13}/>
    </div>
  )
}

function timeAgo(ts) {
  if (!ts) return 'Unknown'
  const diff = Date.now() - new Date(ts).getTime()
  const m = Math.floor(diff / 60000)
  if (m < 1)  return 'Just now'
  if (m < 60) return `${m} mins ago`
  const h = Math.floor(m / 60)
  if (h < 24) return `${h} hours ago`
  return 'Yesterday, ' + new Date(ts).toLocaleTimeString('en-US',{hour:'2-digit',minute:'2-digit'})
}

/* ── Section wrapper ──────────────────────────────────────────────────────── */
function Section({ icon:Icon, title, children }) {
  return (
    <div className="bg-white/[0.03] border border-gb-border rounded-xl2 p-6">
      <h3 className="flex items-center gap-2.5 text-[1rem] font-bold text-ink mb-5">
        <Icon size={18} className="text-eco"/> {title}
      </h3>
      {children}
    </div>
  )
}

export default function Settings() {
  const { user } = useAuthStore()
  const { language, setLanguage } = useAppStore()

  /* Profile form */
  const [name,     setName]     = useState(user?.name     || 'Admin User')
  const [email,    setEmail]    = useState(user?.email    || 'admin@greenbin.ai')
  const [phone,    setPhone]    = useState('+92 300 1234567')
  const [lang,     setLang]     = useState(language === 'UR' ? 'Urdu' : 'English')
  const [saved,    setSaved]    = useState(false)

  /* Security form */
  const [curPw,   setCurPw]    = useState('')
  const [newPw,   setNewPw]    = useState('')
  const [twoFA,   setTwoFA]    = useState(true)

  /* Admin list */
  const [admins,   setAdmins]   = useState(MOCK_ADMINS)
  const [logs,     setLogs]     = useState([])
  const [loadLogs, setLoadLogs] = useState(true)
  const [inviteModal, setInvite]= useState(false)

  const loadAuditLogs = useCallback(async () => {
    setLoadLogs(true)
    try {
      const res = await adminApi.getLogs({ limit: 6 })
      setLogs(Array.isArray(res.data) ? res.data : MOCK_LOGS)
    } catch { setLogs(MOCK_LOGS) }
    finally { setLoadLogs(false) }
  }, [])

  useEffect(() => { loadAuditLogs() }, [])

  const handleSave = () => {
    setSaved(true)
    setLanguage(lang === 'Urdu' ? 'UR' : 'EN')
    setTimeout(() => setSaved(false), 2500)
  }

  return (
    <Layout title="Admin Settings & Security" subtitle="Manage your profile, system access, and view audit logs.">
      <div className="space-y-6 max-w-4xl">

        {/* ── Profile Settings ─────────────────────────────────────── */}
        <Section icon={User} title="Profile Settings">
          <div className="grid grid-cols-2 gap-4 mb-4">
            <div className="space-y-1.5">
              <label className="text-[0.74rem] font-semibold text-ink-sub">Full Name</label>
              <input value={name} onChange={e=>setName(e.target.value)} className="input py-2.5"/>
            </div>
            <div className="space-y-1.5">
              <label className="text-[0.74rem] font-semibold text-ink-sub">Email Address</label>
              <input value={email} onChange={e=>setEmail(e.target.value)} type="email" className="input py-2.5"/>
            </div>
            <div className="space-y-1.5">
              <label className="text-[0.74rem] font-semibold text-ink-sub">Phone Number</label>
              <input value={phone} onChange={e=>setPhone(e.target.value)} className="input py-2.5"/>
            </div>
            <div className="space-y-1.5">
              <label className="text-[0.74rem] font-semibold text-ink-sub">Preferred Language</label>
              <div className="flex items-center gap-3 h-10">
                <span className={`text-[0.84rem] font-medium ${lang==='English'?'text-ink':'text-ink-muted'}`}>English</span>
                <div
                  onClick={() => setLang(l => l==='English' ? 'Urdu' : 'English')}
                  className={`w-12 h-6 rounded-full transition-all cursor-pointer relative ${lang==='Urdu' ? 'bg-eco' : 'bg-gb-surface border border-gb-border'}`}
                >
                  <div className={`absolute top-0.5 w-5 h-5 rounded-full bg-white shadow transition-all duration-200 ${lang==='Urdu' ? 'left-6' : 'left-0.5'}`}/>
                </div>
                <span className={`text-[0.84rem] font-medium ${lang==='Urdu'?'text-ink':'text-ink-muted'}`}>Urdu (اردو)</span>
              </div>
            </div>
          </div>
          <div className="flex justify-end">
            <button onClick={handleSave} className="btn btn-primary gap-2 px-6">
              {saved ? <><CheckCircle2 size={14}/> Saved!</> : 'Save Changes'}
            </button>
          </div>
        </Section>

        {/* ── Security ─────────────────────────────────────────────── */}
        <Section icon={Shield} title="Security">
          <div className="flex gap-6">
            {/* Change password */}
            <div className="flex-1 space-y-3">
              <h4 className="text-[0.9rem] font-semibold text-ink">Change Password</h4>
              <div className="space-y-1.5">
                <label className="text-[0.72rem] text-ink-sub font-medium">Current Password</label>
                <input value={curPw} onChange={e=>setCurPw(e.target.value)}
                  type="password" placeholder="••••••••" className="input py-2.5"/>
              </div>
              <div className="space-y-1.5">
                <label className="text-[0.72rem] text-ink-sub font-medium">New Password</label>
                <input value={newPw} onChange={e=>setNewPw(e.target.value)}
                  type="password" placeholder="••••••••" className="input py-2.5"/>
              </div>
              <button className="text-[0.8rem] text-eco font-semibold hover:underline bg-transparent border-none cursor-pointer p-0 mt-1">
                Update Password
              </button>
            </div>

            {/* 2FA */}
            <div className="w-60 flex-shrink-0">
              <div className="bg-gb-surface border border-gb-border rounded-xl p-4 space-y-3">
                <h4 className="text-[0.88rem] font-bold text-ink">Two-Factor Authentication</h4>
                <p className="text-[0.74rem] text-ink-muted leading-relaxed">Secure your account by requiring a code from your mobile device.</p>
                <div className="flex items-center gap-3">
                  <div
                    onClick={() => setTwoFA(p=>!p)}
                    className={`w-12 h-6 rounded-full transition-all cursor-pointer relative ${twoFA ? 'bg-eco' : 'bg-gb-surface border border-gb-border'}`}
                  >
                    <div className={`absolute top-0.5 w-5 h-5 rounded-full bg-white shadow transition-all duration-200 ${twoFA ? 'left-6' : 'left-0.5'}`}/>
                  </div>
                  {twoFA && <span className="text-eco text-[0.74rem] font-semibold">Enabled</span>}
                </div>
                {twoFA && (
                  <div className="bg-eco-muted border border-eco/20 rounded-lg px-3 py-2 flex items-center gap-2">
                    <CheckCircle2 size={13} className="text-eco flex-shrink-0"/>
                    <span className="text-[0.72rem] text-eco">Enabled on Nov 12, 2023</span>
                  </div>
                )}
              </div>
            </div>
          </div>
        </Section>

        {/* ── Admin Management ─────────────────────────────────────── */}
        <Section icon={UserCog} title="Admin Management">
          <div className="flex items-center justify-between mb-4">
            <div/>
            <button onClick={() => setInvite(true)} className="btn btn-primary gap-2 text-[0.82rem]">
              <Plus size={14}/> Invite New Admin
            </button>
          </div>
          <table className="tbl">
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {admins.map((a, i) => (
                <tr key={a.id||i}>
                  <td className="font-semibold">
                    {a.name}{a.isMe && <span className="text-[0.68rem] text-ink-muted ml-1.5">(You)</span>}
                  </td>
                  <td className="text-ink-sub text-[0.8rem]">{a.email}</td>
                  <td>
                    <span className={`badge text-[0.68rem] border ${ROLE_BADGE[a.role]||ROLE_BADGE.Viewer}`}>{a.role}</span>
                  </td>
                  <td>
                    <span className={`flex items-center gap-1.5 text-[0.78rem] font-medium ${a.status==='Active'?'text-eco':'text-ink-muted'}`}>
                      <span className={`w-1.5 h-1.5 rounded-full ${a.status==='Active'?'bg-eco':'bg-gb-border'}`}/>
                      {a.status}
                    </span>
                  </td>
                  <td>
                    <div className="flex items-center gap-1.5">
                      <button className="w-7 h-7 rounded-lg flex items-center justify-center text-ink-muted hover:text-eco hover:bg-eco-muted transition-all cursor-pointer border-none bg-transparent">
                        <Pencil size={13}/>
                      </button>
                      {!a.isMe && (
                        <button className="w-7 h-7 rounded-lg flex items-center justify-center text-ink-muted hover:text-red-400 hover:bg-red-500/10 transition-all cursor-pointer border-none bg-transparent">
                          <Trash2 size={13}/>
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Section>

        {/* ── Activity Log ─────────────────────────────────────────── */}
        <Section icon={History} title="Activity Log">
          {loadLogs ? <Spinner/> : (
            <>
              <table className="tbl">
                <thead>
                  <tr>
                    <th>Action</th>
                    <th>Performed By</th>
                    <th>IP Address</th>
                    <th>Timestamp</th>
                  </tr>
                </thead>
                <tbody>
                  {logs.map((log, i) => (
                    <tr key={log.id||i}>
                      <td>
                        <div className="flex items-center gap-2.5">
                          <LogIcon action={log.action}/>
                          <span className="text-[0.82rem] font-medium text-ink">{log.action || log.detail?.action || 'System action'}</span>
                        </div>
                      </td>
                      <td className="text-[0.8rem] text-ink-sub">{log.performed_by || log.admin_id?.slice(-8) || 'System'}</td>
                      <td className="font-mono text-[0.74rem] text-sky-400">{log.ip || '192.168.1.45'}</td>
                      <td className="text-[0.76rem] text-ink-muted">{timeAgo(log.timestamp)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <button className="w-full mt-4 py-2.5 text-eco text-[0.8rem] font-semibold hover:bg-eco-muted rounded-lg transition-all cursor-pointer border border-dashed border-eco/25 bg-transparent">
                View All Activity
              </button>
            </>
          )}
        </Section>
      </div>

      {/* Invite Admin Modal */}
      <Modal open={inviteModal} onClose={() => setInvite(false)} title="Invite New Admin" width="max-w-sm">
        <div className="space-y-3">
          {[['Email','email','admin@example.com'],['Full Name','text','John Doe'],['Role','text','MODERATOR']].map(([l,t,ph])=>(
            <div key={l} className="space-y-1.5">
              <label className="text-[0.74rem] font-semibold text-ink-sub">{l}</label>
              <input type={t} placeholder={ph} className="input py-2"/>
            </div>
          ))}
          <div className="flex gap-2 justify-end pt-1">
            <button className="btn btn-ghost btn-sm" onClick={() => setInvite(false)}>Cancel</button>
            <button className="btn btn-primary btn-sm" onClick={() => setInvite(false)}>Send Invite</button>
          </div>
        </div>
      </Modal>
    </Layout>
  )
}

const MOCK_ADMINS = [
  { id:'1', name:'Adil Malik',  email:'adil.malik@greenbin.com',  role:'Super Admin', status:'Active',  isMe:true  },
  { id:'2', name:'Zara Ahmed',  email:'zara.a@greenbin.com',      role:'Editor',      status:'Active',  isMe:false },
  { id:'3', name:'Bilal Khan',  email:'bilal.k@greenbin.com',     role:'Viewer',      status:'Offline', isMe:false },
]
const MOCK_LOGS = [
  { id:'1', action:'Model Retrained',  performed_by:'Adil Malik',    ip:'192.168.1.45',  timestamp:new Date().toISOString() },
  { id:'2', action:'New Bin Added',    performed_by:'Zara Ahmed',    ip:'203.11.56.22',  timestamp:new Date(Date.now()-7200000).toISOString() },
  { id:'3', action:'Route Optimized', performed_by:'System (Auto)', ip:'Server-Internal',timestamp:new Date(Date.now()-18000000).toISOString() },
  { id:'4', action:'User Invite Sent',performed_by:'Adil Malik',    ip:'192.168.1.45',  timestamp:new Date(Date.now()-86400000).toISOString() },
]