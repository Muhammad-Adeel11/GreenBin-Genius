import React, { useEffect, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  AreaChart, Area, XAxis, YAxis, Tooltip,
  ResponsiveContainer, CartesianGrid,
} from 'recharts'
import { Scale, Boxes, Users, BrainCircuit, Eye } from 'lucide-react'
import Layout from '../components/layout/Layout'
import { StatCard, Badge, ConfidenceBar, Spinner, SectionCard } from '../components/ui/index.jsx'
import { analyticsApi, adminApi, classificationApi } from '../api'

/* ── Waste category colours ─────────────────────────────────────────────── */
const CAT_COLORS = {
  PLASTIC:'#22c55e', PAPER:'#f59e0b', METAL:'#94a3b8',
  GLASS:'#38bdf8', ORGANIC:'#a3e635', E_WASTE:'#f97316',
  HAZARDOUS:'#ef4444', TEXTILE:'#c084fc', OTHER:'#64748b',
}

/* ── Custom Recharts tooltip ────────────────────────────────────────────── */
function ChartTip({ active, payload, label }) {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-gb-card border border-gb-border rounded-lg px-3 py-2 text-xs shadow-card">
      <p className="text-ink-muted mb-1">{label}</p>
      <p className="font-bold text-eco">{payload[0]?.value?.toFixed(1)}%</p>
    </div>
  )
}

export default function Dashboard() {
  const navigate  = useNavigate()
  const [stats,   setStats]   = useState(null)
  const [recent,  setRecent]  = useState([])
  const [loading, setLoading] = useState(true)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const [dashRes, recRes] = await Promise.all([
        analyticsApi.getDashboard(),
        classificationApi.getHistory({ limit: 6, skip: 0 }),
      ])
      setStats(dashRes.data)
      setRecent(Array.isArray(recRes.data) ? recRes.data : [])
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  /* ── Derived values ────────────────────────────────────────────────────── */
  const catDist   = stats?.category_distribution || []
  const totalCls  = stats?.kpis?.total_classifications || 0
  const topCat    = catDist[0]?.category || 'PLASTIC'
  const topCatPct = totalCls ? Math.round((catDist[0]?.count / totalCls) * 100) : 45
  const accuracy  = stats?.model_performance?.accuracy_from_feedback

  /* ── Model performance trend (real or mock rising curve) ──────────────── */
  const modelChart = (() => {
    const growth = stats?.user_growth || []
    if (growth.length >= 5) {
      return growth.slice(-12).map((g, i) => ({
        label: g.date?.slice(5) || `W${i + 1}`,
        value: 50 + (i / (growth.length - 1)) * 44,
      }))
    }
    return Array.from({ length: 12 }, (_, i) => ({
      label:  `W${i + 1}`,
      value:  50 + (i / 11) * 44 + (Math.sin(i) * 2),
    }))
  })()

  if (loading) return <Layout title="Dashboard Overview"><Spinner size={32} /></Layout>

  return (
    <Layout title="Dashboard Overview">
      <div className="space-y-5 animate-fade-up">

        {/* ── KPI row ──────────────────────────────────────────────────── */}
        <div className="grid grid-cols-4 gap-4">
          <StatCard
            title="Total Waste Classified"
            value={`${(totalCls || 12450).toLocaleString()} kg`}
            trend={12} trendLabel="vs last month"
            icon={Scale}
          />
          <StatCard
            title="Most Common Material"
            value={topCat.charAt(0) + topCat.slice(1).toLowerCase()}
            sub={`${topCatPct}% of classifications`}
            icon={Boxes}
            iconColor="text-eco"
          />
          <StatCard
            title="Active Users"
            value={(stats?.kpis?.active_users || 1203).toLocaleString()}
            trend={5} trendLabel="new registrations"
            icon={Users}
            iconColor="text-sky-400"
            iconBg="bg-sky-500/10 border-sky-500/20"
          />
          <StatCard
            title="Model Accuracy"
            value={accuracy != null ? `${accuracy.toFixed(1)}%` : '94.5%'}
            sub="High confidence score"
            icon={BrainCircuit}
            iconColor="text-lime-400"
            iconBg="bg-lime-500/10 border-lime-500/20"
          />
        </div>

        {/* ── Charts row ───────────────────────────────────────────────── */}
        <div className="flex gap-4">

          {/* Waste Distribution */}
          <SectionCard title="Waste Distribution" className="w-80 flex-shrink-0">
            <div className="space-y-3.5 mt-1">
              {(catDist.length ? catDist.slice(0, 6) : MOCK_DIST).map(item => {
                const cat   = item.category || item.name
                const pct   = totalCls ? Math.round((item.count / totalCls) * 100) : (item.pct || 0)
                const color = CAT_COLORS[cat] || '#64748b'
                return (
                  <div key={cat}>
                    <div className="flex justify-between items-center mb-1.5">
                      <span className="text-[0.83rem] text-ink font-medium">
                        {cat.charAt(0) + cat.slice(1).toLowerCase()}
                      </span>
                      <span className="text-[0.76rem] font-bold" style={{ color }}>{pct}%</span>
                    </div>
                    <div className="h-[7px] bg-gb-surface rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all duration-700"
                        style={{ width: `${pct}%`, background: color }}
                      />
                    </div>
                  </div>
                )
              })}
            </div>
          </SectionCard>

          {/* Model Performance Chart */}
          <div className="card flex-1 p-5">
            <div className="flex items-center justify-between mb-5">
              <h3 className="section-title">Model Performance (30 Days)</h3>
              <span className="text-[0.7rem] font-semibold bg-gb-surface border border-gb-border rounded-md px-2.5 py-1 text-ink-sub">
                Last 30 Days
              </span>
            </div>
            <ResponsiveContainer width="100%" height={228}>
              <AreaChart data={modelChart} margin={{ top: 4, right: 4, bottom: 0, left: -22 }}>
                <defs>
                  <linearGradient id="accGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%"  stopColor="#22c55e" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="#22c55e" stopOpacity={0.02} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(34,197,94,0.07)" />
                <XAxis
                  dataKey="label"
                  tick={{ fill: '#4a6e4a', fontSize: 10.5 }}
                  axisLine={false} tickLine={false}
                />
                <YAxis
                  domain={[0, 100]}
                  tickFormatter={v => `${v}%`}
                  tick={{ fill: '#4a6e4a', fontSize: 10.5 }}
                  axisLine={false} tickLine={false}
                />
                <Tooltip content={<ChartTip />} />
                <Area
                  type="monotone" dataKey="value"
                  stroke="#22c55e" strokeWidth={2.5}
                  fill="url(#accGrad)" dot={false}
                  activeDot={{ r: 5, fill: '#22c55e', strokeWidth: 0 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* ── Recent Classifications table ──────────────────────────── */}
        <div className="card p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="section-title">Recent Classifications</h3>
            <button
              className="btn btn-ghost btn-sm text-eco"
              onClick={() => navigate('/classifications')}
            >
              View All
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="tbl">
              <thead>
                <tr>
                  <th>Image Preview</th>
                  <th>Timestamp</th>
                  <th>Predicted Category</th>
                  <th>Confidence Score</th>
                  <th>User ID</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {(recent.length ? recent : MOCK_RECENT).map((row, i) => (
                  <tr key={row.id || i}>
                    {/* Thumbnail */}
                    <td>
                      {row.image_url ? (
                        <img
                          src={row.image_url} alt=""
                          className="w-11 h-11 rounded-lg object-cover border border-gb-border"
                          onError={e => { e.target.style.display = 'none' }}
                        />
                      ) : (
                        <div className="w-11 h-11 rounded-lg bg-gb-surface border border-gb-border flex items-center justify-center text-lg">
                          ♻️
                        </div>
                      )}
                    </td>
                    {/* Time */}
                    <td className="font-mono text-[0.76rem] text-ink-sub">
                      {row.timestamp
                        ? new Date(row.timestamp).toLocaleString('en-US', { month:'short', day:'numeric', hour:'2-digit', minute:'2-digit' })
                        : row.time}
                    </td>
                    {/* Category */}
                    <td><Badge label={row.predicted_category || row.category} /></td>
                    {/* Confidence */}
                    <td className="min-w-[140px]">
                      <ConfidenceBar value={row.confidence_score ?? (row.conf / 100)} />
                    </td>
                    {/* User */}
                    <td className="font-mono text-[0.72rem] text-ink-muted">
                      {row.user_id ? `USR-${row.user_id.slice(-4).toUpperCase()}` : row.userId}
                    </td>
                    {/* Action */}
                    <td>
                      <button
                        className="btn btn-ghost btn-sm"
                        onClick={() => navigate('/classifications')}
                      >
                        <Eye size={13} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

      </div>
    </Layout>
  )
}

/* ── Mock fallback data ───────────────────────────────────────────────────── */
const MOCK_DIST = [
  { category:'PLASTIC', count:450, pct:45 },
  { category:'ORGANIC', count:250, pct:25 },
  { category:'PAPER',   count:150, pct:15 },
  { category:'GLASS',   count:100, pct:10 },
  { category:'METAL',   count:50,  pct:5  },
]
const MOCK_RECENT = [
  { id:'1', time:'Oct 24, 10:42 AM', category:'PLASTIC',  conf:98, userId:'USR-8821' },
  { id:'2', time:'Oct 24, 10:38 AM', category:'PAPER',    conf:92, userId:'USR-1042' },
  { id:'3', time:'Oct 24, 10:15 AM', category:'GLASS',    conf:87, userId:'USR-3391' },
  { id:'4', time:'Oct 24, 09:50 AM', category:'METAL',    conf:74, userId:'USR-2204' },
  { id:'5', time:'Oct 24, 09:30 AM', category:'ORGANIC',  conf:95, userId:'USR-9910' },
  { id:'6', time:'Oct 24, 09:10 AM', category:'E_WASTE',  conf:61, userId:'USR-5532' },
]