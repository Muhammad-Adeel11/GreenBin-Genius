import React from 'react'
import { NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard, ListChecks, BarChart2, Users,
  Lightbulb, MapPin, BrainCircuit, Settings, LogOut, Recycle,
} from 'lucide-react'
import useAuthStore from '../../store/authStore'

const NAV = [
  { to: '/',                icon: LayoutDashboard, label: 'Dashboard'       },
  { to: '/classifications', icon: ListChecks,      label: 'Classifications' },
  { to: '/analytics',       icon: BarChart2,       label: 'Analytics'      },
  { to: '/users',           icon: Users,           label: 'Users'          },
  { to: '/eco-tips',        icon: Lightbulb,       label: 'Eco Tips'       },
  { to: '/bins',            icon: MapPin,          label: 'Bin Locations'  },
  { to: '/ai-model',        icon: BrainCircuit,    label: 'AI Model'       },
  { to: '/settings',        icon: Settings,        label: 'Settings'       },
]

export default function Sidebar() {
  const { user, logout } = useAuthStore()
  const navigate = useNavigate()

  return (
    <aside className="fixed inset-y-0 left-0 w-sidebar flex flex-col bg-gb-sidebar border-r border-gb-border z-50">

      {/* ── Logo ──────────────────────────────────────────────────────── */}
      <div className="flex items-center gap-2.5 px-4 py-5 border-b border-gb-border">
        <div className="w-9 h-9 rounded-xl bg-eco-muted border border-eco-border flex items-center justify-center flex-shrink-0">
          <Recycle size={18} className="text-eco" />
        </div>
        <div className="min-w-0">
          <p className="font-bold text-[0.88rem] text-ink leading-tight truncate">GreenBin Genius</p>
          <p className="text-[0.62rem] text-eco font-bold tracking-[0.1em] uppercase">Admin Console</p>
        </div>
      </div>

      {/* ── Nav ───────────────────────────────────────────────────────── */}
      <nav className="flex-1 overflow-y-auto px-2.5 py-3 space-y-0.5">
        {NAV.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `nav-item ${isActive ? 'nav-item-active' : ''}`
            }
          >
            <Icon size={16} className="flex-shrink-0" />
            <span>{label}</span>
          </NavLink>
        ))}
      </nav>

      {/* ── User footer ───────────────────────────────────────────────── */}
      <div className="border-t border-gb-border px-3 py-3 space-y-2.5">
        <div className="flex items-center gap-2.5 min-w-0">
          <div className="w-8 h-8 rounded-full bg-eco-muted border border-eco-border flex items-center justify-center text-eco font-bold text-xs flex-shrink-0">
            {user?.name?.[0]?.toUpperCase() || 'A'}
          </div>
          <div className="min-w-0">
            <p className="text-[0.78rem] font-semibold text-ink truncate">{user?.name || 'Admin User'}</p>
            <p className="text-[0.68rem] text-ink-muted truncate">{user?.email || 'admin@greenbin.ai'}</p>
          </div>
        </div>
        <button
          onClick={() => { logout(); navigate('/login') }}
          className="w-full flex items-center gap-2 px-3 py-2 rounded-lg bg-red-500/8 border border-red-500/15 text-red-400 text-[0.78rem] font-semibold hover:bg-red-500 hover:text-white transition-all duration-150 cursor-pointer"
        >
          <LogOut size={14} />
          Log Out
        </button>
      </div>
    </aside>
  )
}