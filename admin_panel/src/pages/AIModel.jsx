import React, { useEffect, useState, useCallback } from 'react'
import {
  LineChart, Line, XAxis, YAxis, Tooltip,
  ResponsiveContainer, CartesianGrid, Legend,
} from 'recharts'
import {
  RefreshCw, RotateCcw, Activity, Zap, AlertTriangle,
  Database, CheckCircle2, ChevronDown,
} from 'lucide-react'
import Layout from '../components/layout/Layout'
import { ConfidenceBar, Spinner } from '../components/ui/index.jsx'
import { analyticsApi, adminApi } from '../api'

/* ── Epoch training curve ─────────────────────────────────────────────────── */
const EPOCH_DATA = Array.from({ length: 51 }, (_, i) => ({
  epoch:    i,
  accuracy: Math.min(94, 50 + (i / 50) * 44 + Math.sin(i * 0.4) * 1.5),
  loss:     Math.max(6,  50 - (i / 50) * 44 + Math.sin(i * 0.3) * 1.2),
}))

/* ── Confusion matrix data ────────────────────────────────────────────────── */
const CONF_MATRIX = [
  [{ v:'TP', hi:true }, { v:'3',  hi:false }, { v:'1',  hi:false }, { v:'0',  hi:false }],
  [{ v:'4',  hi:false }, { v:'TP', hi:true  }, { v:'12', hi:false }, { v:'2',  hi:false }],
  [{ v:'1',  hi:false }, { v:'8',  hi:false }, { v:'TP', hi:true  }, { v:'5',  hi:false }],
  [{ v:'0',  hi:false }, { v:'1',  hi:false }, { v:'4',  hi:false }, { v:'TP', hi:true  }],
]

const ALL_CATS = ['PLASTIC','PAPER','METAL','GLASS','ORGANIC','E_WASTE','HAZARDOUS','TEXTILE','OTHER']

export default function AIModel() {
  const [modelInfo,   setModelInfo]   = useState(null)
  const [lowConf,     setLowConf]     = useState([])
  const [loading,     setLoading]     = useState(true)
  const [reloading,   setReloading]   = useState(false)
  const [page,        setPage]        = useState(0)
  const [corrections, setCorrections] = useState({})

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const [infoRes, lowRes] = await Promise.all([
        adminApi.getModelStatus(),
        analyticsApi.getLowConfidence({ threshold: 0.80, limit: 10 }),
      ])
      setModelInfo(infoRes.data)
      setLowConf(Array.isArray(lowRes.data) ? lowRes.data : MOCK_LOW_CONF)
    } catch { setModelInfo(MOCK_INFO); setLowConf(MOCK_LOW_CONF) }
    finally { setLoading(false) }
  }, [])

  useEffect(() => { load() }, [load])

  const handleReload = async () => {
    setReloading(true)
    try { await adminApi.reloadModels(); load() }
    catch(e) { console.error(e) }
    finally { setReloading(false) }
  }

  const setCorrection = (id, val) => setCorrections(p => ({ ...p, [id]: val }))

  const displayed = (lowConf.length ? lowConf : MOCK_LOW_CONF).slice(page * 5, page * 5 + 5)

  return (
    <Layout
      title="AI Model Performance"
      subtitle={`Monitoring CNN (InceptionV3) and YOLOv8 model metrics. Current deployment version: ${modelInfo?.version || 'v2.4.1'}`}
    >
      {/* ── Action buttons ─────────────────────────────────────────── */}
      <div className="flex items-center justify-between mb-6">
        <div/>
        <div className="flex items-center gap-3">
          <button className="btn btn-ghost gap-2 text-[0.82rem]">
            <RefreshCw size={13}/> Update Instructions
          </button>
          <button onClick={handleReload} disabled={reloading}
            className="btn btn-primary gap-2 text-[0.82rem] disabled:opacity-60">
            <RotateCcw size={13} className={reloading ? 'animate-spin-slow' : ''}/>
            {reloading ? 'Retraining…' : 'Retrain Model'}
          </button>
        </div>
      </div>

      {/* ── KPI row ────────────────────────────────────────────────── */}
      <div className="grid grid-cols-4 gap-4 mb-5">
        {[
          { label:'MAP @ 0.5',       value:'94.2%', sub:'Mean Average Precision', trend:'+1.2%', icon:Activity,    color:'text-eco',        bg:'bg-eco-muted border-eco-border' },
          { label:'INFERENCE SPEED', value:'45ms',  sub:'Avg per image (T4 GPU)', trend:'−5ms',  icon:Zap,         color:'text-sky-400',    bg:'bg-sky-500/10 border-sky-500/20' },
          { label:'DATA DRIFT',      value:'Low',   sub:'Distribution shift check', extra:'PSI: 0.08', icon:AlertTriangle, color:'text-yellow-400', bg:'bg-yellow-500/10 border-yellow-500/20' },
          { label:'TRAINING SET',    value:'15.4k', sub:'Labeled images total', trend:'+450 New', icon:Database,   color:'text-purple-400', bg:'bg-purple-500/10 border-purple-500/20' },
        ].map(({ label, value, sub, trend, extra, icon:Icon, color, bg }) => (
          <div key={label} className="card p-4">
            <div className="flex items-start justify-between mb-2">
              <p className="text-[0.65rem] font-bold tracking-[0.1em] uppercase text-ink-muted">{label}</p>
              <div className={`w-8 h-8 rounded-lg border flex items-center justify-center ${bg}`}>
                <Icon size={15} className={color}/>
              </div>
            </div>
            <p className={`text-[1.8rem] font-bold leading-none tracking-tight mb-1 ${color}`}>{value}</p>
            {trend && <p className={`text-[0.7rem] font-bold ${trend.startsWith('+') ? 'text-eco' : trend.startsWith('−') ? 'text-red-400' : 'text-ink-muted'}`}>{trend}</p>}
            {extra && <p className="text-[0.68rem] text-ink-muted">{extra}</p>}
            <p className="text-[0.68rem] text-ink-muted mt-0.5">{sub}</p>
          </div>
        ))}
      </div>

      {/* ── Charts row ─────────────────────────────────────────────── */}
      <div className="flex gap-4 mb-5">
        {/* Loss & Accuracy chart */}
        <div className="card flex-1 p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="section-title">Loss &amp; Accuracy (Last 50 Epochs)</h3>
            <div className="flex items-center gap-3 text-[0.72rem]">
              <span className="flex items-center gap-1.5"><span className="w-2 h-2 rounded-full bg-eco inline-block"/>Accuracy</span>
              <span className="flex items-center gap-1.5"><span className="w-2 h-2 rounded-full bg-gb-border inline-block"/>Loss</span>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <LineChart data={EPOCH_DATA} margin={{ top:4, right:4, bottom:0, left:-20 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(34,197,94,0.06)"/>
              <XAxis dataKey="epoch" tickFormatter={v => v % 10 === 0 ? `Epoch ${v}` : ''} tick={{fill:'#4a6e4a',fontSize:10}} axisLine={false} tickLine={false}/>
              <YAxis tick={{fill:'#4a6e4a',fontSize:10}} axisLine={false} tickLine={false}/>
              <Tooltip contentStyle={{background:'#111f11',border:'1px solid rgba(34,197,94,0.15)',borderRadius:8,fontSize:11}}
                formatter={(v,n) => [v.toFixed(1)+'%', n==='accuracy'?'Accuracy':'Loss']}/>
              <Line type="monotone" dataKey="accuracy" stroke="#22c55e" strokeWidth={2.5} dot={false} activeDot={{r:4,fill:'#22c55e',strokeWidth:0}}/>
              <Line type="monotone" dataKey="loss" stroke="#4a6e4a" strokeWidth={1.5} strokeDasharray="4 3" dot={false} activeDot={{r:3}}/>
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Confusion Matrix */}
        <div className="card w-72 flex-shrink-0 p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="section-title">Confusion Matrix</h3>
            <button className="text-[0.72rem] text-eco font-semibold bg-transparent border-none cursor-pointer hover:underline">View Full</button>
          </div>
          <div className="grid grid-cols-4 gap-1">
            {CONF_MATRIX.map((row, ri) =>
              row.map((cell, ci) => (
                <div key={`${ri}-${ci}`}
                  className={`h-14 rounded-lg flex items-center justify-center text-[0.82rem] font-bold transition-all
                    ${cell.hi
                      ? 'bg-eco text-ink-inverse shadow-glow'
                      : parseInt(cell.v) > 5 ? 'bg-eco/30 text-eco'
                      : 'bg-gb-surface text-ink-muted'}`}>
                  {cell.v}
                </div>
              ))
            )}
          </div>
          <div className="mt-3 pt-3 border-t border-gb-border">
            <p className="text-[0.65rem] text-ink-muted uppercase tracking-wider mb-2">Predicted Class</p>
            <div className="flex gap-3">
              <span className="flex items-center gap-1.5 text-[0.7rem] text-eco"><span className="w-2 h-2 rounded-full bg-eco"/>High Match</span>
              <span className="flex items-center gap-1.5 text-[0.7rem] text-ink-muted"><span className="w-2 h-2 rounded-full bg-eco/30"/>Error</span>
            </div>
          </div>
        </div>
      </div>

      {/* ── Uncertain Classifications table ────────────────────────── */}
      <div className="card p-5">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="section-title">Uncertain Classifications</h3>
            <p className="text-[0.75rem] text-ink-muted mt-0.5">Items with confidence score &lt; 60% requiring human labeling</p>
          </div>
          <div className="flex items-center gap-2.5">
            <span className="text-[0.75rem] text-ink-muted">{lowConf.length} pending items</span>
            <button className="btn btn-ghost btn-sm">Select All</button>
            <button className="btn btn-primary btn-sm">Submit Labels</button>
          </div>
        </div>

        <table className="tbl">
          <thead>
            <tr>
              <th>Image</th>
              <th>Timestamp</th>
              <th>AI Prediction</th>
              <th>Confidence</th>
              <th>Correct Label</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {displayed.map((item, i) => {
              const pct   = Math.round((item.confidence_score||0.45) * 100)
              const color = pct >= 60 ? 'text-yellow-400' : 'text-red-400'
              const sel   = corrections[item.id] || item.user_feedback || ''
              return (
                <tr key={item.id||i}>
                  <td>
                    <div className="w-12 h-12 rounded-lg bg-gb-surface border border-gb-border overflow-hidden flex items-center justify-center text-xl">
                      {item.image_url
                        ? <img src={item.image_url} alt="" className="w-full h-full object-cover" onError={e=>{e.target.style.display='none'}}/>
                        : '♻️'}
                    </div>
                  </td>
                  <td className="text-[0.78rem] text-ink-sub">
                    {item.timestamp
                      ? new Date(item.timestamp).toLocaleString('en-US',{month:'short',day:'numeric',hour:'2-digit',minute:'2-digit'})
                      : `Today, ${10+i}:${String(42-i*5).padStart(2,'0')} ${i<2?'AM':'PM'}`}
                  </td>
                  <td>
                    <span className={`text-[0.82rem] font-bold ${color}`}>
                      {item.predicted_category || MOCK_PREDS[i % MOCK_PREDS.length]}?
                    </span>
                  </td>
                  <td className="min-w-[120px]">
                    <ConfidenceBar value={item.confidence_score || 0.45}/>
                  </td>
                  <td>
                    <div className="relative">
                      <select value={sel} onChange={e => setCorrection(item.id||i, e.target.value)}
                        className="input text-[0.76rem] py-1.5 pr-7 appearance-none bg-gb-surface w-full">
                        <option value="">Select label…</option>
                        {ALL_CATS.map(c => <option key={c}>{c.charAt(0)+c.slice(1).toLowerCase()}</option>)}
                        <option>Contaminated (Trash)</option>
                      </select>
                      <ChevronDown size={12} className="absolute right-2 top-1/2 -translate-y-1/2 text-ink-muted pointer-events-none"/>
                    </div>
                  </td>
                  <td>
                    <button
                      onClick={() => console.log('Submit', item.id, corrections[item.id])}
                      className={`w-7 h-7 rounded-full flex items-center justify-center border transition-all cursor-pointer
                        ${sel ? 'bg-eco border-eco text-ink-inverse' : 'bg-gb-surface border-gb-border text-ink-muted hover:border-eco-border'}`}>
                      <CheckCircle2 size={14}/>
                    </button>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>

        <button className="w-full mt-4 py-3 text-eco text-[0.82rem] font-semibold hover:bg-eco-muted rounded-xl transition-all cursor-pointer border border-dashed border-eco/30 bg-transparent">
          Load more items
        </button>
      </div>
    </Layout>
  )
}

const MOCK_INFO = { cnn_loaded: true, yolo_loaded: true, fallback_enabled: true, version: 'v2.4.1' }
const MOCK_PREDS = ['Glass','Paper','Plastic','Metal','Organic']
const MOCK_LOW_CONF = [
  { id:'1', predicted_category:'GLASS',   confidence_score:0.45, timestamp:new Date().toISOString() },
  { id:'2', predicted_category:'PAPER',   confidence_score:0.32, timestamp:new Date(Date.now()-3600000).toISOString() },
  { id:'3', predicted_category:'PLASTIC', confidence_score:0.58, timestamp:new Date(Date.now()-7200000).toISOString() },
  { id:'4', predicted_category:'METAL',   confidence_score:0.41, timestamp:new Date(Date.now()-10800000).toISOString() },
  { id:'5', predicted_category:'ORGANIC', confidence_score:0.53, timestamp:new Date(Date.now()-14400000).toISOString() },
]