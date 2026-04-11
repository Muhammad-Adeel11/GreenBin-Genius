import { create } from 'zustand'
import { authApi } from '../api'

const useAuthStore = create((set, get) => ({
  user:    null,
  token:   localStorage.getItem('access_token') || null,
  loading: false,
  error:   null,

  login: async (email, password) => {
    set({ loading: true, error: null })
    try {
      const { data } = await authApi.login(email, password)
      if (!['ADMIN', 'MODERATOR'].includes(data.user?.role)) {
        throw new Error('Access denied. Admin privileges required.')
      }
      localStorage.setItem('access_token',  data.access_token)
      localStorage.setItem('refresh_token', data.refresh_token)
      set({ user: data.user, token: data.access_token, loading: false })
      return { ok: true }
    } catch (err) {
      const msg = err.message || err.response?.data?.detail || 'Login failed'
      set({ loading: false, error: msg })
      return { ok: false, error: msg }
    }
  },

  logout: () => {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    set({ user: null, token: null })
  },

  fetchMe: async () => {
    try {
      const { data } = await authApi.getMe()
      set({ user: data })
    } catch {
      get().logout()
    }
  },

  clearError: () => set({ error: null }),
}))

export default useAuthStore