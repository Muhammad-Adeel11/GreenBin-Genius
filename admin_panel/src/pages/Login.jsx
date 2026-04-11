import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Recycle, Mail, Lock, AlertCircle, Chrome } from 'lucide-react'
import useAuthStore from '../store/authStore'
import { authApi } from '../api'

export default function Login() {
  const [email,    setEmail]    = useState('')
  const [password, setPassword] = useState('')
  const { login, loading, error, clearError } = useAuthStore()
  const navigate = useNavigate()

  const handleSubmit = async (e) => {
    e.preventDefault()
    clearError()
    const { ok } = await login(email, password)
    if (ok) navigate('/')
  }

  return (
    <div className="min-h-screen bg-gb-base flex items-center justify-center relative overflow-hidden">

      {/* Grid background */}
      <div className="absolute inset-0 bg-grid-green bg-grid opacity-100 pointer-events-none" />

      {/* Glow blob */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-96 h-96 bg-eco/5 rounded-full blur-3xl pointer-events-none" />

      {/* Card */}
      <div className="relative w-full max-w-[400px] mx-4 bg-gb-card border border-gb-border rounded-xl2 p-9 shadow-modal animate-fade-up">

        {/* Logo */}
        <div className="flex items-center gap-3 mb-8">
          <div className="w-11 h-11 rounded-xl bg-eco-muted border border-eco-border flex items-center justify-center">
            <Recycle size={22} className="text-eco" />
          </div>
          <div>
            <p className="font-bold text-[0.95rem] text-ink">GreenBin Genius</p>
            <p className="text-[0.65rem] text-eco font-bold tracking-[0.1em] uppercase">Admin Console</p>
          </div>
        </div>

        <h2 className="text-[1.35rem] font-bold text-ink tracking-tight mb-1">Welcome back</h2>
        <p className="text-[0.82rem] text-ink-muted mb-6">Sign in to your admin account</p>

        {/* Error alert */}
        {error && (
          <div className="flex items-center gap-2 bg-red-500/10 border border-red-500/20 rounded-lg px-3.5 py-2.5 mb-5 text-red-400 text-[0.8rem]">
            <AlertCircle size={14} className="flex-shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {/* Google button */}
        <button
          type="button"
          onClick={() => { window.location.href = authApi.googleUrl() }}
          className="w-full flex items-center justify-center gap-2.5 px-4 py-2.5 bg-gb-input border border-gb-border rounded-xl text-ink text-[0.875rem] font-semibold hover:border-eco-border hover:bg-eco-muted transition-all duration-150 cursor-pointer mb-5"
        >
          <Chrome size={16} className="text-ink-sub" />
          Continue with Google
        </button>

        {/* Divider */}
        <div className="flex items-center gap-3 mb-5">
          <div className="flex-1 h-px bg-gb-border" />
          <span className="text-[0.72rem] text-ink-muted font-medium">or sign in with email</span>
          <div className="flex-1 h-px bg-gb-border" />
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-[0.76rem] font-semibold text-ink-sub">Email address</label>
            <div className="relative">
              <Mail size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-muted pointer-events-none" />
              <input
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="admin@greenbin.ai"
                required
                className="input pl-9 py-2.5"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-[0.76rem] font-semibold text-ink-sub">Password</label>
            <div className="relative">
              <Lock size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-muted pointer-events-none" />
              <input
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                className="input pl-9 py-2.5"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="btn btn-primary w-full justify-center py-2.5 text-[0.9rem] mt-2 disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {loading ? 'Signing in…' : 'Sign In'}
          </button>
        </form>

        <p className="text-center mt-5 text-[0.72rem] text-ink-muted">
          Only admin &amp; moderator accounts can access this console.
        </p>
      </div>
    </div>
  )
}