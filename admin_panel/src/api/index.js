import api from './axiosClient'

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

export const authApi = {
  login:        (email, password) => api.post('/auth/admin-login', { email, password }),
  googleUrl:    ()                => `${BASE_URL}/api/v1/auth/google`,
  refresh:      (token)           => api.post('/auth/refresh', { refresh_token: token }),
  getMe:        ()                => api.get('/auth/me'),
}

export const classificationApi = {
  getHistory:   (params)          => api.get('/admin/classifications', { params }),
  getDetail:    (id)              => api.get(`/classify/${id}`),
  addFeedback:  (id, cat)         => api.post(`/classify/${id}/feedback`, { corrected_category: cat }),
  getModelInfo: ()                => api.get('/classify/model/info'),
}

export const analyticsApi = {
  getDashboard:          (params) => api.get('/analytics/dashboard', { params }),
  getLowConfidence:      (params) => api.get('/analytics/low-confidence', { params }),
  getCorrections:        (params) => api.get('/analytics/corrections', { params }),
  logModelMetrics:       (data)   => api.post('/analytics/model-metrics', data),
  exportClassifications: (params) => api.get('/analytics/export/classifications', { params, responseType: 'blob' }),
  exportUsers:           ()       => api.get('/analytics/export/users', { responseType: 'blob' }),
}

export const userApi = {
  getAll:       (params)          => api.get('/admin/users', { params }),
  search:       (q, params)       => api.get('/admin/users/search', { params: { q, ...params } }),
  getDetail:    (id)              => api.get(`/admin/users/${id}`),
  updateRole:   (id, role)        => api.patch(`/admin/users/${id}/role`, { role }),
  suspend:      (id, suspend, reason) => api.patch(`/admin/users/${id}/suspend`, { suspend, reason }),
  delete:       (id)              => api.delete(`/admin/users/${id}`),
  getLeaderboard: (limit = 10)    => api.get('/leaderboard', { params: { limit } }),
}

export const tipsApi = {
  getAll:       (params)          => api.get('/tips', { params }),
  getByCategory:(cat)             => api.get(`/tips/category/${cat}`),
  getDisposal:  (cat, lang)       => api.get(`/tips/disposal/${cat}`, { params: { language: lang } }),
  create:       (data)            => api.post('/tips', data),
  update:       (id, data)        => api.put(`/tips/${id}`, data),
  delete:       (id)              => api.delete(`/tips/${id}`),
  seed:         ()                => api.post('/tips/seed'),
  submitFeedback: (classificationId, correctedCategory) =>
    api.post('/tips/feedback', { classification_id: classificationId, corrected_category: correctedCategory }),
}

export const faqsApi = {
  getAll:       (params)          => api.get('/faqs', { params }),
  getDetail:    (id)              => api.get(`/faqs/${id}`),
  create:       (data)            => api.post('/faqs', data),
  update:       (id, data)        => api.put(`/faqs/${id}`, data),
  delete:       (id)              => api.delete(`/faqs/${id}`),
  seed:         ()                => api.post('/faqs/seed'),
}

export const resourcesApi = {
  getAll:       (params)          => api.get('/resources', { params }),
  getDetail:    (id)              => api.get(`/resources/${id}`),
  create:       (data)            => api.post('/resources', data),
  update:       (id, data)        => api.put(`/resources/${id}`, data),
  delete:       (id)              => api.delete(`/resources/${id}`),
}

export const binsApi = {
  getNearby:    (params)          => api.get('/bins/nearby', { params }),
  getAll:       (params)          => api.get('/bins', { params }),
  getDetail:    (id)              => api.get(`/bins/${id}`),
  create:       (data)            => api.post('/bins', data),
  update:       (id, data)        => api.put(`/bins/${id}`, data),
  delete:       (id)              => api.delete(`/bins/${id}`),
}


export const notificationsApi = {
  getAll:         (params)        => api.get('/notifications', { params }),
  getUnreadCount: ()              => api.get('/notifications/unread-count'),
  markRead:       (id)            => api.patch(`/notifications/${id}/read`),
  markAllRead:    ()              => api.patch('/notifications/read-all'),
  getCampaigns:   (params)        => api.get('/notifications/campaigns', { params }),
  createCampaign: (data)          => api.post('/notifications/campaigns', data),
}

export const adminApi = {
  getSummary:     ()              => api.get('/admin/dashboard-summary'),
  getLogs:        (params)        => api.get('/admin/logs', { params }),
  getModelStatus: ()              => api.get('/admin/model/status'),
  reloadModels:   ()              => api.post('/admin/model/reload'),
}

export const storiesApi = {
  getAll:       (params)          => api.get('/stories', { params }),
  getDetail:    (id)              => api.get(`/stories/${id}`),
  create:       (data)            => api.post('/stories', data),
  update:       (id, data)        => api.put(`/stories/${id}`, data),
  delete:       (id)              => api.delete(`/stories/${id}`),
  uploadImage:  (formData)        => api.post('/stories/upload', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),
}

export const tasksApi = {
  getAll:       ()                => api.get('/tasks'),
  getMine:      ()                => api.get('/tasks/mine'),
  enroll:       (id)              => api.post(`/tasks/${id}/enroll`),
  getProgress:  (id)              => api.get(`/tasks/${id}/progress`),
  adminGetAll:  (params)          => api.get('/tasks/admin/all', { params }),
  create:       (data)            => api.post('/tasks', data),
  update:       (id, data)        => api.put(`/tasks/${id}`, data),
  toggle:       (id)              => api.patch(`/tasks/${id}/toggle`),
  delete:       (id)              => api.delete(`/tasks/${id}`),
}