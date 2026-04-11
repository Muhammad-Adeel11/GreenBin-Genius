import React, { useEffect } from 'react'
import { Routes, Route, Navigate, useLocation } from 'react-router-dom'
import useAuthStore from './store/authStore'

import Login     from './pages/Login'
import Dashboard from './pages/Dashboard'

const Classifications = React.lazy(() => import('./pages/Classifications'))
const Users           = React.lazy(() => import('./pages/Users'))
const Analytics       = React.lazy(() => import('./pages/Analytics'))
const EcoTips         = React.lazy(() => import('./pages/EcoTips'))
const BinLocations    = React.lazy(() => import('./pages/BinLocations'))
const AIModel         = React.lazy(() => import('./pages/AIModel'))
const Settings        = React.lazy(() => import('./pages/Settings'))

function RequireAuth({ children }) {
  const { token } = useAuthStore()
  const location  = useLocation()
  if (!token) return <Navigate to="/login" state={{ from: location }} replace />
  return children
}

function PageFallback() {
  return (
    <div className="min-h-screen bg-gb-base flex items-center justify-center">
      <div className="text-eco text-sm animate-pulse">Loading…</div>
    </div>
  )
}

/* Stub for pages not yet built */
function Stub({ name }) {
  const Layout = React.lazy(() => import('./components/layout/Layout'))
  return (
    <React.Suspense fallback={<PageFallback />}>
      <Layout title={name}>
        <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
          <span className="text-5xl">🚧</span>
          <h2 className="text-ink font-bold">{name}</h2>
          <p className="text-ink-muted text-sm">Coming in Part 2 / 3</p>
        </div>
      </Layout>
    </React.Suspense>
  )
}

export default function App() {
  const { token, fetchMe } = useAuthStore()
  useEffect(() => { if (token) fetchMe() }, [token])

  return (
    <React.Suspense fallback={<PageFallback />}>
      <Routes>
        <Route path="/login" element={<Login />} />

        <Route path="/" element={<RequireAuth><Dashboard /></RequireAuth>} />

        <Route path="/classifications" element={
          <RequireAuth>
            <React.Suspense fallback={<PageFallback />}><Classifications /></React.Suspense>
          </RequireAuth>
        } />
        <Route path="/users" element={
          <RequireAuth>
            <React.Suspense fallback={<PageFallback />}><Users /></React.Suspense>
          </RequireAuth>
        } />
        <Route path="/analytics" element={
          <RequireAuth>
            <React.Suspense fallback={<PageFallback />}><Analytics /></React.Suspense>
          </RequireAuth>
        } />
        <Route path="/eco-tips" element={
          <RequireAuth>
            <React.Suspense fallback={<PageFallback />}><EcoTips /></React.Suspense>
          </RequireAuth>
        } />
        <Route path="/bins" element={
          <RequireAuth>
            <React.Suspense fallback={<PageFallback />}><BinLocations /></React.Suspense>
          </RequireAuth>
        } />
        <Route path="/ai-model" element={
          <RequireAuth>
            <React.Suspense fallback={<PageFallback />}><AIModel /></React.Suspense>
          </RequireAuth>
        } />
        <Route path="/settings" element={
          <RequireAuth>
            <React.Suspense fallback={<PageFallback />}><Settings /></React.Suspense>
          </RequireAuth>
        } />

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </React.Suspense>
  )
}