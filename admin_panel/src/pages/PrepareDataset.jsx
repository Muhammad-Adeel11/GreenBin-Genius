import React, { useEffect, useState, useCallback } from 'react'
import {
  Download, CheckCircle2, AlertTriangle, Play,
  FolderOpen, Layers, Check, RefreshCw, HelpCircle,
} from 'lucide-react'
import Layout from '../components/layout/Layout'
import { Spinner, EmptyState } from '../components/ui/index.jsx'
import { classificationApi } from '../api'

const CLASSES = [
  { id: 'PLASTIC',  label: 'Plastic',  icon: '🧴', color: '#22c55e' },
  { id: 'METAL',    label: 'Metal',    icon: '🥫', color: '#94a3b8' },
  { id: 'GLASS',    label: 'Glass',    icon: '🫙', color: '#38bdf8' },
  { id: 'PAPER',    label: 'Paper',    icon: '📦', color: '#f59e0b' },
  { id: 'ORGANIC',  label: 'Organic',  icon: '🥦', color: '#a3e635' },
  { id: 'E_WASTE',  label: 'E-Waste',  icon: '🔌', color: '#f97316' },
  { id: 'TEXTILE',  label: 'Textile',  icon: '👕', color: '#c084fc' },
  { id: 'WOOD',     label: 'Wood',     icon: '🪵', color: '#8b5cf6' },
]

export default function PrepareDataset() {
  const [selectedClass, setSelectedClass] = useState('PLASTIC')
  const [items, setSelectedItems]         = useState([])
  const [loading, setLoading]             = useState(false)
  const [batchActionRunning, setBatchActionRunning] = useState(false)

  const load = useCallback(async (category) => {
    setLoading(true)
    try {
      const res = await classificationApi.getHistory({ category, limit: 100, skip: 0 })
      const data = res.data?.items || (Array.isArray(res.data) ? res.data : [])
      setSelectedItems(data)
    } catch (e) {
      console.error('Failed to load dataset items:', e)
      setSelectedItems([])
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load(selectedClass)
  }, [selectedClass, load])

  const handleDownloadImage = async (url, filename) => {
    if (!url) return
    try {
      const response = await fetch(url)
      const blob = await response.blob()
      const blobUrl = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = blobUrl
      a.download = filename || 'dataset_image.jpg'
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(blobUrl)
    } catch (e) {
      window.open(url, '_blank')
    }
  }

  const handleVerify = async (id, correctClass) => {
    try {
      await classificationApi.addFeedback(id, correctClass)
      setSelectedItems(prev =>
        prev.map(item =>
          item.id === id
            ? { ...item, category: correctClass, predicted_category: correctClass, is_verified: true }
            : item
        )
      )
    } catch (e) {
      console.error('Failed to verify classification:', e)
    }
  }

  const handleRelabel = async (id, targetClass) => {
    try {
      await classificationApi.addFeedback(id, targetClass)
      // Since it's relabeled to a DIFFERENT class, remove it from the current class list view
      setSelectedItems(prev => prev.filter(item => item.id !== id))
    } catch (e) {
      console.error('Failed to relabel classification:', e)
    }
  }

  const handleDownloadAll = async () => {
    setBatchActionRunning(true)
    try {
      // Direct bulk metadata file download (CSV)
      const csvContent = "data:text/csv;charset=utf-8," 
        + ["ID,Image URL,Category,Is Verified,Timestamp"].join(",") + "\n"
        + items.map(item => `"${item.id}","${item.image_url || ''}","${item.category || item.predicted_category || ''}",${item.is_verified || false},"${item.timestamp || ''}"`).join("\n")
      
      const encodedUri = encodeURI(csvContent)
      const link = document.createElement("a")
      link.setAttribute("href", encodedUri)
      link.setAttribute("download", `dataset_${selectedClass.toLowerCase()}_metadata.csv`)
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    } catch (e) {
      console.error(e)
    } finally {
      setBatchActionRunning(false)
    }
  }

  return (
    <Layout title="Prepare Dataset" subtitle="Clean and curate waste images by category to retrain AI classifiers.">
      <div className="space-y-6">

        {/* Categories / Classes Selector */}
        <div className="grid grid-cols-8 gap-3">
          {CLASSES.map((cls) => {
            const isActive = selectedClass === cls.id
            return (
              <button
                key={cls.id}
                onClick={() => setSelectedClass(cls.id)}
                className={`card p-3 flex flex-col items-center justify-center text-center gap-2 border transition-all duration-200 cursor-pointer
                  ${isActive 
                    ? 'border-eco bg-eco-muted shadow-md ring-1 ring-eco' 
                    : 'border-gb-border bg-gb-card hover:border-eco-border hover:text-eco'
                  }`}
              >
                <span className="text-3xl">{cls.icon}</span>
                <span className="text-[0.78rem] font-bold text-ink leading-tight">{cls.label}</span>
              </button>
            )
          })}
        </div>

        {/* Action Header bar */}
        <div className="flex items-center justify-between bg-gb-card p-4 rounded-2xl border border-gb-border">
          <div className="flex items-center gap-2">
            <FolderOpen size={16} className="text-eco" />
            <h3 className="text-[0.88rem] font-bold text-ink">
              Classified Images for <span className="text-eco">{selectedClass}</span>
            </h3>
            <span className="text-xs text-ink-muted bg-gb-surface px-2.5 py-0.5 rounded-full border border-gb-border font-medium ml-2">
              {items.length} items found
            </span>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => load(selectedClass)}
              disabled={loading}
              className="btn btn-ghost btn-sm flex items-center gap-1.5"
            >
              <RefreshCw size={13} className={loading ? 'animate-spin' : ''} />
              Refresh
            </button>
            <button
              onClick={handleDownloadAll}
              disabled={loading || items.length === 0 || batchActionRunning}
              className="btn btn-primary btn-sm flex items-center gap-1.5"
            >
              <Download size={13} />
              Export Metadata CSV
            </button>
          </div>
        </div>

        {/* Main Grid Section */}
        {loading ? (
          <div className="py-20 flex justify-center"><Spinner /></div>
        ) : items.length === 0 ? (
          <EmptyState 
            icon="🗂️" 
            message={`No images collected under the '${selectedClass}' category yet.`} 
          />
        ) : (
          <div className="grid grid-cols-4 gap-4">
            {items.map((item, idx) => {
              const conf = item.confidence ?? item.confidence_score ?? (item.conf ? item.conf / 100 : 0)
              const pct = Math.round(conf * 100)
              return (
                <div 
                  key={item.id || idx} 
                  className={`card overflow-hidden flex flex-col group transition-all duration-300 ${item.is_verified ? 'border-eco/30' : 'border-gb-border'}`}
                >
                  
                  {/* Image container */}
                  <div className="relative h-44 bg-gb-surface overflow-hidden">
                    {item.image_url ? (
                      <>
                        <img 
                          src={item.image_url} 
                          alt={selectedClass} 
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                        />
                        {/* Hover Download button */}
                        <button
                          onClick={(e) => {
                            e.stopPropagation()
                            handleDownloadImage(item.image_url, `dataset_${selectedClass.toLowerCase()}_${item.id || idx}.jpg`)
                          }}
                          title="Download Image"
                          className="absolute bottom-2 right-2 p-1.5 rounded-lg bg-gb-surface/90 hover:bg-eco text-ink-sub hover:text-ink-inverse border border-gb-border hover:border-eco transition-all duration-200 cursor-pointer opacity-0 group-hover:opacity-100 shadow-md flex items-center justify-center"
                        >
                          <Download size={13} />
                        </button>
                      </>
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-4xl bg-gb-surface">
                        📷
                      </div>
                    )}
                    
                    {/* Confidence score badge */}
                    <span className="absolute top-2 left-2 text-[0.68rem] font-bold px-2 py-0.5 rounded-lg bg-gb-card/85 text-ink border border-gb-border">
                      {pct}% Conf.
                    </span>

                    {/* Status Badge */}
                    <span className="absolute top-2 right-2">
                      {item.is_verified ? (
                        <span className="flex items-center justify-center w-5 h-5 rounded-full bg-eco text-ink-inverse">
                          <CheckCircle2 size={13} />
                        </span>
                      ) : (
                        <span className="flex items-center justify-center w-5 h-5 rounded-full bg-yellow-500/80 text-white">
                          <AlertTriangle size={13} />
                        </span>
                      )}
                    </span>
                  </div>

                  {/* Body text & operations */}
                  <div className="p-3 flex flex-col gap-3 flex-grow">
                    <div className="flex justify-between items-start">
                      <div>
                        <p className="text-[0.84rem] font-bold text-ink leading-snug">
                          {item.label || item.object_detected || 'Detected Object'}
                        </p>
                        <p className="text-[0.68rem] text-ink-muted mt-0.5">
                          ID: <span className="font-mono text-ink-sub">{String(item.id).substring(0, 8)}...</span>
                        </p>
                      </div>
                    </div>

                    {/* Verification & Relabel Action Row */}
                    <div className="mt-auto space-y-2">
                      <div className="flex gap-1.5">
                        <button
                          onClick={() => handleVerify(item.id, selectedClass)}
                          disabled={item.is_verified}
                          className={`flex-1 py-1.5 rounded-lg text-[0.72rem] font-bold border transition-all flex items-center justify-center gap-1 cursor-pointer
                            ${item.is_verified 
                              ? 'bg-eco/10 border-eco/30 text-eco cursor-default' 
                              : 'bg-eco text-ink-inverse border-eco hover:bg-eco-hover'
                            }`}
                        >
                          <Check size={12} />
                          {item.is_verified ? 'Verified Correct' : 'Confirm Class'}
                        </button>
                      </div>

                      {/* Relabel Dropdown Selection */}
                      <div className="relative group/relabel">
                        <div className="text-[0.66rem] text-ink-muted font-medium mb-1">Incorrect? Relabel as:</div>
                        <div className="grid grid-cols-4 gap-1">
                          {CLASSES.filter(c => c.id !== selectedClass).map(c => (
                            <button
                              key={c.id}
                              onClick={() => handleRelabel(item.id, c.id)}
                              title={`Relabel as ${c.label}`}
                              className="px-1 py-1 rounded bg-gb-surface hover:bg-eco-muted border border-gb-border text-ink-sub hover:text-eco text-[0.66rem] font-semibold text-center transition-colors cursor-pointer truncate"
                            >
                              {c.label}
                            </button>
                          ))}
                        </div>
                      </div>
                    </div>

                  </div>
                </div>
              )
            })}
          </div>
        )}

      </div>
    </Layout>
  )
}
