import React, { useState, useCallback } from 'react'
import {
  LineChart, Line, XAxis, YAxis, Tooltip,
  ResponsiveContainer, CartesianGrid, Legend,
} from 'recharts'
import {
  SlidersHorizontal, Download, Plus, Clock,
  FileText, Sheet, Code2, TrendingUp, Leaf, Recycle,
} from 'lucide-react'
import Layout from '../components/layout/Layout'
import { analyticsApi } from '../api'

/* ── Mock data ──────────────────────────────────────────────────────────── */
const RECYCLING_CHART = [
  { q:'Q1', prev:42, curr:51 },
  { q:'Q2', prev:55, curr:63 },
  { q:'Q3', prev:60, curr:72 },
  { q:'Q4', prev:68, curr:80 },
]
const IMPACT_ROWS = [
  { zone:'North',  waste:4500, recycled:75, co2:850,  status:'Optimal'  },
  { zone:'South',  waste:3200, recycled:62, co2:610,  status:'Good'     },
  { zone:'East',   waste:2800, recycled:58, co2:520,  status:'Moderate' },
  { zone:'West',   waste:5100, recycled:71, co2:960,  status:'Optimal'  },
  { zone:'Central',waste:1900, recycled:45, co2:380,  status:'Low'      },
]
const STATUS_STYLE = {
  Optimal:  'text-eco bg-eco-muted',
  Good:     'text-sky-400 bg-sky-500/10',
  Moderate: 'text-yellow-400 bg-yellow-500/10',
  Low:      'text-red-400 bg-red-500/10',
}

const WASTE_CATS = ['Plastic','Organic','Metal','Paper','E-Waste','Glass']

export default function Analytics() {
  const [startDate,   setStartDate]   = useState('')
  const [endDate,     setEndDate]     = useState('')
  const [selCats,     setSelCats]     = useState(['Plastic','Organic'])
  const [region,      setRegion]      = useState('All Regions')
  const [rawImages,   setRawImages]   = useState(false)
  const [loading,     setLoading]     = useState(false)

  const toggleCat = (c) =>
    setSelCats(p => p.includes(c) ? p.filter(x=>x!==c) : [...p,c])

  const handleExport = async (fmt) => {
    try {
      const res = await analyticsApi.exportClassifications({
        start_date: startDate || undefined,
        end_date:   endDate   || undefined,
      })
      const ext  = fmt === 'CSV' ? 'csv' : fmt === 'XLSX' ? 'xlsx' : 'pdf'
      const url  = URL.createObjectURL(new Blob([res.data]))
      Object.assign(document.createElement('a'), { href:url, download:`report_${Date.now()}.${ext}` }).click()
      URL.revokeObjectURL(url)
    } catch (e) { console.error(e) }
  }

  return (
    <Layout
      title="Sustainability Reports"
      subtitle="Generate insights and export data for environmental impact analysis."
    >
      {/* Top action bar */}
      <div className="flex items-center justify-between mb-6">
        <div />
        <div className="flex items-center gap-3">
          <button className="btn btn-ghost gap-2 text-[0.82rem]">
            <Clock size={14}/> Recent Exports
          </button>
          <button className="btn btn-primary gap-2 text-[0.82rem]">
            <Plus size={14}/> New Report
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

            {/* Region */}
            <div>
              <p className="text-[0.72rem] font-semibold text-ink-sub mb-2">Region / Zone</p>
              <select value={region} onChange={e=>setRegion(e.target.value)}
                className="input text-[0.76rem] py-1.5 bg-gb-input">
                {['All Regions','North','South','East','West','Central'].map(r=>(
                  <option key={r}>{r}</option>
                ))}
              </select>
            </div>

            <button className="btn btn-primary w-full justify-center py-2.5 text-[0.82rem]">
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
              { label:'CO2 EMISSIONS SAVED', value:'1,245', unit:'kg', sub:'+12% vs last month', color:'text-eco',       bg:'bg-eco/5 border-eco/20' },
              { label:'TREES EQUIVALENT',    value:'45',    unit:'trees', sub:'Est. impact',     color:'text-sky-400',   bg:'bg-sky-500/5 border-sky-500/20' },
              { label:'RECYCLING RATE',      value:'68.2',  unit:'%',  sub:'↑ Target: 70%',      color:'text-orange-400',bg:'bg-orange-500/5 border-orange-500/20' },
            ].map(({label,value,unit,sub,color,bg}) => (
              <div key={label} className={`card p-4 border ${bg}`}>
                <p className={`text-[0.62rem] font-bold tracking-[0.1em] uppercase ${color} mb-2`}>{label}</p>
                <div className="flex items-baseline gap-1.5">
                  <span className="text-[2rem] font-bold text-ink leading-none">{value}</span>
                  <span className={`text-[0.85rem] font-semibold ${color}`}>{unit}</span>
                </div>
                <p className="text-[0.72rem] text-ink-muted mt-1.5">{sub}</p>
              </div>
            ))}
          </div>

          {/* Charts row */}
          <div className="grid grid-cols-2 gap-4">
            {/* Recycling Rates YoY */}
            <div className="card p-4">
              <div className="flex items-center justify-between mb-4">
                <h3 className="section-title">Recycling Rates (YoY)</h3>
                <span className="text-[0.68rem] text-ink-muted bg-gb-surface border border-gb-border px-2 py-1 rounded-md">2023 vs 2022</span>
              </div>
              <ResponsiveContainer width="100%" height={180}>
                <LineChart data={RECYCLING_CHART} margin={{top:4,right:4,bottom:0,left:-20}}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(34,197,94,0.07)"/>
                  <XAxis dataKey="q" tick={{fill:'#4a6e4a',fontSize:11}} axisLine={false} tickLine={false}/>
                  <YAxis tick={{fill:'#4a6e4a',fontSize:11}} axisLine={false} tickLine={false}/>
                  <Tooltip contentStyle={{background:'#111f11',border:'1px solid rgba(34,197,94,0.15)',borderRadius:8,fontSize:11}}/>
                  <Legend wrapperStyle={{fontSize:11, paddingTop:8}}
                    formatter={v => <span style={{color:'#7aaa7a'}}>{v==='curr'?'Current Year':'Previous Year'}</span>}/>
                  <Line type="monotone" dataKey="prev" name="prev" stroke="#4a6e4a" strokeWidth={2} dot={false} strokeDasharray="5 3"/>
                  <Line type="monotone" dataKey="curr" name="curr" stroke="#22c55e" strokeWidth={2.5} dot={false}
                    activeDot={{r:4,fill:'#22c55e',strokeWidth:0}}/>
                </LineChart>
              </ResponsiveContainer>
            </div>

            {/* Disposal Activity Heatmap */}
            <div className="card p-4">
              <div className="flex items-center justify-between mb-3">
                <h3 className="section-title">Disposal Activity Heatmap</h3>
                <button className="text-[0.72rem] text-eco font-semibold bg-transparent border-none cursor-pointer hover:underline">View Full Map</button>
              </div>
              {/* Heatmap placeholder — radial gradient approximation */}
              <div className="relative h-44 rounded-xl overflow-hidden bg-gb-surface border border-gb-border">
                <div className="absolute inset-0" style={{
                  background: `
                    radial-gradient(ellipse 40% 35% at 55% 45%, rgba(239,68,68,0.55) 0%, rgba(245,158,11,0.35) 40%, rgba(34,197,94,0.1) 70%, transparent 100%),
                    radial-gradient(ellipse 25% 20% at 30% 65%, rgba(245,158,11,0.3) 0%, transparent 70%)
                  `
                }}/>
                <div className="absolute bottom-2 left-2 bg-gb-card/90 border border-gb-border rounded-lg px-2.5 py-1.5 text-[0.7rem] text-ink-sub font-medium">
                  High Activity: North Zone
                </div>
              </div>
              {/* Heatmap legend */}
              <div className="flex items-center justify-between mt-2 text-[0.66rem] text-ink-muted">
                <span>Low Activity</span>
                <div className="flex-1 mx-3 h-1.5 rounded-full" style={{background:'linear-gradient(90deg,#22c55e,#f59e0b,#ef4444)'}}/>
                <span>Critical Load</span>
              </div>
            </div>
          </div>

          {/* Detailed Impact Metrics table */}
          <div className="card p-4">
            <div className="flex items-center justify-between mb-4">
              <h3 className="section-title">Detailed Impact Metrics</h3>
              <button className="text-ink-muted hover:text-eco transition-colors bg-transparent border-none cursor-pointer">
                <svg width="18" height="4" viewBox="0 0 18 4" fill="currentColor">
                  <circle cx="2" cy="2" r="2"/><circle cx="9" cy="2" r="2"/><circle cx="16" cy="2" r="2"/>
                </svg>
              </button>
            </div>
            <div className="overflow-x-auto">
              <table className="tbl">
                <thead>
                  <tr>
                    <th>Zone / Region</th>
                    <th>Waste Collected (kg)</th>
                    <th>Recycled (%)</th>
                    <th>CO2 Saved</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {IMPACT_ROWS.map(r => (
                    <tr key={r.zone}>
                      <td className="font-semibold">{r.zone}</td>
                      <td>{r.waste.toLocaleString()}</td>
                      <td>
                        <div className="flex items-center gap-2">
                          <div className="flex-1 h-1.5 bg-gb-surface rounded-full overflow-hidden max-w-[80px]">
                            <div className="h-full bg-eco rounded-full" style={{width:`${r.recycled}%`}}/>
                          </div>
                          <span className="text-[0.78rem] font-semibold text-eco">{r.recycled}%</span>
                        </div>
                      </td>
                      <td className="font-mono text-[0.78rem]">{r.co2} kg</td>
                      <td>
                        <span className={`badge text-[0.7rem] ${STATUS_STYLE[r.status]||'text-ink-sub bg-gb-surface'}`}>
                          {r.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  )
}