import React, { useEffect, useState, useCallback } from 'react'
import {
  Search, Plus, MapPin, ChevronRight, X,
  AlertTriangle, Wrench, CheckCircle2,
} from 'lucide-react'
import Layout from '../components/layout/Layout'
import { Modal, Spinner } from '../components/ui/index.jsx'
import { binsApi } from '../api'
import { GoogleMap, useJsApiLoader, MarkerF, InfoWindowF } from '@react-google-maps/api'
import { DARK_EMERALD_STYLE } from '../api/mapStyles'

const GOOGLE_API_KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY || ''

const mapContainerStyle = {
  width: '100%',
  height: '100%'
}

const defaultCenter = {
  lat: 33.6844,
  lng: 73.0479
}

/* ── Status config ────────────────────────────────────────────────────────── */
const STATUS_CFG = {
  ACTIVE:      { label:'AVAILABLE',   dot:'bg-eco',        badge:'text-eco bg-eco-muted border-eco/30',       icon:CheckCircle2 },
  AVAILABLE:   { label:'AVAILABLE',   dot:'bg-eco',        badge:'text-eco bg-eco-muted border-eco/30',       icon:CheckCircle2 },
  FULL:        { label:'FULL',        dot:'bg-red-500',    badge:'text-red-400 bg-red-500/10 border-red-500/20', icon:AlertTriangle },
  MAINTENANCE: { label:'MAINTENANCE', dot:'bg-yellow-400', badge:'text-yellow-400 bg-yellow-500/10 border-yellow-500/20', icon:Wrench },
  INACTIVE:    { label:'INACTIVE',    dot:'bg-gb-border',  badge:'text-ink-muted bg-gb-surface border-gb-border', icon:X },
}

function statusCfg(s) { return STATUS_CFG[s?.toUpperCase()] || STATUS_CFG.ACTIVE }

/* ── Bin list card ────────────────────────────────────────────────────────── */
function BinCard({ bin, active, onClick }) {
  const cfg = statusCfg(bin.status)
  const Icon = cfg.icon
  const lat  = bin.latitude  || bin.location?.coordinates?.[1] || 33.6844
  const lng  = bin.longitude || bin.location?.coordinates?.[0] || 73.0479
  return (
    <div onClick={() => onClick(bin)}
      className={`p-3.5 rounded-xl border cursor-pointer transition-all duration-150 group
        ${active ? 'border-eco bg-eco-muted' : 'border-gb-border bg-gb-card hover:border-eco-border hover:bg-gb-hover'}`}>
      <div className="flex items-center justify-between mb-2.5">
        <div className="flex items-center gap-2">
          <Icon size={15} className={active ? 'text-eco' : cfg.dot === 'bg-eco' ? 'text-eco' : cfg.dot === 'bg-red-500' ? 'text-red-400' : 'text-yellow-400'}/>
          <span className="text-[0.88rem] font-bold text-ink">{bin.name || `BIN-${bin.id?.slice(-3)?.toUpperCase() || '101'}`}</span>
        </div>
        <span className={`badge text-[0.66rem] border ${cfg.badge}`}>{cfg.label}</span>
      </div>
      <div className="space-y-1 text-[0.74rem]">
        <div className="flex justify-between">
          <span className="text-ink-muted">Material</span>
          <span className="text-ink font-medium">{(bin.waste_types||['Plastic'])[0]?.charAt(0)+(bin.waste_types||['Plastic'])[0]?.slice(1).toLowerCase()}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-ink-muted">Last Update</span>
          <span className="text-ink">{bin.last_update || '2 mins ago'}</span>
        </div>
      </div>
      <div className="flex items-center justify-between mt-2.5 pt-2.5 border-t border-gb-border">
        <div className="flex items-center gap-1 text-[0.68rem] text-ink-muted">
          <MapPin size={10}/> {lat.toFixed(4)}° N, {Math.abs(lng).toFixed(4)}° E
        </div>
        <ChevronRight size={13} className="text-ink-muted group-hover:text-eco transition-colors"/>
      </div>
    </div>
  )
}

/* ── Map pin ──────────────────────────────────────────────────────────────── */
function MapPin2({ x, y, status, active, onClick, label }) {
  const cfg = statusCfg(status)
  return (
    <div className="absolute cursor-pointer" style={{ left:`${x}%`, top:`${y}%`, transform:'translate(-50%,-50%)' }} onClick={onClick}>
      <div className={`relative group`}>
        <div className={`w-4 h-4 rounded-full border-2 border-white shadow-lg transition-all duration-200
          ${active ? 'scale-150' : 'hover:scale-125'}
          ${cfg.dot}`}/>
        {active && (
          <div className={`absolute -top-0.5 -left-0.5 w-5 h-5 rounded-full opacity-40 animate-pulse ${cfg.dot}`}/>
        )}
        {label && active && (
          <div className="absolute -top-7 left-1/2 -translate-x-1/2 bg-gb-card border border-gb-border rounded px-1.5 py-0.5 text-[0.6rem] whitespace-nowrap text-ink font-semibold shadow">
            {label}
          </div>
        )}
      </div>
    </div>
  )
}

/* ── Add Bin Modal ────────────────────────────────────────────────────────── */
function AddBinModal({ open, onClose, onSave, initialData }) {
  const [form, setForm] = useState({ name:'', address:'', latitude:'', longitude:'', waste_types:[] })
  
  useEffect(() => {
    if (initialData) {
      setForm(p => ({ ...p, ...initialData }))
    } else if (open) {
      setForm({ name:'', address:'', latitude:'', longitude:'', waste_types:[] })
    }
  }, [initialData, open])

  const set = (k,v) => setForm(p=>({...p,[k]:v}))
  return (
    <Modal open={open} onClose={onClose} title="Add New Bin Location" width="max-w-md">
      <div className="space-y-3">
        {[['name','Bin Name (e.g. BIN-105)'],['address','Address'],['latitude','Latitude'],['longitude','Longitude']].map(([k,ph])=>(
          <div key={k}>
            <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1 capitalize">{k}</label>
            <input value={form[k]} onChange={e=>set(k,e.target.value)} placeholder={ph} className="input text-[0.82rem] py-2" type={k==='latitude'||k==='longitude' ? 'number' : 'text'}/>
          </div>
        ))}
        <div className="flex gap-2 justify-end pt-1">
          <button className="btn btn-ghost btn-sm" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary btn-sm" onClick={() => { onSave(form); onClose() }}>Add Bin</button>
        </div>
      </div>
    </Modal>
  )
}


export default function BinLocations() {
  const [bins,       setBins]       = useState([])
  const [loading,    setLoading]    = useState(true)
  const [search,     setSearch]     = useState('')
  const [statusFilter, setStatus]   = useState('All Bins')
  const [activeId,   setActiveId]   = useState(null)
  const [addModal,   setAddModal]   = useState({ open: false, initialData: null })


  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await binsApi.getAll()
      const data = Array.isArray(res.data) ? res.data : []
      setBins(data.length ? data : MOCK_BINS)
    } catch { setBins(MOCK_BINS) }
    finally { setLoading(false) }
  }, [])

  useEffect(() => { load() }, [load])

  const filtered = bins.filter(b => {
    const matchSearch = !search || (b.name||'').toLowerCase().includes(search.toLowerCase()) || (b.waste_types||[]).join(' ').toLowerCase().includes(search.toLowerCase())
    const matchStatus = statusFilter === 'All Bins' || b.status?.toUpperCase().includes(statusFilter.toUpperCase()) || statusFilter === b.status
    return matchSearch && matchStatus
  })

  const activeBin = bins.find(b => b.id === activeId || b._id === activeId)

  const handleAdd = async (form) => {
    try {
      await binsApi.create({ ...form, latitude: parseFloat(form.latitude), longitude: parseFloat(form.longitude), waste_types: ['PLASTIC'] })
      load()
    } catch(e) { console.error(e) }
  }

  const { isLoaded } = useJsApiLoader({
    id: 'google-map-script',
    googleMapsApiKey: GOOGLE_API_KEY
  })

  const [map, setMap] = useState(null)

  const onMapLoad = useCallback((mapInstance) => {
    setMap(mapInstance)
  }, [])

  const onMapClick = useCallback((e) => {
    const lat = e.latLng.lat()
    const lng = e.latLng.lng()
    setAddModal({ open: true, initialData: { latitude: lat.toFixed(6), longitude: lng.toFixed(6) } })
  }, [])

  const handleMarkerClick = (id) => {
    setActiveId(id)
  }


  // Effect to pan map when activeId changes from sidebar
  useEffect(() => {
    if (map && activeId) {
      const bin = bins.find(b => b.id === activeId || b._id === activeId) || MOCK_BINS.find(b => b.id === activeId)
      if (bin) {
        const lat = bin.latitude || bin.location?.coordinates?.[1]
        const lng = bin.longitude || bin.location?.coordinates?.[0]
        if (lat && lng) {
          map.panTo({ lat, lng })
          map.setZoom(16)
        }
      }
    }
  }, [activeId, map, bins])

  return (
    <Layout title="Disposal Locations" subtitle="Manage bins & GPS coordinates">
      <div className="flex gap-0 h-[calc(100vh-130px)] -mx-7 -mb-7">

        {/* ── Left sidebar ─────────────────────────────────────────── */}
        <div className="w-96 flex-shrink-0 flex flex-col border-r border-gb-border bg-gb-surface">
          {/* Header */}
          <div className="p-4 border-b border-gb-border space-y-3">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-[1.2rem] font-bold text-ink">Disposal Locations</h2>
                <p className="text-[0.72rem] text-ink-muted">Manage bins & GPS coordinates</p>
              </div>
              <button onClick={() => setAddModal({ open: true, initialData: null })}
                className="btn btn-primary btn-sm gap-1.5 text-[0.78rem]">
                <MapPin size={13}/> Add Bin
              </button>

            </div>
            {/* Search */}
            <div className="relative">
              <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-muted pointer-events-none"/>
              <input value={search} onChange={e=>setSearch(e.target.value)}
                placeholder="Search by ID, Status, Material..."
                className="input pl-9 text-[0.8rem] py-2"/>
            </div>
            {/* Filter tabs */}
            <div className="flex gap-2 flex-wrap">
              {['All Bins','Full','Available','Maintenance'].map(s => (
                <button key={s} onClick={() => setStatus(s)}
                  className={`px-3 py-1 rounded-full text-[0.72rem] font-semibold border transition-all cursor-pointer
                    ${statusFilter===s ? 'bg-eco text-ink-inverse border-eco' : 'bg-transparent border-gb-border text-ink-muted hover:border-eco-border hover:text-eco'}`}>
                  {s}
                </button>
              ))}
            </div>
          </div>

          {/* Bin list */}
          <div className="flex-1 overflow-y-auto p-3 space-y-2.5">
            {loading ? <Spinner/> : filtered.map((bin, i) => (
              <BinCard key={bin.id||bin._id||i} bin={bin}
                active={(bin.id||bin._id) === activeId}
                onClick={b => setActiveId(b.id||b._id)}/>
            ))}
          </div>

          {/* Footer */}
          <div className="p-3 border-t border-gb-border flex items-center justify-between text-[0.72rem] text-ink-muted">
            <span>Showing {filtered.length} of {bins.length} bins</span>
            <button className="text-eco font-semibold hover:underline bg-transparent border-none cursor-pointer">View Archived</button>
          </div>
        </div>

        {/* ── Map area ─────────────────────────────────────────────── */}
        <div className="flex-1 relative bg-[#0a1a0a] overflow-hidden">
          {isLoaded ? (
            <GoogleMap
              mapContainerStyle={mapContainerStyle}
              center={defaultCenter}
              zoom={13}
              onLoad={onMapLoad}
              onClick={onMapClick}
              options={{
                styles: DARK_EMERALD_STYLE,
                disableDefaultUI: true,
                zoomControl: false,
                mapTypeControl: false,
                streetViewControl: false,
                fullscreenControl: false
              }}
            >

              {(bins.length ? bins : MOCK_BINS).map((bin) => {
                const lat = bin.latitude || bin.location?.coordinates?.[1] || 33.6844
                const lng = bin.longitude || bin.location?.coordinates?.[0] || 73.0479
                const cfg = statusCfg(bin.status)
                const id = bin.id || bin._id
                
                return (
                  <MarkerF
                    key={id}
                    position={{ lat, lng }}
                    onClick={() => handleMarkerClick(id)}
                    icon={{
                      path: "M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z",
                      fillColor: cfg.dot === 'bg-eco' ? '#22c55e' : cfg.dot === 'bg-red-500' ? '#ef4444' : '#f59e0b',
                      fillOpacity: 1,
                      strokeWeight: 2,
                      strokeColor: "#ffffff",
                      scale: activeId === id ? 1.5 : 1.2,
                      anchor: { x: 12, y: 22 }
                    }}
                  />
                )
              })}
            </GoogleMap>
          ) : (
            <div className="w-full h-full flex items-center justify-center text-eco/40">
              <Spinner />
              <span className="ml-3 font-medium">Loading Google Maps...</span>
            </div>
          )}

          {/* Detail popup */}
          {activeBin && (
            <div className="absolute top-1/2 left-1/2 -translate-y-1/2 z-20" style={{ marginLeft: 20 }}>
              <div className="w-64 bg-gb-card border border-gb-border rounded-xl shadow-modal overflow-hidden animate-fade-up">
                <div className="flex items-center justify-between px-4 py-3 border-b border-gb-border">
                  <span className="text-[0.88rem] font-bold text-ink">{activeBin.name} Details</span>
                  <button onClick={() => setActiveId(null)} className="text-ink-muted hover:text-ink cursor-pointer bg-transparent border-none">
                    <X size={14}/>
                  </button>
                </div>
                <div className="p-4 space-y-2.5 text-[0.78rem]">
                  <div className="flex justify-between items-center">
                    <span className="text-ink-muted uppercase text-[0.62rem] font-bold tracking-wider">Status</span>
                    <span className={`badge text-[0.68rem] border ${statusCfg(activeBin.status).badge}`}>
                      {statusCfg(activeBin.status).label}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-ink-muted uppercase text-[0.62rem] font-bold tracking-wider">Type</span>
                    <span className="text-ink font-medium">
                      {(activeBin.waste_types||['Glass'])[0]?.charAt(0)+(activeBin.waste_types||['Glass'])[0]?.slice(1).toLowerCase()} Recycle
                    </span>
                  </div>
                  <div className="flex items-center gap-1.5 text-ink-muted">
                    <MapPin size={11} className="text-eco"/>
                    <span className="font-mono text-[0.68rem]">
                      {(activeBin.latitude||33.6938).toFixed(4)}° N, {Math.abs(activeBin.longitude||73.0652).toFixed(4)}° E
                    </span>
                  </div>
                  {activeBin.address && <p className="text-ink-muted text-[0.7rem] italic">{activeBin.address}</p>}
                </div>
                <div className="grid grid-cols-2 gap-2 px-4 pb-4">
                  <button className="btn btn-ghost btn-sm justify-center text-[0.74rem]">History</button>
                  <button className="btn btn-primary btn-sm justify-center text-[0.74rem]">Edit Location</button>
                </div>
              </div>
            </div>
          )}

          {/* Zoom controls */}
          <div className="absolute top-4 right-4 flex flex-col gap-1 z-20">
            <button key="recenter" title="Recenter Map" onClick={() => map?.panTo(defaultCenter)}
              className="w-9 h-9 bg-gb-card border border-gb-border rounded-lg flex items-center justify-center text-ink-sub text-[1rem] hover:text-eco hover:border-eco-border transition-all cursor-pointer shadow-card">
              ⊕
            </button>
            <button key="zoom_in" title="Zoom In" onClick={() => map?.setZoom((map.getZoom() || 13) + 1)}
              className="w-9 h-9 bg-gb-card border border-gb-border rounded-lg flex items-center justify-center text-ink-sub text-[1rem] hover:text-eco hover:border-eco-border transition-all cursor-pointer shadow-card">
              +
            </button>
            <button key="zoom_out" title="Zoom Out" onClick={() => map?.setZoom((map.getZoom() || 13) - 1)}
              className="w-9 h-9 bg-gb-card border border-gb-border rounded-lg flex items-center justify-center text-ink-sub text-[1rem] hover:text-eco hover:border-eco-border transition-all cursor-pointer shadow-card">
              −
            </button>
          </div>

          {/* Map legend */}
          <div className="absolute bottom-5 right-5 bg-gb-card border border-gb-border rounded-xl px-4 py-3 shadow-card">
            <p className="text-[0.65rem] font-bold tracking-[0.1em] uppercase text-ink-muted mb-2">Map Legend</p>
            {[
              { dot:'bg-eco',        label:'Available'     },
              { dot:'bg-red-500',    label:'Full / Critical'},
              { dot:'bg-yellow-400', label:'Maintenance'   },
            ].map(({dot,label}) => (
              <div key={label} className="flex items-center gap-2 mb-1.5 last:mb-0">
                <div className={`w-2.5 h-2.5 rounded-full ${dot}`}/>
                <span className="text-[0.72rem] text-ink-sub">{label}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <AddBinModal 
        open={addModal.open} 
        initialData={addModal.initialData}
        onClose={() => setAddModal({ open: false, initialData: null })} 
        onSave={handleAdd}
      />

    </Layout>
  )
}

const MOCK_BINS = [
  { id:'101', name:'BIN-101', status:'FULL',        waste_types:['Plastic'], latitude:33.6844, longitude:73.0479, last_update:'2 mins ago'  },
  { id:'102', name:'BIN-102', status:'ACTIVE',      waste_types:['Glass'],   latitude:33.6938, longitude:73.0652, last_update:'1 hr ago'    },
  { id:'103', name:'BIN-103', status:'MAINTENANCE', waste_types:['Organic'], latitude:33.7001, longitude:73.0511, last_update:'Yesterday'   },
  { id:'104', name:'BIN-104', status:'ACTIVE',      waste_types:['Paper'],   latitude:33.7122, longitude:73.0244, last_update:'3 days ago'  },
]