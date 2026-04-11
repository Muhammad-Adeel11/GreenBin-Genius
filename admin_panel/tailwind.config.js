/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx,ts,tsx}'],
  theme: {
    extend: {
      // ── Fonts ──────────────────────────────────────────────────────────
      fontFamily: {
        sans: ['DM Sans', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },

      // ── GreenBin colour palette ────────────────────────────────────────
      colors: {
        // Base surfaces
        gb: {
          base:    '#090f09',
          surface: '#0d1a0d',
          card:    '#111f11',
          hover:   '#152815',
          sidebar: '#0a150a',
          input:   '#0d1a0d',
          border:  'rgba(34,197,94,0.12)',
          'border-strong': 'rgba(34,197,94,0.28)',
        },
        // Accent green
        eco: {
          DEFAULT: '#22c55e',
          hover:   '#16a34a',
          muted:   'rgba(34,197,94,0.12)',
          border:  'rgba(34,197,94,0.28)',
          50:      'rgba(34,197,94,0.05)',
        },
        // Text
        ink: {
          DEFAULT: '#e2f0e2',
          sub:     '#7aaa7a',
          muted:   '#4a6e4a',
          inverse: '#090f09',
        },
        // Waste categories
        waste: {
          plastic:   '#22c55e',
          paper:     '#f59e0b',
          metal:     '#94a3b8',
          glass:     '#38bdf8',
          organic:   '#a3e635',
          ewaste:    '#f97316',
          hazardous: '#ef4444',
          textile:   '#c084fc',
          other:     '#64748b',
        },
      },

      // ── Spacing / sizing extras ────────────────────────────────────────
      width:  { sidebar: '240px' },
      height: { topbar:  '64px'  },

      // ── Border radius ──────────────────────────────────────────────────
      borderRadius: {
        card: '12px',
        xl2:  '18px',
      },

      // ── Box shadows ────────────────────────────────────────────────────
      boxShadow: {
        card:  '0 4px 24px rgba(0,0,0,0.45)',
        glow:  '0 0 24px rgba(34,197,94,0.18)',
        modal: '0 24px 60px rgba(0,0,0,0.55)',
      },

      // ── Keyframes ──────────────────────────────────────────────────────
      keyframes: {
        fadeUp: {
          from: { opacity: '0', transform: 'translateY(14px)' },
          to:   { opacity: '1', transform: 'translateY(0)' },
        },
        pulseGreen: {
          '0%, 100%': { boxShadow: '0 0 0 0 rgba(34,197,94,0.4)' },
          '50%':      { boxShadow: '0 0 0 8px rgba(34,197,94,0)' },
        },
        spinSlow: {
          to: { transform: 'rotate(360deg)' },
        },
      },
      animation: {
        'fade-up':     'fadeUp 0.3s ease both',
        'pulse-green': 'pulseGreen 2s ease infinite',
        'spin-slow':   'spinSlow 1s linear infinite',
      },

      // ── Background images ──────────────────────────────────────────────
      backgroundImage: {
        'grid-green': `
          linear-gradient(rgba(34,197,94,0.04) 1px, transparent 1px),
          linear-gradient(90deg, rgba(34,197,94,0.04) 1px, transparent 1px)
        `,
      },
      backgroundSize: {
        grid: '40px 40px',
      },
    },
  },
  plugins: [],
}