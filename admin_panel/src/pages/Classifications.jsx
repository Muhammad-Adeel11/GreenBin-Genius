import React, { useEffect, useState, useCallback } from 'react'
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from 'recharts'
import {
  Filter, AlertTriangle, Calendar, Pencil,
  Download, Clock, CheckCircle2, Sparkles, RotateCcw,
} from 'lucide-react'
import Layout from '../components/layout/Layout'
import { Modal, Spinner, EmptyState } from '../components/ui/index.jsx'
import { classificationApi, analyticsApi } from '../api'

const CAT_COLORS   = { PLASTIC:'#22c55e',PAPER:'#f59e0b',METAL:'#94a3b8',GLASS:'#38bdf8',ORGANIC:'#a3e635',E_WASTE:'#f97316',HAZARDOUS:'#ef4444',TEXTILE:'#c084fc',OTHER:'#64748b',UNKNOWN:'#475569' }
const DONUT_COLORS = ['#22c55e','#f59e0b','#94a3b8','#475569']
const LABEL_MAP    = { PLASTIC:'Plastic Bottle',PAPER:'Cardboard Box',METAL:'Aluminium Can',GLASS:'Glass Jar',ORGANIC:'Food Waste',E_WASTE:'Electronic Device',HAZARDOUS:'Chemical Container',TEXTILE:'Clothing Item',OTHER:'Unknown Object',UNKNOWN:'Unknown Object' }
const ALL_CATS     = ['PLASTIC','PAPER','METAL','GLASS','ORGANIC','E_WASTE','HAZARDOUS','TEXTILE','OTHER']

function confBadgeClass(score) {
  const p = Math.round((score ?? 0) * 100)
  if (p >= 80) return 'bg-eco text-ink-inverse'
  if (p >= 60) return 'bg-yellow-400 text-gb-base'
  return 'bg-red-500 text-white'
}

function timeAgo(ts) {
  if (!ts) return 'Unknown'
  const diff = Date.now() - new Date(ts).getTime()
  const m = Math.floor(diff / 60000)
  if (m < 1)  return 'Just now'
  if (m < 60) return `${m} mins ago`
  const h = Math.floor(m / 60)
  if (h < 24) return `${h}h ago`
  return 'Yesterday'
}

function EditModal({ open, item, onClose, onSave }) {
  const [sel, setSel] = useState('')
  useEffect(() => setSel(item?.predicted_category || ''), [item])
  return (
    <Modal open={open} onClose={onClose} title="Edit Classification Label" width="max-w-sm">
      <p className="text-xs text-ink-muted mb-4">
        Current: <span className="text-eco font-semibold">{item?.predicted_category}</span>
        {item?.confidence_score != null && <span className="ml-2">({Math.round(item.confidence_score*100)}% conf.)</span>}
      </p>
      <div className="grid grid-cols-3 gap-2 mb-5">
        {ALL_CATS.map(cat => (
          <button key={cat} onClick={() => setSel(cat)}
            className={`px-2 py-1.5 rounded-lg text-[0.72rem] font-semibold border transition-all cursor-pointer
              ${sel===cat ? 'bg-eco text-ink-inverse border-eco' : 'bg-gb-surface border-gb-border text-ink-sub hover:border-eco-border hover:text-eco'}`}>
            {cat}
          </button>
        ))}
      </div>
      <div className="flex gap-2 justify-end">
        <button className="btn btn-ghost btn-sm" onClick={onClose}>Cancel</button>
        <button className="btn btn-primary btn-sm" onClick={() => { onSave(item?.id,sel); onClose() }} disabled={sel===item?.predicted_category}>
          Save Label
        </button>
      </div>
    </Modal>
  )
}

export default function Classifications() {
  const [items,     setItems]     = useState([])
  const [filtered,  setFiltered]  = useState([])
  const [loading,   setLoading]   = useState(true)
  const [filter,    setFilter]    = useState('ALL')
  const [editModal, setEditModal] = useState(false)
  const [editItem,  setEditItem]  = useState(null)
  const [catDist,   setCatDist]   = useState([])

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const [hRes, dRes] = await Promise.all([
        classificationApi.getHistory({ limit: 50, skip: 0 }),
        analyticsApi.getDashboard(),
      ])
      const data = Array.isArray(hRes.data) ? hRes.data : MOCK_ITEMS
      setItems(data)
      setFiltered(data)
      const dist = dRes.data?.category_distribution || []
      const t    = dist.reduce((s,d)=>s+d.count,0) || 2400
      setCatDist([
        { name:'Plastic (PET/HDPE)', value: dist.find(d=>d.category==='PLASTIC')?.count || Math.round(t*0.40) },
        { name:'Paper & Card',       value: dist.find(d=>d.category==='PAPER')?.count   || Math.round(t*0.25) },
        { name:'Metal & Glass',      value: dist.find(d=>d.category==='METAL')?.count   || Math.round(t*0.15) },
        { name:'Others / Unknown',   value: dist.find(d=>d.category==='OTHER')?.count   || Math.round(t*0.20) },
      ])
    } catch {
      setItems(MOCK_ITEMS); setFiltered(MOCK_ITEMS); setCatDist(MOCK_DIST)
    } finally { setLoading(false) }
  }, [])

  useEffect(() => { load() }, [load])
  useEffect(() => {
    setFiltered(filter === 'LOW_CONF' ? items.filter(i => (i.confidence_score??i.conf/100) < 0.80) : items)
  }, [filter, items])

  const handleSave = async (id, category) => {
    try {
      await classificationApi.addFeedback(id, category)
      setItems(prev => prev.map(i => i.id===id ? {...i, predicted_category:category, is_verified:true} : i))
    } catch(e) { console.error(e) }
  }

  const handleExport = async () => {
    try {
      const res = await analyticsApi.exportClassifications()
      const url = URL.createObjectURL(new Blob([res.data]))
      Object.assign(document.createElement('a'), { href:url, download:`cls_${Date.now()}.csv` }).click()
      URL.revokeObjectURL(url)
    } catch(e) { console.error(e) }
  }

  const totalDonut = catDist.reduce((s,d)=>s+d.value,0)
  const reviewed   = items.filter(i=>i.is_verified).length
  const goalPct    = Math.min(100, Math.round((reviewed/Math.max(items.length,1))*100)) || 85

  return (
    <Layout title="Classifications Management">
      <div className="flex gap-5">

        {/* Main content */}
        <div className="flex-1 min-w-0 space-y-4">

          {/* Filter bar */}
          <div className="flex items-center gap-3 flex-wrap">
            {[
              { id:'ALL',      icon:Filter,       label:'All Categories',     active:'bg-eco-muted border-eco text-eco',          inactive:'hover:border-eco-border hover:text-eco' },
              { id:'LOW_CONF', icon:AlertTriangle, label:'Low Confidence Only', active:'bg-yellow-500/15 border-yellow-500/40 text-yellow-400', inactive:'hover:border-yellow-500/40 hover:text-yellow-400' },
            ].map(({ id, icon:Icon, label, active, inactive }) => (
              <button key={id} onClick={()=>setFilter(id)}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl text-[0.82rem] font-semibold border transition-all cursor-pointer
                  ${filter===id ? active : `bg-gb-card border-gb-border text-ink-sub ${inactive}`}`}>
                <Icon size={14}/> {label}
              </button>
            ))}
            <button className="flex items-center gap-2 px-4 py-2 rounded-xl text-[0.82rem] font-semibold border border-gb-border bg-gb-card text-ink-sub hover:border-eco-border hover:text-eco transition-all cursor-pointer">
              <Calendar size={14}/> This Week
            </button>
            <span className="ml-auto text-[0.8rem] text-ink-muted">
              Showing <strong className="text-ink">{filtered.length}</strong> items
            </span>
          </div>

          {/* Cards grid */}
          {loading ? <Spinner /> : filtered.length===0 ? <EmptyState icon="🗂️" message="No classifications found"/> : (
            <div className="grid grid-cols-4 gap-4">
              {filtered.map((item,i) => {
                const conf        = item.confidence_score ?? (item.conf/100)
                const pct         = Math.round(conf*100)
                const cat         = item.predicted_category || 'UNKNOWN'
                const needsReview = conf < 0.60 || cat === 'UNKNOWN'
                return (
                  <div key={item.id||i}
                    className={`card overflow-hidden flex flex-col group animate-fade-up ${needsReview?'border-yellow-500/25':''}`}
                    style={{ animationDelay:`${i*35}ms` }}>
                    {/* Image */}
                    <div className="relative h-36 bg-gb-surface overflow-hidden">
                      {item.image_url ? (
                        <img src={item.image_url} alt={cat}
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                          onError={e=>{ e.target.style.display='none' }}/>
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-4xl">
                          {cat==='PLASTIC'?'🧴':cat==='PAPER'?'📦':cat==='GLASS'?'🫙':cat==='METAL'?'🥫':cat==='ORGANIC'?'🥦':'♻️'}
                        </div>
                      )}
                      <span className={`absolute top-2 left-2 text-[0.68rem] font-bold px-2 py-0.5 rounded-lg ${confBadgeClass(conf)}`}>
                        {pct}% Conf.
                      </span>
                      <span className="absolute top-2 right-2">
                        {item.is_verified   ? <CheckCircle2 size={15} className="text-eco"/> :
                         needsReview        ? <AlertTriangle size={15} className="text-yellow-400"/> :
                                             <Sparkles size={15} className="text-eco"/>}
                      </span>
                    </div>
                    {/* Body */}
                    <div className="p-3 flex flex-col gap-2 flex-1">
                      <div>
                        <p className="text-[0.88rem] font-bold text-ink leading-tight">
                          {item.label || LABEL_MAP[cat] || cat}
                        </p>
                        <p className="text-[0.7rem] text-ink-muted mt-0.5">Detected: {cat.charAt(0)+cat.slice(1).toLowerCase()}</p>
                      </div>
                      <div className="flex items-center gap-1 text-[0.68rem] text-ink-muted">
                        <Clock size={10}/> {timeAgo(item.timestamp)}
                      </div>
                      <button onClick={()=>{setEditItem(item);setEditModal(true)}}
                        className={`flex items-center gap-1.5 text-[0.74rem] font-semibold transition-colors cursor-pointer mt-auto bg-transparent border-none p-0
                          ${needsReview&&!item.is_verified ? 'text-red-400 hover:text-red-300' : 'text-ink-sub hover:text-eco'}`}>
                        <Pencil size={11}/>
                        {needsReview && !item.is_verified ? 'Review Now' : 'Edit Label'}
                      </button>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>

        {/* Right sidebar */}
        <div className="w-60 flex-shrink-0 space-y-4">

          {/* Donut chart */}
          <div className="card p-4">
            <h3 className="section-title mb-4">Category Distribution</h3>
            <div className="relative h-44">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={catDist.length?catDist:MOCK_DIST} cx="50%" cy="50%"
                    innerRadius={52} outerRadius={72} dataKey="value" paddingAngle={2} strokeWidth={0}>
                    {(catDist.length?catDist:MOCK_DIST).map((_,idx)=>(
                      <Cell key={idx} fill={DONUT_COLORS[idx%DONUT_COLORS.length]}/>
                    ))}
                  </Pie>
                  <Tooltip formatter={v=>[`${v} items`,'']}
                    contentStyle={{background:'#111f11',border:'1px solid rgba(34,197,94,0.15)',borderRadius:8,fontSize:11}}/>
                </PieChart>
              </ResponsiveContainer>
              <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-[1.3rem] font-bold text-ink leading-none">
                  {totalDonut>=1000?`${(totalDonut/1000).toFixed(1)}k`:totalDonut||'2.4k'}
                </span>
                <span className="text-[0.63rem] text-ink-muted mt-0.5">Items Total</span>
              </div>
            </div>
            <div className="space-y-2.5 mt-1">
              {(catDist.length?catDist:MOCK_DIST).map((d,i)=>{
                const pct=totalDonut?Math.round((d.value/totalDonut)*100):[40,25,15,20][i]
                return (
                  <div key={d.name} className="flex items-center justify-between gap-2">
                    <div className="flex items-center gap-1.5">
                      <div className="w-2 h-2 rounded-full flex-shrink-0" style={{background:DONUT_COLORS[i]}}/>
                      <span className="text-[0.7rem] text-ink-sub">{d.name}</span>
                    </div>
                    <span className="text-[0.7rem] font-bold text-ink">{pct}%</span>
                  </div>
                )
              })}
            </div>
          </div>

          {/* Goal progress */}
          <div className="card p-4 space-y-2.5">
            <div className="flex items-center justify-between">
              <h3 className="text-[0.83rem] font-bold text-ink">Classification Goal</h3>
              <span className="text-[0.7rem] font-bold text-eco">{goalPct}% Complete</span>
            </div>
            <div className="h-2 bg-gb-surface rounded-full overflow-hidden">
              <div className="h-full bg-eco rounded-full transition-all duration-700" style={{width:`${goalPct}%`}}/>
            </div>
            <p className="text-[0.7rem] text-ink-muted leading-relaxed">
              You've reviewed {reviewed} items today. Keep up the great work ensuring data quality!
            </p>
          </div>

          <button onClick={handleExport} className="btn btn-primary w-full justify-center gap-2 py-3">
            <Download size={14}/> Export Report
          </button>
          <button onClick={load} className="btn btn-ghost w-full justify-center gap-2 text-[0.78rem]">
            <RotateCcw size={12}/> Refresh
          </button>
        </div>
      </div>

      <EditModal open={editModal} item={editItem} onClose={()=>setEditModal(false)} onSave={handleSave}/>
    </Layout>
  )
}

const MOCK_ITEMS = [
  {id:'1',predicted_category:'PLASTIC', confidence_score:0.94,timestamp:new Date(Date.now()-120000).toISOString()},
  {id:'2',predicted_category:'METAL',   confidence_score:0.88,timestamp:new Date(Date.now()-900000).toISOString()},
  {id:'3',predicted_category:'PAPER',   confidence_score:0.91,timestamp:new Date(Date.now()-3600000).toISOString()},
  {id:'4',predicted_category:'UNKNOWN', confidence_score:0.45,timestamp:new Date(Date.now()-7200000).toISOString()},
  {id:'5',predicted_category:'GLASS',   confidence_score:0.76,timestamp:new Date(Date.now()-10800000).toISOString()},
  {id:'6',predicted_category:'PAPER',   confidence_score:0.65,timestamp:new Date(Date.now()-14400000).toISOString()},
  {id:'7',predicted_category:'PLASTIC', confidence_score:0.95,timestamp:new Date(Date.now()-18000000).toISOString()},
  {id:'8',predicted_category:'METAL',   confidence_score:0.82,timestamp:new Date(Date.now()-86400000).toISOString()},
]
const MOCK_DIST = [
  {name:'Plastic (PET/HDPE)',value:40},{name:'Paper & Card',value:25},
  {name:'Metal & Glass',value:15},{name:'Others / Unknown',value:20},
]