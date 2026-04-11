import api from './axiosClient'

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

export const authApi = {
  login:        (email, password) => api.post('/auth/login', { email, password }),
  googleUrl:    ()                => `${BASE_URL}/api/v1/auth/google`,
  refresh:      (token)           => api.post('/auth/refresh', { refresh_token: token }),
  getMe:        ()                => api.get('/auth/me'),
}

export const classificationApi = {
  getHistory:   (params)          => api.get('/classify/history', { params }),
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
  getByCategory:(cat, params)     => api.get(`/tips/category/${cat}`, { params }),
  getDisposal:  (cat, lang)       => api.get(`/tips/disposal/${cat}`, { params: { language: lang } }),
  create:       (data)            => api.post('/tips', data),
  update:       (id, data)        => api.put(`/tips/${id}`, data),
  delete:       (id)              => api.delete(`/tips/${id}`),
}

export const binsApi = {
  getNearby:    (params)          => api.get('/bins/nearby', { params }),
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