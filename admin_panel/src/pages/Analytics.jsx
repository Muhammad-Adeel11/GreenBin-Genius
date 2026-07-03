import React, { useState, useCallback, useEffect } from 'react'
import {
  LineChart, Line, XAxis, YAxis, Tooltip,
  ResponsiveContainer, CartesianGrid, Legend, BarChart, Bar, Cell
} from 'recharts'
import {
  SlidersHorizontal, Download, Plus, Clock,
  FileText, Sheet, Code2, Activity, Users, Target
} from 'lucide-react'
import Layout from '../components/layout/Layout'
import { analyticsApi } from '../api'

const WASTE_CATS = ['Plastic', 'Organic', 'Metal', 'Paper', 'E-Waste', 'Glass']
const BAR_COLORS = ['#22c55e', '#3b82f6', '#f59e0b', '#ec4899', '#a855f7', '#ef4444']

export default function Analytics() {
  const [startDate,   setStartDate]   = useState('')
  const [endDate,     setEndDate]     = useState('')
  const [selCats,     setSelCats]     = useState(['Plastic', 'Organic', 'Metal', 'Paper', 'E-Waste', 'Glass'])
  const [rawImages,   setRawImages]   = useState(false)
  const [loading,     setLoading]     = useState(true)

  const [kpis,        setKpis]        = useState({ total_classifications: 0, active_users: 0, accuracy: 94.5 })
  const [trendData,   setTrendData]   = useState([])
  const [catDist,     setCatDist]     = useState([])

  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const res = await analyticsApi.getDashboard()
      const d = res.data
      setKpis({
        total_classifications: d.kpis?.total_classifications ?? 0,
        active_users:          d.kpis?.active_users ?? 0,
        accuracy:              d.model_performance?.accuracy_from_feedback ?? 94.5
      })
      setTrendData(d.daily_trend || [])
      setCatDist(d.category_distribution || [])
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadData()
  }, [loadData])

  const toggleCat = (c) =>
    setSelCats(p => p.includes(c) ? p.filter(x=>x!==c) : [...p,c])

  const handleExport = async (fmt) => {
    try {
      const res = await analyticsApi.exportClassifications({
        start_date: startDate || undefined,
        end_date:   endDate   || undefined,
        categories: selCats.map(c => c.toUpperCase()).join(','),
        format:     fmt.toLowerCase()
      })
      const ext  = fmt === 'CSV' ? 'csv' : fmt === 'XLSX' ? 'xlsx' : 'pdf'
      const url  = URL.createObjectURL(new Blob([res.data]))
      Object.assign(document.createElement('a'), { href:url, download:`report_${Date.now()}.${ext}` }).click()
      URL.revokeObjectURL(url)
    } catch (e) { console.error(e) }
  }

  const totalCatItems = catDist.reduce((s, c) => s + c.count, 0)

  return (
    <Layout
      title="Sustainability Reports & Analytics"
      subtitle="Track real-time waste classification metrics and generate environmental reports."
    >
      {/* Top action bar */}
      <div className="flex items-center justify-between mb-6">
        <div />
        <div className="flex items-center gap-3">
          <button onClick={loadData} className="btn btn-ghost gap-2 text-[0.82rem]">
            <Clock size={14}/> Refresh Data
          </button>
        </div>
      </div>

      <div className="flex gap-5 items-start">

        {/* ── Left: config panel ─────────────────────────────────── */}
        <div className="w-64 flex-shrink-0 space-y-4">

          {/* Report Configuration */}
          <div className="card p-5 space-y-4">
            <h3 className="flex items-center gap-2 text-[0.95rem] font-bold text-ink">
              <SlidersHorizontal size={16} className="text-eco"/> Report Configuration
            </h3>

            {/* Date range */}
            <div>
              <p className="text-[0.72rem] font-semibold text-ink-sub mb-2">Date Range</p>
              <div className="flex items-center gap-2">
                <input type="date" value={startDate} onChange={e=>setStartDate(e.target.value)}
                  className="input text-[0.76rem] py-1.5 flex-1"/>
                <span className="text-ink-muted text-sm">–</span>
                <input type="date" value={endDate} onChange={e=>setEndDate(e.target.value)}
                  className="input text-[0.76rem] py-1.5 flex-1"/>
              </div>
            </div>

            {/* Waste categories */}
            <div>
              <p className="text-[0.72rem] font-semibold text-ink-sub mb-2">Waste Categories</p>
              <div className="grid grid-cols-2 gap-2">
                {WASTE_CATS.map(c => (
                  <label key={c} className="flex items-center gap-2 cursor-pointer group">
                    <div
                      onClick={() => toggleCat(c)}
                      className={`w-4 h-4 rounded border flex items-center justify-center transition-all cursor-pointer flex-shrink-0
                        ${selCats.includes(c)
                          ? 'bg-eco border-eco'
                          : 'bg-gb-surface border-gb-border group-hover:border-eco-border'}`}
                    >
                      {selCats.includes(c) && (
                        <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
                          <path d="M2 5l2.5 2.5L8 3" stroke="#090f09" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
                        </svg>
                      )}
                    </div>
                    <span className="text-[0.76rem] text-ink-sub">{c}</span>
                  </label>
                ))}
              </div>
            </div>

            <button onClick={loadData} className="btn btn-primary w-full justify-center py-2.5 text-[0.82rem]">
              Update Preview
            </button>
          </div>

          {/* Export Options */}
          <div className="card p-5 space-y-3">
            <h3 className="flex items-center gap-2 text-[0.9rem] font-bold text-ink">
              <Download size={15} className="text-eco"/> Export Options
            </h3>
            {/* Raw images toggle */}
            <label className="flex items-center justify-between cursor-pointer">
              <span className="text-[0.78rem] text-ink-sub">Include Raw Images</span>
              <div
                onClick={() => setRawImages(p=>!p)}
                className={`w-10 h-5 rounded-full transition-all cursor-pointer relative ${rawImages ? 'bg-eco' : 'bg-gb-surface border border-gb-border'}`}
              >
                <div className={`absolute top-0.5 w-4 h-4 rounded-full bg-white shadow transition-all duration-200 ${rawImages ? 'left-5' : 'left-0.5'}`}/>
              </div>
            </label>
            {/* Format buttons */}
            <div className="grid grid-cols-3 gap-2">
              {[
                { fmt:'PDF',  icon:FileText, color:'text-red-400',   bg:'bg-red-500/10 border-red-500/20' },
                { fmt:'XLSX', icon:Sheet,    color:'text-eco',       bg:'bg-eco-muted border-eco-border' },
                { fmt:'CSV',  icon:Code2,    color:'text-sky-400',   bg:'bg-sky-500/10 border-sky-500/20' },
              ].map(({fmt,icon:Icon,color,bg}) => (
                <button key={fmt} onClick={() => handleExport(fmt)}
                  className={`flex flex-col items-center gap-1.5 py-3 rounded-xl border text-[0.72rem] font-bold cursor-pointer transition-all hover:scale-105 ${bg} ${color}`}>
                  <Icon size={18}/>
                  {fmt}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* ── Right: charts + metrics ────────────────────────────── */}
        <div className="flex-1 min-w-0 space-y-4">

          {/* KPI cards */}
          <div className="grid grid-cols-3 gap-4">
            {[
              { label:'Total Waste Scanned', value: kpis.total_classifications.toLocaleString(), sub:'Item classifications total', color:'text-eco', bg:'bg-eco/5 border-eco/20', icon: Activity },
              { label:'Active Users', value: kpis.active_users.toLocaleString(), sub:'Engaged app accounts', color:'text-sky-400', bg:'bg-sky-500/5 border-sky-500/20', icon: Users },
              { label:'Verified Model Accuracy', value: `${kpis.accuracy}%`, sub:'Based on user correction feedback', color:'text-orange-400', bg:'bg-orange-500/5 border-orange-500/20', icon: Target },
            ].map(({label,value,sub,color,bg,icon:Icon}) => (
              <div key={label} className={`card p-4 border flex items-center justify-between ${bg}`}>
                <div>
                  <p className={`text-[0.62rem] font-bold tracking-[0.1em] uppercase ${color} mb-2`}>{label}</p>
                  <span className="text-[1.8rem] font-bold text-ink leading-none">{value}</span>
                  <p className="text-[0.72rem] text-ink-muted mt-1.5">{sub}</p>
                </div>
                <Icon size={28} className={`${color} opacity-80`} />
              </div>
            ))}
          </div>

          {/* Charts row */}
          <div className="grid grid-cols-2 gap-4">
            {/* Daily Classification Activity */}
            <div className="card p-4">
              <div className="flex items-center justify-between mb-4">
                <h3 className="section-title">Daily Classification Trend</h3>
                <span className="text-[0.68rem] text-ink-muted bg-gb-surface border border-gb-border px-2 py-1 rounded-md">Last 30 Days</span>
              </div>
              <ResponsiveContainer width="100%" height={180}>
                <LineChart data={trendData} margin={{top:4,right:4,bottom:0,left:-20}}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(34,197,94,0.07)"/>
                  <XAxis dataKey="date" tick={{fill:'#4a6e4a',fontSize:9}} axisLine={false} tickLine={false}/>
                  <YAxis tick={{fill:'#4a6e4a',fontSize:9}} axisLine={false} tickLine={false}/>
                  <Tooltip contentStyle={{background:'#111f11',border:'1px solid rgba(34,197,94,0.15)',borderRadius:8,fontSize:11}}/>
                  <Line type="monotone" dataKey="count" name="Classifications" stroke="#22c55e" strokeWidth={2.5} dot={false}
                    activeDot={{r:4,fill:'#22c55e',strokeWidth:0}}/>
                </LineChart>
              </ResponsiveContainer>
            </div>

            {/* Category Share */}
            <div className="card p-4">
              <div className="flex items-center justify-between mb-4">
                <h3 className="section-title">Category Distribution</h3>
                <span className="text-[0.68rem] text-ink-muted bg-gb-surface border border-gb-border px-2 py-1 rounded-md">By Item Volume</span>
              </div>
              <ResponsiveContainer width="100%" height={180}>
                <BarChart data={catDist} margin={{top:4,right:4,bottom:0,left:-20}}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(34,197,94,0.07)"/>
                  <XAxis dataKey="category" tick={{fill:'#4a6e4a',fontSize:9}} axisLine={false} tickLine={false}/>
                  <YAxis tick={{fill:'#4a6e4a',fontSize:9}} axisLine={false} tickLine={false}/>
                  <Tooltip contentStyle={{background:'#111f11',border:'1px solid rgba(34,197,94,0.15)',borderRadius:8,fontSize:11}}/>
                  <Bar dataKey="count" fill="#22c55e" radius={[4, 4, 0, 0]}>
                    {catDist.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={BAR_COLORS[index % BAR_COLORS.length]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Detailed Category Metrics table */}
          <div className="card p-4">
            <div className="flex items-center justify-between mb-4">
              <h3 className="section-title">Waste Categories Breakdown</h3>
            </div>
            <div className="overflow-x-auto">
              <table className="tbl">
                <thead>
                  <tr>
                    <th>Category</th>
                    <th>Total Items Classified</th>
                    <th>Recycling Category Type</th>
                    <th>Platform Share (%)</th>
                  </tr>
                </thead>
                <tbody>
                  {catDist.map((c, i) => {
                    const isRecyclable = ['PLASTIC', 'PAPER', 'GLASS', 'METAL'].includes(c.category)
                    const pct = totalCatItems ? Math.round((c.count / totalCatItems) * 100) : 0
                    return (
                      <tr key={c.category}>
                        <td className="font-semibold">{c.category}</td>
                        <td>{c.count.toLocaleString()}</td>
                        <td>
                          <span className={`badge text-[0.7rem] ${isRecyclable ? 'text-eco bg-eco-muted' : 'text-yellow-400 bg-yellow-500/10'}`}>
                            {isRecyclable ? 'Recyclable' : 'Organic / Other'}
                          </span>
                        </td>
                        <td>
                          <div className="flex items-center gap-2">
                            <div className="flex-1 h-1.5 bg-gb-surface rounded-full overflow-hidden max-w-[80px]">
                              <div className="h-full bg-eco rounded-full" style={{width:`${pct}%`}}/>
                            </div>
                            <span className="text-[0.78rem] font-semibold text-eco">{pct}%</span>
                          </div>
                        </td>
                      </tr>
                    )
                  })}
                  {catDist.length === 0 && (
                    <tr>
                      <td colSpan="4" className="text-center py-4 text-ink-muted text-sm">No classifications registered yet.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  )
}