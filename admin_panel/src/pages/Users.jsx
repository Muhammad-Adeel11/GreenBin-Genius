import React, { useEffect, useState, useCallback } from 'react'
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid,
} from 'recharts'
import {
  Search, TrendingUp, TrendingDown, Minus,
  Download, BrainCircuit, MoreVertical, Eye,
  ShieldBan, UserCog, Loader2,
} from 'lucide-react'
import Layout from '../components/layout/Layout'
import { Badge, Modal, Spinner, EmptyState } from '../components/ui/index.jsx'
import { userApi, analyticsApi, adminApi } from '../api'

/* ── Rank badge ────────────────────────────────────────────────────────────── */
function RankBadge({ rank }) {
  if (rank === 1) return <div className="w-8 h-8 rounded-full bg-yellow-400/20 border border-yellow-400/40 flex items-center justify-center text-yellow-400 font-bold text-sm">1</div>
  if (rank === 2) return <div className="w-8 h-8 rounded-full bg-slate-400/20 border border-slate-400/40 flex items-center justify-center text-slate-300 font-bold text-sm">2</div>
  if (rank === 3) return <div className="w-8 h-8 rounded-full bg-orange-400/20 border border-orange-400/40 flex items-center justify-center text-orange-400 font-bold text-sm">3</div>
  return <div className="w-8 h-8 flex items-center justify-center text-ink-muted font-semibold text-sm">{rank}</div>
}

/* ── Sustainability score badge ─────────────────────────────────────────────── */
function SustScore({ score }) {
  const pct = Math.min(100, score || 0)
  const color = pct >= 90 ? 'text-eco border-eco/30 bg-eco-muted' : pct >= 75 ? 'text-yellow-400 border-yellow-400/30 bg-yellow-400/10' : 'text-ink-sub border-gb-border bg-gb-surface'
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-lg text-[0.76rem] font-bold border ${color}`}>
      {pct}/100
    </span>
  )
}

/* ── Trend icon ─────────────────────────────────────────────────────────────── */
function Trend({ value }) {
  if (!value || value === 0) return <Minus size={14} className="text-ink-muted" />
  return value > 0
    ? <TrendingUp  size={14} className="text-eco" />
    : <TrendingDown size={14} className="text-red-400" />
}

/* ── User avatar (initials) ─────────────────────────────────────────────────── */
function UserAvatar({ name, size = 'sm' }) {
  const initials = name?.split(' ').map(n=>n[0]).join('').slice(0,2).toUpperCase() || '??'
  const colors   = ['bg-eco-muted text-eco','bg-sky-500/15 text-sky-400','bg-yellow-500/15 text-yellow-400','bg-purple-500/15 text-purple-400','bg-orange-500/15 text-orange-400']
  const idx      = (name?.charCodeAt(0) || 0) % colors.length
  const cls      = size === 'sm' ? 'w-8 h-8 text-[0.72rem]' : 'w-10 h-10 text-[0.82rem]'
  return (
    <div className={`${cls} rounded-full ${colors[idx]} flex items-center justify-center font-bold border border-white/10 flex-shrink-0`}>
      {initials}
    </div>
  )
}

/* ── Action dropdown ─────────────────────────────────────────────────────────── */
function ActionMenu({ user, onRefresh }) {
  const [open, setOpen] = useState(false)

  const handleRole = async (role) => {
    try { await userApi.updateRole(user.id||user._id, role); onRefresh(); setOpen(false) }
    catch(e) { console.error(e) }
  }
  const handleSuspend = async () => {
    try { await userApi.suspend(user.id||user._id, true, 'Admin action'); onRefresh(); setOpen(false) }
    catch(e) { console.error(e) }
  }

  return (
    <div className="relative">
      <button onClick={()=>setOpen(o=>!o)}
        className="w-7 h-7 rounded-lg flex items-center justify-center text-ink-muted hover:text-eco hover:bg-eco-muted transition-all cursor-pointer border-none bg-transparent">
        <MoreVertical size={14}/>
      </button>
      {open && (
        <div className="absolute right-0 top-8 z-50 w-44 bg-gb-card border border-gb-border rounded-xl shadow-modal overflow-hidden"
          onMouseLeave={()=>setOpen(false)}>
          {[
            { label:'Make Admin',     icon:UserCog,   action:()=>handleRole('ADMIN') },
            { label:'Make Moderator', icon:UserCog,   action:()=>handleRole('MODERATOR') },
            { label:'Suspend User',   icon:ShieldBan, action:handleSuspend, cls:'text-red-400' },
          ].map(({label,icon:Icon,action,cls=''})=>(
            <button key={label} onClick={action}
              className={`w-full flex items-center gap-2.5 px-3.5 py-2.5 text-[0.78rem] font-medium hover:bg-eco-muted transition-colors cursor-pointer bg-transparent border-none text-left ${cls||'text-ink-sub hover:text-eco'}`}>
              <Icon size={13}/> {label}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

export default function Users() {
  const [leaderboard, setLeaderboard]   = useState([])
  const [history,     setHistory]       = useState([])
  const [histSearch,  setHistSearch]    = useState('')
  const [growthData,  setGrowthData]    = useState([])
  const [loadingLead, setLoadingLead]   = useState(true)
  const [loadingHist, setLoadingHist]   = useState(false)

  const loadLeaderboard = useCallback(async () => {
    setLoadingLead(true)
    try {
      const res = await userApi.getLeaderboard(10)
      setLeaderboard(Array.isArray(res.data) ? res.data : MOCK_LEADERS)
    } catch { setLeaderboard(MOCK_LEADERS) }
    finally  { setLoadingLead(false) }
  }, [])

  const loadGrowth = useCallback(async () => {
    try {
      const res = await analyticsApi.getDashboard()
      const raw = res.data?.user_growth || []
      if (raw.length >= 4) {
        const monthly = {}
        raw.forEach(d => {
          const month = d.date?.slice(0,7)
          if (month) monthly[month] = (monthly[month]||0) + d.count
        })
        const sorted = Object.entries(monthly).slice(-6).map(([k,v])=>({
          month: new Date(k+'-01').toLocaleString('en-US',{month:'short'}),
          users: v,
        }))
        setGrowthData(sorted)
        return
      }
    } catch {}
    setGrowthData(MOCK_GROWTH)
  }, [])

  const searchHistory = useCallback(async (q) => {
    if (!q.trim()) { setHistory([]); return }
    setLoadingHist(true)
    try {
      const res = await userApi.search(q, { limit:20 })
      setHistory(Array.isArray(res.data) ? res.data : [])
    } catch { setHistory([]) }
    finally  { setLoadingHist(false) }
  }, [])

  useEffect(() => { loadLeaderboard(); loadGrowth() }, [])

  useEffect(() => {
    const t = setTimeout(() => searchHistory(histSearch), 400)
    return () => clearTimeout(t)
  }, [histSearch])

  /* ── Export users CSV ────────────────────────────────────────────────── */
  const handleExport = async () => {
    try {
      const res = await analyticsApi.exportUsers()
      const url = URL.createObjectURL(new Blob([res.data]))
      Object.assign(document.createElement('a'),{href:url,download:`users_${Date.now()}.csv`}).click()
      URL.revokeObjectURL(url)
    } catch(e) { console.error(e) }
  }

  return (
    <Layout title="Users & Leaderboard">
      <div className="flex gap-5">

        {/* ── Left main ─────────────────────────────────────────────── */}
        <div className="flex-1 min-w-0 space-y-6">

          {/* ── Global Leaderboard ─────────────────────────────────── */}
          <div>
            <h1 className="text-[1.65rem] font-bold text-ink tracking-tight leading-tight">Global Leaderboard</h1>
            <p className="text-[0.82rem] text-ink-muted mt-1 mb-4">Top 10 eco-contributors ranked by sustainability score.</p>

            <div className="card overflow-hidden">
              {loadingLead ? <Spinner/> : (
                <table className="tbl">
                  <thead>
                    <tr>
                      <th className="w-12">Rank</th>
                      <th>User Profile</th>
                      <th className="text-right">Items Classified</th>
                      <th className="text-center">Sust. Score</th>
                      <th className="text-center">Trend</th>
                    </tr>
                  </thead>
                  <tbody>
                    {leaderboard.map((u, i) => {
                      const score = Math.min(100, Math.round((u.contribution_points||0) / 10))
                      return (
                        <tr key={u.user_id||u.id||i}>
                          <td><RankBadge rank={i+1}/></td>
                          <td>
                            <div className="flex items-center gap-3">
                              <UserAvatar name={u.name} size="sm"/>
                              <div>
                                <p className="text-[0.85rem] font-semibold text-ink">{u.name || 'Unknown'}</p>
                                <p className="text-[0.7rem] text-ink-muted">{u.email || `user${i+1}@example.com`}</p>
                              </div>
                            </div>
                          </td>
                          <td className="text-right font-semibold">
                            {(u.total_classifications||0).toLocaleString()}
                          </td>
                          <td className="text-center"><SustScore score={score}/></td>
                          <td className="text-center"><Trend value={i < 3 ? 1 : i === 3 ? 0 : -1}/></td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              )}
            </div>
          </div>

          {/* ── User History Search ────────────────────────────────── */}
          <div>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-[1.1rem] font-bold text-ink">User History Search</h2>
              <div className="relative">
                <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-muted pointer-events-none"/>
                <input
                  value={histSearch}
                  onChange={e=>setHistSearch(e.target.value)}
                  placeholder="Search by username or email..."
                  className="input pl-9 w-72 text-[0.82rem] py-2"
                />
              </div>
            </div>

            <div className="card overflow-hidden">
              {loadingHist ? (
                <Spinner/>
              ) : !histSearch.trim() ? (
                <EmptyState icon="🔍" message="Type a name or email above to search user history"/>
              ) : history.length === 0 ? (
                <EmptyState icon="👤" message="No users found"/>
              ) : (
                <table className="tbl">
                  <thead>
                    <tr>
                      <th>Date &amp; Time</th>
                      <th>Waste Image</th>
                      <th>AI Prediction</th>
                      <th>User</th>
                      <th>Accuracy</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {history.map((u, i) => (
                      <tr key={u.id||i}>
                        <td className="text-[0.76rem]">
                          <p className="text-ink font-medium">{new Date(u.created_at||Date.now()).toLocaleDateString('en-US',{month:'short',day:'numeric',year:'numeric'})}</p>
                          <p className="text-ink-muted">{new Date(u.created_at||Date.now()).toLocaleTimeString('en-US',{hour:'2-digit',minute:'2-digit'})}</p>
                        </td>
                        <td>
                          <div className="w-12 h-12 rounded-lg bg-gb-surface border border-gb-border flex items-center justify-center text-xl overflow-hidden">
                            ♻️
                          </div>
                        </td>
                        <td>
                          <p className="text-[0.84rem] font-semibold text-ink">{u.name||'User'}</p>
                          <span className="badge badge-green text-[0.66rem] mt-0.5">Recyclable</span>
                        </td>
                        <td>
                          <div className="flex items-center gap-2">
                            <UserAvatar name={u.name} size="sm"/>
                            <span className="text-[0.82rem] text-ink">{u.name||'Unknown'}</span>
                          </div>
                        </td>
                        <td>
                          {u.total_classifications > 100 ? (
                            <span className="flex items-center gap-1.5 text-eco text-[0.78rem] font-semibold">
                              <CheckCircle size={13}/> Verified
                            </span>
                          ) : (
                            <span className="flex items-center gap-1.5 text-yellow-400 text-[0.78rem] font-semibold">
                              ⚠ Pending
                            </span>
                          )}
                        </td>
                        <td>
                          <ActionMenu user={u} onRefresh={loadLeaderboard}/>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        </div>

        {/* ── Right sidebar ──────────────────────────────────────────── */}
        <div className="w-60 flex-shrink-0 space-y-4">
          <h3 className="text-[0.95rem] font-bold text-ink">Contribution Analytics</h3>

          {/* Most Active Regions */}
          <div className="card p-4 space-y-3">
            <div className="flex items-center justify-between">
              <p className="text-[0.66rem] font-bold tracking-[0.1em] uppercase text-ink-muted">Most Active Regions</p>
              <button className="text-[0.7rem] text-eco font-semibold cursor-pointer bg-transparent border-none">View All</button>
            </div>
            {/* World map placeholder */}
            <div className="h-28 bg-gb-surface rounded-lg border border-gb-border flex items-center justify-center overflow-hidden relative">
              <div className="absolute inset-0 opacity-20" style={{
                backgroundImage: `radial-gradient(circle at 30% 50%, #22c55e 2px, transparent 2px),
                  radial-gradient(circle at 60% 40%, #22c55e 3px, transparent 3px),
                  radial-gradient(circle at 80% 60%, #f59e0b 2px, transparent 2px)`,
                backgroundSize: '100% 100%',
              }}/>
              <span className="relative z-10 text-[0.75rem] font-semibold text-eco flex items-center gap-1.5 bg-gb-card/90 px-3 py-1.5 rounded-full border border-eco/20">
                🌍 Global Data
              </span>
            </div>
            {/* Region bars */}
            {[
              { name:'North America', pct:78 },
              { name:'Europe',        pct:62 },
              { name:'Asia Pacific',  pct:45 },
            ].map(r => (
              <div key={r.name}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-[0.72rem] text-ink-sub">{r.name}</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="flex-1 h-1.5 bg-gb-surface rounded-full overflow-hidden">
                    <div className="h-full bg-eco rounded-full" style={{width:`${r.pct}%`}}/>
                  </div>
                  <div className="w-5 h-1.5 bg-gb-border rounded-full"/>
                </div>
              </div>
            ))}
          </div>

          {/* User Growth chart */}
          <div className="card p-4">
            <p className="text-[0.66rem] font-bold tracking-[0.1em] uppercase text-ink-muted mb-3">User Growth</p>
            <ResponsiveContainer width="100%" height={100}>
              <BarChart data={growthData} margin={{top:0,right:0,bottom:0,left:-25}}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(34,197,94,0.06)" vertical={false}/>
                <XAxis dataKey="month" tick={{fill:'#4a6e4a',fontSize:9.5}} axisLine={false} tickLine={false}/>
                <YAxis tick={{fill:'#4a6e4a',fontSize:9.5}} axisLine={false} tickLine={false}/>
                <Tooltip
                  contentStyle={{background:'#111f11',border:'1px solid rgba(34,197,94,0.15)',borderRadius:8,fontSize:11}}
                  formatter={v=>[`${v} users`,'']}/>
                <Bar dataKey="users" fill="#22c55e" radius={[3,3,0,0]}/>
              </BarChart>
            </ResponsiveContainer>
            <div className="flex items-center justify-between mt-3 pt-3 border-t border-gb-border">
              <div>
                <p className="text-[1rem] font-bold text-eco">+24%</p>
                <p className="text-[0.65rem] text-ink-muted">vs last month</p>
              </div>
              <button onClick={handleExport}
                className="btn btn-ghost btn-sm text-[0.72rem] gap-1.5">
                <Download size={11}/> Report
              </button>
            </div>
          </div>

          {/* AI Model Update card */}
          <div className="card p-4 flex items-start gap-3 border-eco/20">
            <div className="w-9 h-9 rounded-full bg-eco-muted border border-eco-border flex items-center justify-center flex-shrink-0">
              <BrainCircuit size={16} className="text-eco"/>
            </div>
            <div>
              <p className="text-[0.8rem] font-bold text-ink">AI Model Update</p>
              <p className="text-[0.68rem] text-ink-muted mt-0.5 leading-relaxed">
                New version v2.4 ready for deployment. Improved plastic detection accuracy.
              </p>
              <button className="text-[0.72rem] text-eco font-semibold mt-1.5 bg-transparent border-none cursor-pointer p-0 hover:underline">
                Review Update →
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  )
}

/* ── CheckCircle2 import fix ──────────────────────────────────────────────── */
function CheckCircle({ size, className }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className={className}><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22,4 12,14.01 9,11.01"/></svg>
}

/* ── Mock data ─────────────────────────────────────────────────────────────── */
const MOCK_LEADERS = [
  {user_id:'1',name:'Sarah Jenkins',email:'sarah.j@example.com',total_classifications:1245,contribution_points:980},
  {user_id:'2',name:'Ali Khan',      email:'ali.k@example.com',  total_classifications:1102,contribution_points:950},
  {user_id:'3',name:'Maria Rodriguez',email:'maria.r@example.com',total_classifications:980,contribution_points:920},
  {user_id:'4',name:'John Doe',      email:'john.doe@example.com',total_classifications:850,contribution_points:890},
  {user_id:'5',name:'Emily Chen',    email:'emily.c@example.com', total_classifications:820,contribution_points:880},
]
const MOCK_GROWTH = [
  {month:'May',users:42},{month:'Jun',users:58},{month:'Jul',users:71},
  {month:'Aug',users:89},{month:'Sep',users:105},{month:'Oct',users:134},
]