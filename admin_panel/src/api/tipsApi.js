/**
 * GreenBin Genius – Tips API Client
 * Calls the FastAPI /api/tips endpoints.
 */
import api from './axiosClient'

export const tipsApi = {
  /** List all eco tips (paginated) */
  getAll: (params) => api.get('/tips', { params }),

  /** Get full disposal guidance for a specific waste category */
  getByCategory: (category) => api.get(`/tips/category/${category}`),

  /** Create a new tip (admin only) */
  create: (data) => api.post('/tips', data),

  /** Update an existing tip (admin only) */
  update: (id, data) => api.put(`/tips/${id}`, data),

  /** Delete a tip (admin only) */
  delete: (id) => api.delete(`/tips/${id}`),

  /** Seed tips from hardcoded defaults (admin only) */
  seed: () => api.post('/tips/seed'),

  /** Submit a user correction/feedback for a classification */
  submitFeedback: (classificationId, correctedCategory) =>
    api.post('/tips/feedback', {
      classification_id:  classificationId,
      corrected_category: correctedCategory,
    }),
}
