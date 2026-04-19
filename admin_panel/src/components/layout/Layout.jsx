import React from 'react'
import Sidebar from './Sidebar'
import Topbar from './Topbar'

export default function Layout({ title, subtitle, children }) {
  return (
    <div className="flex min-h-screen bg-gb-base">
      <Sidebar />
      {/* 240px = w-sidebar — using inline style as a guarantee since ml-sidebar
          is a custom Tailwind value that can sometimes miss purging */}
      <div style={{ marginLeft: '240px' }} className="flex flex-col flex-1 min-h-screen min-w-0 overflow-hidden">
        <Topbar title={title} subtitle={subtitle} />
        <main className="flex-1 p-7 overflow-x-auto">
          {children}
        </main>
      </div>
    </div>
  )
}