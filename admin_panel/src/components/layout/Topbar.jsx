import React, { useEffect } from 'react'
import { Bell, Search, HelpCircle } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import useAuthStore from '../../store/authStore'
import useAppStore from '../../store/appStore'
import { notificationsApi } from '../../api'

export default function Topbar({ title, subtitle }) {
  const { user }                           = useAuthStore()
  const { language, setLanguage, unreadCount, setUnread } = useAppStore()
  const navigate = useNavigate()

  useEffect(() => {
    notificationsApi.getUnreadCount()
      .then(r => setUnread(r.data.unread_count))
      .catch(() => {})
  }, [])

  return (
    <header className="sticky top-0 z-40 h-topbar flex items-center justify-between px-7 bg-gb-surface border-b border-gb-border">

      {/* Title */}
      <div>
        <h1 className="text-[1.2rem] font-bold text-ink tracking-tight leading-tight">{title}</h1>
        {subtitle && <p className="text-[0.75rem] text-ink-muted mt-0.5">{subtitle}</p>}
      </div>

      {/* Controls */}
      <div className="flex items-center gap-2.5">

        {/* Search */}
        <div className="relative">
          <Search size={13} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-ink-muted pointer-events-none" />
          <input
            placeholder="Search data..."
            className="input pl-8 w-48 text-[0.8rem] py-1.5"
          />
        </div>

        {/* Language toggle */}
        <div className="flex bg-gb-card border border-gb-border rounded-lg overflow-hidden">
          {['EN', 'UR'].map(l => (
            <button
              key={l}
              onClick={() => setLanguage(l)}
              className={`px-3 py-1.5 text-[0.72rem] font-bold tracking-wider transition-all duration-150 cursor-pointer border-none font-sans
                ${language === l ? 'bg-eco text-ink-inverse' : 'bg-transparent text-ink-muted hover:text-ink'}`}
            >
              {l}
            </button>
          ))}
        </div>

        {/* Bell */}
        <button
          onClick={() => navigate('/settings')}
          className="relative w-9 h-9 rounded-lg bg-gb-card border border-gb-border flex items-center justify-center text-ink-sub hover:border-eco-border hover:text-eco transition-all duration-150 cursor-pointer"
        >
          <Bell size={16} />
          {unreadCount > 0 && (
            <span className="absolute -top-1 -right-1 min-w-[16px] h-4 px-1 bg-red-500 text-white text-[0.58rem] font-bold rounded-full flex items-center justify-center leading-none">
              {unreadCount > 9 ? '9+' : unreadCount}
            </span>
          )}
        </button>

        {/* Help */}
        <button className="w-9 h-9 rounded-lg bg-gb-card border border-gb-border flex items-center justify-center text-ink-sub hover:border-eco-border hover:text-eco transition-all duration-150 cursor-pointer">
          <HelpCircle size={16} />
        </button>

        {/* Avatar */}
        <div className="w-9 h-9 rounded-full bg-eco-muted border-2 border-eco-border flex items-center justify-center text-eco font-bold text-[0.78rem] cursor-pointer">
          {user?.name?.[0]?.toUpperCase() || 'A'}
        </div>

      </div>
    </header>
  )
}