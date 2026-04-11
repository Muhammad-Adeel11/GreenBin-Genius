import React from 'react'
import Sidebar from './Sidebar'
import Topbar from './Topbar'

export default function Layout({ title, subtitle, children }) {
  return (
    <div className="flex min-h-screen bg-gb-base">
      <Sidebar />
      <div className="ml-sidebar flex flex-col flex-1 min-h-screen">
        <Topbar title={title} subtitle={subtitle} />
        <main className="flex-1 p-7 overflow-x-hidden">
          {children}
        </main>
      </div>
    </div>
  )
}