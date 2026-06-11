import React, { useEffect, useState, useCallback } from 'react'
import {
  Search, Plus, Pencil, Trash2, ChevronDown, ChevronUp,
  X, RefreshCw, Save, ExternalLink
} from 'lucide-react'
import Layout from '../components/layout/Layout'
import { Modal, Spinner, EmptyState } from '../components/ui/index.jsx'
import { faqsApi, resourcesApi } from '../api'

const FAQ_CATEGORIES = ['general', 'classification', 'locator', 'account', 'other']
const RESOURCE_CATEGORIES = ['Education', 'Composting', 'Tips', 'E-Waste', 'Other']

const EMPTY_FAQ = {
  question_en: '',
  question_ur: '',
  answer_en: '',
  answer_ur: '',
  category: 'general',
  is_active: true,
}

const EMPTY_RESOURCE = {
  title: '',
  url: '',
  category: 'Education',
  icon: '🔗',
  description: '',
  is_active: true,
}

export default function FaqsResources() {
  const [activeTab, setActiveTab] = useState('faqs') // 'faqs' | 'resources'
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)

  // FAQs State
  const [faqs, setFaqs] = useState([])
  const [faqModal, setFaqModal] = useState(false)
  const [editFaq, setEditFaq] = useState(null)
  const [faqForm, setFaqForm] = useState(EMPTY_FAQ)

  // Resources State
  const [resources, setResources] = useState([])
  const [resourceModal, setResourceModal] = useState(false)
  const [editResource, setEditResource] = useState(null)
  const [resourceForm, setResourceForm] = useState(EMPTY_RESOURCE)

  // Action status states
  const [saving, setSaving] = useState(false)

  // Load Data
  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      if (activeTab === 'faqs') {
        const res = await faqsApi.getAll({ limit: 100 })
        const data = Array.isArray(res.data?.data) ? res.data.data : Array.isArray(res.data) ? res.data : []
        setFaqs(data)
      } else {
        const res = await resourcesApi.getAll({ limit: 100 })
        const data = Array.isArray(res.data?.data) ? res.data.data : Array.isArray(res.data) ? res.data : []
        setResources(data)
      }
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
    }
  }, [activeTab])

  useEffect(() => {
    loadData()
  }, [loadData])

  // FAQ CRUD
  const handleOpenFaqModal = (faq = null) => {
    if (faq) {
      setEditFaq(faq)
      setFaqForm({ ...faq })
    } else {
      setEditFaq(null)
      setFaqForm(EMPTY_FAQ)
    }
    setFaqModal(true)
  }

  const handleSaveFaq = async (e) => {
    e.preventDefault()
    setSaving(true)
    try {
      if (editFaq) {
        await faqsApi.update(editFaq.id, faqForm)
      } else {
        await faqsApi.create(faqForm)
      }
      setFaqModal(false)
      loadData()
    } catch (err) {
      console.error(err)
    } finally {
      setSaving(false)
    }
  }

  const handleDeleteFaq = async (id) => {
    if (!window.confirm('Are you sure you want to delete this FAQ?')) return
    try {
      await faqsApi.delete(id)
      loadData()
    } catch (err) {
      console.error(err)
    }
  }

  const handleSeedDefaults = async () => {
    if (!window.confirm('Re-seed all FAQs and Resources from defaults? This will overwrite existing records.')) return
    setLoading(true)
    try {
      await faqsApi.seed()
      loadData()
    } catch (err) {
      console.error(err)
      setLoading(false)
    }
  }

  // Resource CRUD
  const handleOpenResourceModal = (resource = null) => {
    if (resource) {
      setEditResource(resource)
      setResourceForm({ ...resource })
    } else {
      setEditResource(null)
      setResourceForm(EMPTY_RESOURCE)
    }
    setResourceModal(true)
  }

  const handleSaveResource = async (e) => {
    e.preventDefault()
    setSaving(true)
    try {
      if (editResource) {
        await resourcesApi.update(editResource.id, resourceForm)
      } else {
        await resourcesApi.create(resourceForm)
      }
      setResourceModal(false)
      loadData()
    } catch (err) {
      console.error(err)
    } finally {
      setSaving(false)
    }
  }

  const handleDeleteResource = async (id) => {
    if (!window.confirm('Are you sure you want to delete this resource?')) return
    try {
      await resourcesApi.delete(id)
      loadData()
    } catch (err) {
      console.error(err)
    }
  }

  // Filters
  const filteredFaqs = faqs.filter(f =>
    !search ||
    f.question_en.toLowerCase().includes(search.toLowerCase()) ||
    f.answer_en.toLowerCase().includes(search.toLowerCase()) ||
    f.category.toLowerCase().includes(search.toLowerCase())
  )

  const filteredResources = resources.filter(r =>
    !search ||
    r.title.toLowerCase().includes(search.toLowerCase()) ||
    r.category.toLowerCase().includes(search.toLowerCase()) ||
    (r.description || '').toLowerCase().includes(search.toLowerCase())
  )

  return (
    <Layout title="FAQs & Resources Management" subtitle="Manage FAQs and external resources visible in the mobile application">
      {/* Top Controls */}
      <div className="flex items-center justify-between mb-6">
        {/* Tabs */}
        <div className="flex gap-1 border-b border-gb-border pb-1">
          <button
            onClick={() => { setActiveTab('faqs'); setSearch(''); }}
            className={`px-4 py-2 text-[0.85rem] font-bold rounded-lg transition-all cursor-pointer border-none
              ${activeTab === 'faqs' ? 'bg-eco text-ink-inverse' : 'bg-transparent text-ink-muted hover:text-ink'}`}
          >
            📋 Frequently Asked Questions (FAQs)
          </button>
          <button
            onClick={() => { setActiveTab('resources'); setSearch(''); }}
            className={`px-4 py-2 text-[0.85rem] font-bold rounded-lg transition-all cursor-pointer border-none
              ${activeTab === 'resources' ? 'bg-eco text-ink-inverse' : 'bg-transparent text-ink-muted hover:text-ink'}`}
          >
            🌱 External Eco-Resources
          </button>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-2">
          {activeTab === 'faqs' && (
            <button onClick={handleSeedDefaults} className="btn btn-ghost btn-sm gap-1.5 text-[0.78rem]">
              <RefreshCw size={13} /> Seed Defaults
            </button>
          )}
          <button
            onClick={() => activeTab === 'faqs' ? handleOpenFaqModal() : handleOpenResourceModal()}
            className="btn btn-primary gap-2 text-[0.82rem]"
          >
            <Plus size={14} /> Add {activeTab === 'faqs' ? 'FAQ' : 'Resource'}
          </button>
        </div>
      </div>

      {/* Search Bar */}
      <div className="flex justify-between items-center mb-5">
        <h3 className="text-[0.95rem] font-bold text-ink">
          {activeTab === 'faqs' ? '🎓 FAQs List' : '📖 Resources Directory'}
          <span className="text-[0.78rem] text-ink-muted font-normal ml-2">
            ({activeTab === 'faqs' ? filteredFaqs.length : filteredResources.length} entries)
          </span>
        </h3>
        <div className="relative">
          <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-muted pointer-events-none" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder={`Search ${activeTab}...`}
            className="input pl-9 w-60 text-[0.8rem] py-2"
          />
        </div>
      </div>

      {/* Main Content */}
      {loading ? (
        <Spinner />
      ) : activeTab === 'faqs' ? (
        filteredFaqs.length === 0 ? (
          <EmptyState icon="❓" message="No FAQs found. Add one or seed defaults." />
        ) : (
          <div className="space-y-4">
            {filteredFaqs.map((faq) => (
              <div key={faq.id} className="card p-5 flex flex-col gap-3 group relative">
                {/* Header info */}
                <div className="flex items-center gap-2">
                  <span className="text-[0.68rem] font-bold uppercase tracking-widest text-ink-muted bg-gb-surface px-2.5 py-1 rounded">
                    Category: {faq.category}
                  </span>
                  <span className={`text-[0.65rem] font-bold px-2 py-0.5 rounded border
                    ${faq.is_active ? 'bg-eco/10 text-eco border-eco/20' : 'bg-red-500/10 text-red-400 border-red-500/20'}`}>
                    {faq.is_active ? 'Active' : 'Inactive'}
                  </span>
                </div>

                {/* Question & Answer Content */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {/* English */}
                  <div className="space-y-1">
                    <p className="text-[0.86rem] font-bold text-ink">Q: {faq.question_en}</p>
                    <p className="text-[0.8rem] text-ink-sub pl-4">A: {faq.answer_en}</p>
                  </div>
                  {/* Urdu */}
                  <div className="space-y-1 text-right" dir="rtl">
                    <p className="text-[0.86rem] font-bold text-ink">سوال: {faq.question_ur}</p>
                    <p className="text-[0.8rem] text-ink-sub pr-4">جواب: {faq.answer_ur}</p>
                  </div>
                </div>

                {/* Actions row */}
                <div className="flex gap-2 justify-end border-t border-gb-border pt-3 mt-1">
                  <button onClick={() => handleOpenFaqModal(faq)} className="btn btn-ghost btn-sm gap-1 text-[0.74rem]">
                    <Pencil size={12} /> Edit
                  </button>
                  <button onClick={() => handleDeleteFaq(faq.id)} className="btn btn-ghost btn-sm gap-1 text-[0.74rem] text-red-400 hover:text-red-500">
                    <Trash2 size={12} /> Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )
      ) : filteredResources.length === 0 ? (
        <EmptyState icon="📖" message="No resources found. Add a new resource." />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
          {filteredResources.map((res) => (
            <div key={res.id} className="card p-5 flex flex-col gap-3 group relative h-60">
              {/* Badge & Active State */}
              <div className="flex items-center justify-between">
                <span className="text-[0.68rem] font-bold uppercase tracking-widest text-ink-muted bg-gb-surface px-2.5 py-1 rounded">
                  {res.category}
                </span>
                <span className={`text-[0.65rem] font-bold px-2 py-0.5 rounded border
                  ${res.is_active ? 'bg-eco/10 text-eco border-eco/20' : 'bg-red-500/10 text-red-400 border-red-500/20'}`}>
                  {res.is_active ? 'Active' : 'Inactive'}
                </span>
              </div>

              {/* Title & Description */}
              <div className="flex gap-3 mt-1">
                <div className="w-10 h-10 rounded-xl bg-gb-surface flex items-center justify-center text-xl flex-shrink-0">
                  {res.icon || '🔗'}
                </div>
                <div className="min-w-0">
                  <h4 className="text-[0.88rem] font-bold text-ink leading-tight truncate" title={res.title}>
                    {res.title}
                  </h4>
                  <a
                    href={res.url}
                    target="_blank"
                    rel="noreferrer"
                    className="text-[0.72rem] text-eco hover:underline flex items-center gap-1 mt-0.5 truncate"
                  >
                    {res.url} <ExternalLink size={10} />
                  </a>
                </div>
              </div>

              <p className="text-[0.78rem] text-ink-muted line-clamp-3 leading-relaxed">
                {res.description || 'No description provided.'}
              </p>

              {/* Edit/Delete Actions */}
              <div className="flex gap-2 mt-auto pt-3 border-t border-gb-border">
                <button onClick={() => handleOpenResourceModal(res)} className="btn btn-ghost btn-sm flex-1 justify-center gap-1 text-[0.74rem]">
                  <Pencil size={12} /> Edit
                </button>
                <button onClick={() => handleDeleteResource(res.id)} className="btn btn-ghost btn-sm flex-1 justify-center gap-1 text-[0.74rem] text-red-400 hover:text-red-500">
                  <Trash2 size={12} /> Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* FAQ Modal */}
      <Modal open={faqModal} onClose={() => setFaqModal(false)} title={editFaq ? 'Edit FAQ' : 'Add New FAQ'} width="max-w-xl">
        <form onSubmit={handleSaveFaq} className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Category</label>
              <select
                value={faqForm.category}
                onChange={e => setFaqForm({ ...faqForm, category: e.target.value })}
                className="input text-[0.82rem] py-2"
              >
                {FAQ_CATEGORIES.map(cat => <option key={cat} value={cat}>{cat.toUpperCase()}</option>)}
              </select>
            </div>
            <div className="flex items-center pt-5">
              <input
                type="checkbox"
                id="faq_is_active"
                checked={faqForm.is_active}
                onChange={e => setFaqForm({ ...faqForm, is_active: e.target.checked })}
                className="w-4 h-4 mr-2"
              />
              <label htmlFor="faq_is_active" className="text-[0.82rem] text-ink-sub">Active / Visible</label>
            </div>
          </div>

          <div>
            <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Question (English)</label>
            <input
              required
              value={faqForm.question_en}
              onChange={e => setFaqForm({ ...faqForm, question_en: e.target.value })}
              className="input text-[0.82rem] py-2"
              placeholder="e.g. How does waste sorting work?"
            />
          </div>

          <div>
            <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Question (اردو)</label>
            <input
              required
              value={faqForm.question_ur}
              onChange={e => setFaqForm({ ...faqForm, question_ur: e.target.value })}
              className="input text-[0.82rem] py-2 text-right"
              dir="rtl"
              placeholder="سوال لکھیں..."
            />
          </div>

          <div>
            <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Answer (English)</label>
            <textarea
              required
              value={faqForm.answer_en}
              onChange={e => setFaqForm({ ...faqForm, answer_en: e.target.value })}
              rows={4}
              className="input text-[0.82rem] py-2 resize-none"
              placeholder="Enter explanation..."
            />
          </div>

          <div>
            <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Answer (اردو)</label>
            <textarea
              required
              value={faqForm.answer_ur}
              onChange={e => setFaqForm({ ...faqForm, answer_ur: e.target.value })}
              rows={4}
              className="input text-[0.82rem] py-2 resize-none text-right"
              dir="rtl"
              placeholder="جواب لکھیں..."
            />
          </div>

          <div className="flex gap-2 justify-end pt-3 border-t border-gb-border">
            <button type="button" className="btn btn-ghost btn-sm" onClick={() => setFaqModal(false)}>Cancel</button>
            <button type="submit" className="btn btn-primary btn-sm gap-1.5" disabled={saving}>
              {saving ? <RefreshCw size={12} className="animate-spin" /> : <Save size={12} />}
              {editFaq ? 'Update FAQ' : 'Save FAQ'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Resource Modal */}
      <Modal open={resourceModal} onClose={() => setResourceModal(false)} title={editResource ? 'Edit Resource' : 'Add New Resource'} width="max-w-xl">
        <form onSubmit={handleSaveResource} className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Category</label>
              <select
                value={resourceForm.category}
                onChange={e => setResourceForm({ ...resourceForm, category: e.target.value })}
                className="input text-[0.82rem] py-2"
              >
                {RESOURCE_CATEGORIES.map(cat => <option key={cat} value={cat}>{cat}</option>)}
              </select>
            </div>
            <div className="flex items-center pt-5">
              <input
                type="checkbox"
                id="res_is_active"
                checked={resourceForm.is_active}
                onChange={e => setResourceForm({ ...resourceForm, is_active: e.target.checked })}
                className="w-4 h-4 mr-2"
              />
              <label htmlFor="res_is_active" className="text-[0.82rem] text-ink-sub">Active / Visible</label>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div className="col-span-2">
              <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Title</label>
              <input
                required
                value={resourceForm.title}
                onChange={e => setResourceForm({ ...resourceForm, title: e.target.value })}
                className="input text-[0.82rem] py-2"
                placeholder="e.g. EPA Recycling Guide"
              />
            </div>
            <div>
              <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Icon (emoji)</label>
              <input
                value={resourceForm.icon}
                onChange={e => setResourceForm({ ...resourceForm, icon: e.target.value })}
                className="input text-[0.82rem] py-2"
                placeholder="e.g. 📖"
              />
            </div>
          </div>

          <div>
            <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Website URL</label>
            <input
              required
              type="url"
              value={resourceForm.url}
              onChange={e => setResourceForm({ ...resourceForm, url: e.target.value })}
              className="input text-[0.82rem] py-2"
              placeholder="e.g. https://www.epa.gov/recycle"
            />
          </div>

          <div>
            <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Description</label>
            <textarea
              value={resourceForm.description}
              onChange={e => setResourceForm({ ...resourceForm, description: e.target.value })}
              rows={4}
              className="input text-[0.82rem] py-2 resize-none"
              placeholder="Enter brief description of this resource..."
            />
          </div>

          <div className="flex gap-2 justify-end pt-3 border-t border-gb-border">
            <button type="button" className="btn btn-ghost btn-sm" onClick={() => setResourceModal(false)}>Cancel</button>
            <button type="submit" className="btn btn-primary btn-sm gap-1.5" disabled={saving}>
              {saving ? <RefreshCw size={12} className="animate-spin" /> : <Save size={12} />}
              {editResource ? 'Update Resource' : 'Save Resource'}
            </button>
          </div>
        </form>
      </Modal>
    </Layout>
  )
}
