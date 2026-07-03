import React, { useEffect, useState } from 'react'
import { Plus, Target, Edit, Trash2, ToggleLeft, ToggleRight, CheckCircle, Clock, Users, Trophy, Loader2 } from 'lucide-react'
import Layout from '../components/layout/Layout'
import { PageHeader, DataTable, Modal, Spinner } from '../components/ui/index.jsx'
import { tasksApi, googleTranslateApi } from '../api'

const TASK_TYPES = [
  { value: 'scan_count',    label: 'Total Scan Count (any category)' },
  { value: 'category_scan', label: 'Category-Specific Scans' },
  { value: 'streak',        label: 'Daily Scan Streak' },
  { value: 'manual',        label: 'Manual (admin marks done)' },
]

const CATEGORIES = ['plastic','glass','metal','e-waste','textile','wood','food_waste','not_food_waste']

const DIFFICULTIES = ['easy', 'medium', 'hard']

const BADGE_ICONS = ['🌿','♻️','🌍','🏆','⭐','💚','🎯','🔋','🌱','🗑️']

const diffColor = { easy: 'bg-green-100 text-green-700', medium: 'bg-yellow-100 text-yellow-700', hard: 'bg-red-100 text-red-700' }

export default function EcoTasks() {
  const [tasks, setTasks]       = useState([])
  const [loading, setLoading]   = useState(true)
  const [error, setError]       = useState(null)
  const [modalOpen, setModalOpen]       = useState(false)
  const [modalLoading, setModalLoading] = useState(false)
  const [modalError, setModalError]     = useState(null)
  const [editingTask, setEditingTask]   = useState(null)

  // Form state
  const [title, setTitle]               = useState('')
  const [titleUr, setTitleUr]           = useState('')
  const [description, setDescription]   = useState('')
  const [descriptionUr, setDescriptionUr] = useState('')
  const [taskType, setTaskType]         = useState('scan_count')
  const [targetCategory, setTargetCategory] = useState('')
  const [targetCount, setTargetCount]   = useState(10)
  const [rewardPoints, setRewardPoints] = useState(100)
  const [badgeIcon, setBadgeIcon]       = useState('🌿')
  const [difficulty, setDifficulty]     = useState('medium')
  const [deadline, setDeadline]         = useState('')
  const [isActive, setIsActive]         = useState(true)

  const fetchTasks = async () => {
    setLoading(true); setError(null)
    try {
      const { data } = await tasksApi.adminGetAll()
      setTasks(data.data || [])
    } catch (err) {
      setError(err.message || 'Failed to load tasks')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { fetchTasks() }, [])

  const resetForm = () => {
    setTitle(''); setTitleUr(''); setDescription(''); setDescriptionUr('')
    setTaskType('scan_count'); setTargetCategory(''); setTargetCount(10)
    setRewardPoints(100); setBadgeIcon('🌿'); setDifficulty('medium')
    setDeadline(''); setIsActive(true); setModalError(null)
  }

  const handleOpenCreate = () => { setEditingTask(null); resetForm(); setModalOpen(true) }

  const handleOpenEdit = (task) => {
    setEditingTask(task)
    setTitle(task.title || '')
    setTitleUr(task.title_ur || '')
    setDescription(task.description || '')
    setDescriptionUr(task.description_ur || '')
    setTaskType(task.type || 'scan_count')
    setTargetCategory(task.target_category || '')
    setTargetCount(task.target_count || 10)
    setRewardPoints(task.reward_points || 100)
    setBadgeIcon(task.badge_icon || '🌿')
    setDifficulty(task.difficulty || 'medium')
    setDeadline(task.deadline ? task.deadline.slice(0, 10) : '')
    setIsActive(task.is_active !== false)
    setModalError(null)
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    if (!title || !taskType || !targetCount || !rewardPoints) {
      setModalError('Title, type, target count and reward points are required.'); return
    }
    setModalLoading(true); setModalError(null)
    const body = {
      title, title_ur: titleUr, description, description_ur: descriptionUr,
      type: taskType, target_category: targetCategory || null,
      target_count: Number(targetCount), reward_points: Number(rewardPoints),
      badge_icon: badgeIcon, difficulty, is_active: isActive,
      deadline: deadline ? new Date(deadline).toISOString() : null,
    }
    try {
      if (editingTask) {
        await tasksApi.update(editingTask.id, body)
      } else {
        await tasksApi.create(body)
      }
      setModalOpen(false)
      fetchTasks()
    } catch (err) {
      setModalError(err.response?.data?.detail || err.message || 'Save failed')
    } finally {
      setModalLoading(false)
    }
  }

  const handleToggle = async (task) => {
    try {
      await tasksApi.toggle(task.id)
      fetchTasks()
    } catch (err) {
      alert(err.message || 'Toggle failed')
    }
  }

  const handleDelete = async (task) => {
    if (!confirm(`Delete task "${task.title}"? This will also remove all user enrollments.`)) return
    try {
      await tasksApi.delete(task.id)
      fetchTasks()
    } catch (err) {
      alert(err.message || 'Delete failed')
    }
  }

  const columns = [
    {
      key: 'task',
      label: 'Task',
      render: (_, t) => (
        <div className="flex items-center gap-3">
          <span className="text-2xl">{t.badge_icon || '🌿'}</span>
          <div>
            <p className="font-semibold text-gray-900 text-sm">{t.title}</p>
            {t.title_ur && <p className="text-xs text-gray-400 mt-0.5" dir="rtl">{t.title_ur}</p>}
          </div>
        </div>
      ),
    },
    {
      key: 'type',
      label: 'Type',
      render: (v) => (
        <span className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full font-medium">
          {TASK_TYPES.find(t => t.value === v)?.label.split('(')[0].trim() || v}
        </span>
      ),
    },
    {
      key: 'difficulty',
      label: 'Difficulty',
      render: (v) => (
        <span className={`text-xs px-2 py-1 rounded-full font-semibold capitalize ${diffColor[v] || ''}`}>{v}</span>
      ),
    },
    {
      key: 'target_count',
      label: 'Target',
      render: (v, t) => (
        <div className="text-sm">
          <span className="font-bold text-gray-700">{v}</span>
          {t.target_category && <span className="text-xs text-gray-400 ml-1">({t.target_category})</span>}
        </div>
      ),
    },
    {
      key: 'reward_points',
      label: 'Reward',
      render: (v) => (
        <div className="flex items-center gap-1">
          <Trophy className="w-3 h-3 text-amber-500" />
          <span className="text-sm font-bold text-amber-600">{v} pts</span>
        </div>
      ),
    },
    {
      key: 'enrolled_count',
      label: 'Enrolled',
      render: (v) => (
        <div className="flex items-center gap-1 text-sm text-gray-600">
          <Users className="w-3.5 h-3.5" />{v || 0}
        </div>
      ),
    },
    {
      key: 'completed_count',
      label: 'Completed',
      render: (v) => (
        <div className="flex items-center gap-1 text-sm text-green-600 font-semibold">
          <CheckCircle className="w-3.5 h-3.5" />{v || 0}
        </div>
      ),
    },
    {
      key: 'deadline',
      label: 'Deadline',
      render: (v) => v ? (
        <div className="flex items-center gap-1 text-xs text-gray-500">
          <Clock className="w-3 h-3" />{new Date(v).toLocaleDateString()}
        </div>
      ) : <span className="text-xs text-gray-300">No deadline</span>,
    },
    {
      key: 'is_active',
      label: 'Status',
      render: (v, t) => (
        <button onClick={() => handleToggle(t)} className="flex items-center gap-1">
          {v
            ? <><ToggleRight className="w-5 h-5 text-green-500" /><span className="text-xs text-green-600 font-medium">Active</span></>
            : <><ToggleLeft  className="w-5 h-5 text-gray-400" /><span className="text-xs text-gray-400">Inactive</span></>
          }
        </button>
      ),
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (_, t) => (
        <div className="flex gap-2">
          <button onClick={() => handleOpenEdit(t)} className="p-1.5 rounded-lg hover:bg-blue-50 text-blue-600" title="Edit">
            <Edit className="w-4 h-4" />
          </button>
          <button onClick={() => handleDelete(t)} className="p-1.5 rounded-lg hover:bg-red-50 text-red-500" title="Delete">
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      ),
    },
  ]

  return (
    <Layout title="Eco Tasks">
      <PageHeader
        title="Eco Tasks"
        subtitle="Create and manage challenges for GreenBin users"
        icon={<Target className="w-6 h-6" />}
        action={
          <button onClick={handleOpenCreate}
            className="flex items-center gap-2 bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-xl text-sm font-semibold transition-colors">
            <Plus className="w-4 h-4" /> New Task
          </button>
        }
      />

      {/* Stats Row */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        {[
          { label: 'Total Tasks', value: tasks.length, icon: Target, color: 'blue' },
          { label: 'Active',      value: tasks.filter(t => t.is_active).length, icon: ToggleRight, color: 'green' },
          { label: 'Inactive',    value: tasks.filter(t => !t.is_active).length, icon: ToggleLeft,  color: 'gray' },
        ].map(s => (
          <div key={s.label} className="bg-white rounded-2xl p-4 border border-gray-100 shadow-sm flex items-center gap-3">
            <div className={`p-2.5 rounded-xl bg-${s.color}-50`}>
              <s.icon className={`w-5 h-5 text-${s.color}-600`} />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-800">{s.value}</p>
              <p className="text-xs text-gray-500">{s.label}</p>
            </div>
          </div>
        ))}
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><Spinner /></div>
      ) : error ? (
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl p-4 text-sm">{error}</div>
      ) : (
        <DataTable columns={columns} data={tasks} emptyMessage="No tasks yet. Create your first eco challenge!" />
      )}

      {/* Create / Edit Modal */}
      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editingTask ? 'Edit Task' : 'Create New Eco Task'}
      >
        <div className="flex flex-col max-h-[75vh]">
          {/* Scrollable Form Body */}
          <div className="space-y-4 overflow-y-auto pr-1 pb-4 flex-1">
            {modalError && (
              <div className="bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl p-3">{modalError}</div>
            )}

            {/* Badge + Title */}
            <div className="flex gap-3">
              <div className="w-20">
                <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Icon</label>
                <select value={badgeIcon} onChange={e => setBadgeIcon(e.target.value)}
                  className="input text-center text-xl p-1.5">
                  {BADGE_ICONS.map(i => <option key={i} value={i} className="bg-gb-card text-ink">{i}</option>)}
                </select>
              </div>
              <div className="flex-1">
                <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Title (English) *</label>
                <input value={title} onChange={e => setTitle(e.target.value)}
                  placeholder="e.g. Plastic Free Week"
                  className="input text-[0.82rem] py-2" />
              </div>
            </div>

            <div>
              <div className="flex items-center justify-between mb-1">
                <label className="text-[0.74rem] font-semibold text-ink-sub">Title (Urdu)</label>
                <button
                  type="button"
                  onClick={async () => {
                    const translated = await googleTranslateApi.translateToUrdu(title)
                    setTitleUr(translated)
                  }}
                  className="text-[0.7rem] text-eco font-bold hover:underline cursor-pointer bg-transparent border-none"
                >
                  ✨ Auto-Translate from English
                </button>
              </div>
              <input value={titleUr} onChange={e => setTitleUr(e.target.value)}
                placeholder="اردو عنوان" dir="rtl"
                className="input text-[0.82rem] py-2 text-right" />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Task Type *</label>
                <select value={taskType} onChange={e => setTaskType(e.target.value)}
                  className="input text-[0.82rem] py-2">
                  {TASK_TYPES.map(t => <option key={t.value} value={t.value} className="bg-gb-card text-ink">{t.label}</option>)}
                </select>
              </div>
              <div>
                <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Difficulty</label>
                <select value={difficulty} onChange={e => setDifficulty(e.target.value)}
                  className="input text-[0.82rem] py-2 capitalize">
                  {DIFFICULTIES.map(d => <option key={d} value={d} className="bg-gb-card text-ink capitalize">{d}</option>)}
                </select>
              </div>
            </div>

            {taskType === 'category_scan' && (
              <div>
                <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Target Category *</label>
                <select value={targetCategory} onChange={e => setTargetCategory(e.target.value)}
                  className="input text-[0.82rem] py-2">
                  <option value="" className="bg-gb-card text-ink-muted">Select category…</option>
                  {CATEGORIES.map(c => <option key={c} value={c} className="bg-gb-card text-ink">{c.replace('_', ' ')}</option>)}
                </select>
              </div>
            )}

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Target Count *</label>
                <input type="number" min="1" value={targetCount} onChange={e => setTargetCount(e.target.value)}
                  className="input text-[0.82rem] py-2" />
              </div>
              <div>
                <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Reward Points *</label>
                <input type="number" min="1" value={rewardPoints} onChange={e => setRewardPoints(e.target.value)}
                  className="input text-[0.82rem] py-2" />
              </div>
            </div>

            <div>
              <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Deadline (optional)</label>
              <input type="date" value={deadline} onChange={e => setDeadline(e.target.value)}
                min={new Date().toISOString().slice(0, 10)}
                className="input text-[0.82rem] py-2" />
            </div>

            <div>
              <label className="text-[0.74rem] font-semibold text-ink-sub block mb-1">Description (English)</label>
              <textarea value={description} onChange={e => setDescription(e.target.value)} rows={2}
                placeholder="What should users do to complete this task?"
                className="input text-[0.82rem] py-2 resize-none" />
            </div>

            <div>
              <div className="flex items-center justify-between mb-1">
                <label className="text-[0.74rem] font-semibold text-ink-sub">Description (Urdu)</label>
                <button
                  type="button"
                  onClick={async () => {
                    const translated = await googleTranslateApi.translateToUrdu(description)
                    setDescriptionUr(translated)
                  }}
                  className="text-[0.7rem] text-eco font-bold hover:underline cursor-pointer bg-transparent border-none"
                >
                  ✨ Auto-Translate from English
                </button>
              </div>
              <textarea value={descriptionUr} onChange={e => setDescriptionUr(e.target.value)} rows={2}
                dir="rtl" placeholder="اردو تفصیل"
                className="input text-[0.82rem] py-2 resize-none text-right" />
            </div>

            <div className="flex items-center gap-3 p-3 bg-gb-surface border border-gb-border rounded-xl">
              <button onClick={() => setIsActive(!isActive)}
                className={`relative w-11 h-6 rounded-full transition-colors ${isActive ? 'bg-green-500' : 'bg-gray-600'}`}>
                <span className={`absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${isActive ? 'translate-x-5' : ''}`} />
              </button>
              <span className="text-sm font-medium text-ink-sub">{isActive ? 'Active (visible to users)' : 'Inactive (hidden from users)'}</span>
            </div>
          </div>

          {/* Sticky Footer */}
          <div className="flex gap-2 justify-end pt-4 border-t border-gb-border mt-2">
            <button onClick={() => setModalOpen(false)}
              className="btn btn-ghost btn-sm">
              Cancel
            </button>
            <button onClick={handleSubmit} disabled={modalLoading}
              className="btn btn-primary btn-sm flex items-center gap-1.5">
              {modalLoading && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
              {editingTask ? 'Save Changes' : 'Create Task'}
            </button>
          </div>
        </div>
      </Modal>
    </Layout>
  )
}
