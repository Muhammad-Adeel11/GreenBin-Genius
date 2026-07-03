import React, { useEffect, useState } from 'react'
import { Plus, Megaphone, Send, AlertCircle } from 'lucide-react'
import Layout from '../components/layout/Layout'
import { PageHeader, DataTable, Modal, Spinner } from '../components/ui/index.jsx'
import { notificationsApi, googleTranslateApi } from '../api'

export default function Campaigns() {
  const [campaigns, setCampaigns] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  
  // Create Modal State
  const [modalOpen, setModalOpen] = useState(false)
  const [modalLoading, setModalLoading] = useState(false)
  const [modalError, setModalError] = useState(null)
  
  // Form State
  const [titleEnglish, setTitleEnglish] = useState('')
  const [titleUrdu, setTitleUrdu] = useState('')
  const [messageEnglish, setMessageEnglish] = useState('')
  const [messageUrdu, setMessageUrdu] = useState('')
  const [targetAudience, setTargetAudience] = useState('ALL')

  const fetchCampaigns = async () => {
    setLoading(true)
    setError(null)
    try {
      const { data } = await notificationsApi.getCampaigns()
      setCampaigns(data.data || [])
    } catch (err) {
      setError(err.message || 'Failed to fetch campaigns')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchCampaigns()
  }, [])

  const handleCreateCampaign = async (e) => {
    e.preventDefault()
    setModalLoading(true)
    setModalError(null)
    try {
      const payload = {
        title_english: titleEnglish,
        title_urdu: titleUrdu,
        message_english: messageEnglish,
        message_urdu: messageUrdu,
        target_audience: targetAudience
      }
      await notificationsApi.createCampaign(payload)
      
      // Reset form & close modal
      setTitleEnglish('')
      setTitleUrdu('')
      setMessageEnglish('')
      setMessageUrdu('')
      setTargetAudience('ALL')
      setModalOpen(false)
      
      // Refresh list
      fetchCampaigns()
    } catch (err) {
      setModalError(err.response?.data?.detail || err.message || 'Failed to send campaign')
    } finally {
      setModalLoading(false)
    }
  }

  const columns = [
    {
      key: 'created_at',
      label: 'Sent Date',
      render: (val) => val ? new Date(val).toLocaleString('en-US', {
        dateStyle: 'short',
        timeStyle: 'short'
      }) : '—'
    },
    {
      key: 'title_english',
      label: 'Title (EN)',
      render: (val) => <span className="font-semibold text-ink">{val}</span>
    },
    {
      key: 'title_urdu',
      label: 'Title (UR)',
      render: (val) => <span className="text-ink text-right block" dir="rtl">{val}</span>
    },
    {
      key: 'message_english',
      label: 'Message (EN)',
      render: (val) => <span className="text-ink-sub text-xs line-clamp-2">{val}</span>
    },
    {
      key: 'message_urdu',
      label: 'Message (UR)',
      render: (val) => <span className="text-ink-sub text-xs line-clamp-2 text-right block" dir="rtl">{val}</span>
    },
    {
      key: 'target_audience',
      label: 'Audience',
      render: (val) => (
        <span className={`badge ${val === 'ALL' ? 'bg-eco-muted text-eco' : 'bg-yellow-500/15 text-yellow-400'}`}>
          {val === 'ALL' ? 'All Users' : 'Active Users'}
        </span>
      )
    },
    {
      key: 'recipients_count',
      label: 'Recipients',
      render: (val) => <span className="font-mono text-ink font-semibold">{val}</span>
    }
  ]

  const headerAction = (
    <button
      onClick={() => setModalOpen(true)}
      className="btn btn-primary flex items-center gap-2 cursor-pointer"
    >
      <Plus size={16} />
      <span>New Campaign</span>
    </button>
  )

  return (
    <Layout title="Campaigns">
      <PageHeader 
        title="Eco-Awareness Campaigns" 
        subtitle="Schedule and broadcast push notifications directly to user devices." 
        action={headerAction}
      />

      <div className="card p-6">
        {error ? (
          <div className="flex items-center gap-2 bg-red-500/10 border border-red-500/20 rounded-lg px-4 py-3 text-red-400 text-sm">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        ) : loading ? (
          <Spinner />
        ) : (
          <DataTable 
            columns={columns} 
            data={campaigns} 
            pageSize={10} 
            emptyIcon="📢" 
            emptyMsg="No campaigns sent yet." 
          />
        )}
      </div>

      {/* Create Campaign Modal */}
      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title="Broadcast New Campaign">
        <form onSubmit={handleCreateCampaign} className="space-y-4">
          {modalError && (
            <div className="flex items-center gap-2 bg-red-500/10 border border-red-500/20 rounded-lg px-4 py-3 text-red-400 text-sm">
              <AlertCircle size={16} />
              <span>{modalError}</span>
            </div>
          )}

          <div className="space-y-1.5">
            <label className="text-[0.76rem] font-semibold text-ink-sub">Target Audience</label>
            <select
              value={targetAudience}
              onChange={e => setTargetAudience(e.target.value)}
              className="input text-sm"
              required
            >
              <option value="ALL">All Registered Users</option>
              <option value="ACTIVE_USERS">Active Users (Min. 1 Scan)</option>
            </select>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <label className="text-[0.76rem] font-semibold text-ink-sub">Title (English)</label>
              <input
                type="text"
                value={titleEnglish}
                onChange={e => setTitleEnglish(e.target.value)}
                placeholder="e.g., Waste Sorting Tip!"
                className="input"
                required
              />
            </div>
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <button
                  type="button"
                  onClick={async () => {
                    const translated = await googleTranslateApi.translateToUrdu(titleEnglish)
                    setTitleUrdu(translated)
                  }}
                  className="text-[0.7rem] text-eco font-bold hover:underline cursor-pointer bg-transparent border-none"
                >
                  ✨ Auto-Translate
                </button>
                <label className="text-[0.76rem] font-semibold text-ink-sub text-right block">Title (Urdu)</label>
              </div>
              <input
                type="text"
                value={titleUrdu}
                onChange={e => setTitleUrdu(e.target.value)}
                placeholder="مثال: کوڑا کرکٹ الگ کرنے کا طریقہ"
                className="input text-right"
                dir="rtl"
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <label className="text-[0.76rem] font-semibold text-ink-sub">Message (English)</label>
              <textarea
                value={messageEnglish}
                onChange={e => setMessageEnglish(e.target.value)}
                placeholder="Enter details of your campaign Tip..."
                rows={4}
                className="input"
                required
              />
            </div>
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <button
                  type="button"
                  onClick={async () => {
                    const translated = await googleTranslateApi.translateToUrdu(messageEnglish)
                    setMessageUrdu(translated)
                  }}
                  className="text-[0.7rem] text-eco font-bold hover:underline cursor-pointer bg-transparent border-none"
                >
                  ✨ Auto-Translate
                </button>
                <label className="text-[0.76rem] font-semibold text-ink-sub text-right block">Message (Urdu)</label>
              </div>
              <textarea
                value={messageUrdu}
                onChange={e => setMessageUrdu(e.target.value)}
                placeholder="اپنی مہم کی تفصیلات درج کریں..."
                rows={4}
                className="input text-right"
                dir="rtl"
                required
              />
            </div>
          </div>

          <div className="flex justify-end gap-2.5 pt-3.5 border-t border-gb-border">
            <button
              type="button"
              onClick={() => setModalOpen(false)}
              className="btn btn-ghost px-4 py-2 cursor-pointer text-ink-sub"
              disabled={modalLoading}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="btn btn-primary flex items-center gap-2 px-4 py-2 cursor-pointer"
              disabled={modalLoading}
            >
              {modalLoading ? 'Sending...' : (
                <>
                  <Send size={14} />
                  <span>Broadcast Campaign</span>
                </>
              )}
            </button>
          </div>
        </form>
      </Modal>
    </Layout>
  )
}
