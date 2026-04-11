import { create } from 'zustand'

const useAppStore = create((set) => ({
  language:    'EN',
  unreadCount: 0,
  setLanguage: (lang) => set({ language: lang }),
  setUnread:   (n)    => set({ unreadCount: n }),
}))

export default useAppStore