import React, { useEffect, useState } from 'react'
import { Plus, BookOpen, Edit, Trash2, Globe, Check, X, AlertCircle, Upload, Film } from 'lucide-react'
import Layout from '../components/layout/Layout'
import { PageHeader, DataTable, Modal, Spinner } from '../components/ui/index.jsx'
import { storiesApi } from '../api'

export default function ImpactStories() {
  const [stories, setStories] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  // Modal State
  const [modalOpen, setModalOpen] = useState(false)
  const [modalLoading, setModalLoading] = useState(false)
  const [modalError, setModalError] = useState(null)
  const [editingStory, setEditingStory] = useState(null)

  // Form Fields
  const [title, setTitle] = useState('')
  const [imageUrl, setImageUrl] = useState('')
  const [videoUrl, setVideoUrl] = useState('')
  const [description, setDescription] = useState('')
  const [isActive, setIsActive] = useState(true)
  const [uploading, setUploading] = useState(false)

  const fetchStories = async () => {
    setLoading(true)
    setError(null)
    try {
      const { data } = await storiesApi.getAll()
      setStories(data.data || [])
    } catch (err) {
      setError(err.message || 'Failed to fetch impact stories')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchStories()
  }, [])

  const handleOpenCreate = () => {
    setEditingStory(null)
    setTitle('')
    setImageUrl('')
    setVideoUrl('')
    setDescription('')
    setIsActive(true)
    setModalError(null)
    setModalOpen(true)
  }

  const handleOpenEdit = (story) => {
    setEditingStory(story)
    setTitle(story.title)
    setImageUrl(story.image_url)
    setVideoUrl(story.video_url || '')
    setDescription(story.description || '')
    setIsActive(story.is_active)
    setModalError(null)
    setModalOpen(true)
  }

  const handleImageUpload = async (e) => {
    const file = e.target.files[0]
    if (!file) return

    setUploading(true)
    setModalError(null)

    const formData = new FormData()
    formData.append('file', file)

    try {
      const { data } = await storiesApi.uploadImage(formData)
      setImageUrl(data.secure_url)
    } catch (err) {
      setModalError(err.response?.data?.detail || err.message || 'Image upload failed')
    } finally {
      setUploading(false)
    }
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!imageUrl) {
      setModalError('Please upload a cover image first.')
      return
    }

    setModalLoading(true)
    setModalError(null)

    const payload = {
      title,
      image_url: imageUrl,
      video_url: videoUrl || null,
      description,
      is_active: isActive
    }

    try {
      if (editingStory) {
        await storiesApi.update(editingStory.id, payload)
      } else {
        await storiesApi.create(payload)
      }
      setModalOpen(false)
      fetchStories()
    } catch (err) {
      setModalError(err.response?.data?.detail || err.message || 'Failed to save story')
    } finally {
      setModalLoading(false)
    }
  }

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this story?')) return
    try {
      await storiesApi.delete(id)
      fetchStories()
    } catch (err) {
      alert(err.message || 'Failed to delete story')
    }
  }

  const columns = [
    {
      key: 'image_url',
      label: 'Cover',
      render: (val) => (
        <img 
          src={val} 
          alt="Cover" 
          className="w-14 h-10 object-cover rounded-lg border border-gb-border bg-ink-muted/10" 
        />
      )
    },
    {
      key: 'title',
      label: 'Story Title',
      render: (val) => <span className="font-semibold text-ink text-sm">{val}</span>
    },
    {
      key: 'video_url',
      label: 'Web Link / Video URL',
      render: (val) => val ? (
        <a 
          href={val} 
          target="_blank" 
          rel="noopener noreferrer" 
          className="flex items-center gap-1.5 text-xs text-eco hover:underline"
        >
          <Globe size={12} />
          <span className="max-w-[200px] truncate">{val}</span>
        </a>
      ) : <span className="text-xs text-ink-sub">None</span>
    },
    {
      key: 'is_active',
      label: 'Status',
      render: (val) => (
        <span className={`badge ${val ? 'bg-eco-muted text-eco' : 'bg-red-500/10 text-red-400'}`}>
          {val ? 'Active' : 'Inactive'}
        </span>
      )
    },
    {
      key: 'id',
      label: 'Actions',
      render: (_, row) => (
        <div className="flex items-center gap-2">
          <button 
            onClick={() => handleOpenEdit(row)} 
            className="p-1.5 rounded-lg text-ink-sub hover:text-ink hover:bg-gb-border cursor-pointer transition-colors"
            title="Edit"
          >
            <Edit size={14} />
          </button>
          <button 
            onClick={() => handleDelete(row.id)} 
            className="p-1.5 rounded-lg text-ink-sub hover:text-red-400 hover:bg-red-500/10 cursor-pointer transition-colors"
            title="Delete"
          >
            <Trash2 size={14} />
          </button>
        </div>
      )
    }
  ]

  const headerAction = (
    <button
      onClick={handleOpenCreate}
      className="btn btn-primary flex items-center gap-2 cursor-pointer"
    >
      <Plus size={16} />
      <span>New Story</span>
    </button>
  )

  return (
    <Layout title="Impact Stories">
      <PageHeader 
        title="Stories of Impact" 
        subtitle="Manage dynamic stories and initiatives showcased in the mobile app's Impact screen." 
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
            data={stories} 
            pageSize={10} 
            emptyIcon="📖" 
            emptyMsg="No impact stories found." 
          />
        )}
      </div>

      {/* Story Form Modal */}
      <Modal 
        open={modalOpen} 
        onClose={() => setModalOpen(false)} 
        title={editingStory ? "Edit Story of Impact" : "Add Story of Impact"}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          {modalError && (
            <div className="flex items-center gap-2 bg-red-500/10 border border-red-500/20 rounded-lg px-4 py-3 text-red-400 text-sm">
              <AlertCircle size={16} />
              <span>{modalError}</span>
            </div>
          )}

          <div className="space-y-1.5">
            <label className="text-[0.76rem] font-semibold text-ink-sub">Story Title</label>
            <input
              type="text"
              value={title}
              onChange={e => setTitle(e.target.value)}
              placeholder="e.g., Beach Cleanup in Karachi"
              className="input text-sm"
              required
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-[0.76rem] font-semibold text-ink-sub">Cover Image</label>
            <div className="flex items-center gap-4">
              <div className="relative flex-1">
                <input
                  type="text"
                  value={imageUrl}
                  onChange={e => setImageUrl(e.target.value)}
                  placeholder="https://example.com/image.jpg (automatically set on upload)"
                  className="input pr-10 text-xs"
                  required
                  readOnly
                />
                {imageUrl && (
                  <button 
                    type="button" 
                    onClick={() => setImageUrl('')}
                    className="absolute right-2.5 top-1/2 -translate-y-1/2 text-ink-sub hover:text-ink cursor-pointer"
                  >
                    <X size={14} />
                  </button>
                )}
              </div>
              <label className="btn btn-ghost flex items-center gap-2 px-4 py-2 border border-dashed border-gb-border hover:border-eco cursor-pointer">
                <Upload size={14} />
                <span className="text-xs">{uploading ? 'Uploading...' : 'Upload file'}</span>
                <input 
                  type="file" 
                  accept="image/*" 
                  onChange={handleImageUpload} 
                  className="hidden" 
                  disabled={uploading}
                />
              </label>
            </div>

            {imageUrl && (
              <div className="mt-2.5 relative w-32 h-20 rounded-lg overflow-hidden border border-gb-border bg-ink-muted/10">
                <img src={imageUrl} alt="Upload preview" className="w-full h-full object-cover" />
              </div>
            )}
          </div>

          <div className="space-y-1.5">
            <label className="text-[0.76rem] font-semibold text-ink-sub flex items-center gap-1.5">
              <Film size={12} />
              <span>Video Link / Web Article URL (Optional)</span>
            </label>
            <input
              type="url"
              value={videoUrl}
              onChange={e => setVideoUrl(e.target.value)}
              placeholder="e.g., https://www.youtube.com/watch?v=..."
              className="input text-sm"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-[0.76rem] font-semibold text-ink-sub">Description</label>
            <textarea
              value={description}
              onChange={e => setDescription(e.target.value)}
              placeholder="Detailed description of the impact story..."
              className="input text-sm min-h-[100px] py-2 resize-y"
              required
            />
          </div>

          <div className="flex items-center gap-2 py-1.5">
            <input
              type="checkbox"
              id="isActive"
              checked={isActive}
              onChange={e => setIsActive(e.target.checked)}
              className="w-4 h-4 rounded text-eco border-gb-border accent-eco cursor-pointer"
            />
            <label htmlFor="isActive" className="text-xs font-medium text-ink cursor-pointer">
              Active (Visible in mobile app)
            </label>
          </div>

          <div className="flex justify-end gap-2.5 pt-3.5 border-t border-gb-border">
            <button
              type="button"
              onClick={() => setModalOpen(false)}
              className="btn btn-ghost px-4 py-2 cursor-pointer text-ink-sub"
              disabled={modalLoading || uploading}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="btn btn-primary flex items-center gap-2 px-4 py-2 cursor-pointer"
              disabled={modalLoading || uploading}
            >
              {modalLoading ? 'Saving...' : 'Save Story'}
            </button>
          </div>
        </form>
      </Modal>
    </Layout>
  )
}
