import { useCallback, useEffect, useState } from 'react'
import { MOCK_CASES } from '../data/mockCases'
import type { HeatCase } from '../types/heat'
import { fetchNui } from '../utils/fetchNui'
import { isEnvBrowser } from '../utils/nui'

export function useCases(visible: boolean) {
  const [cases, setCases] = useState<HeatCase[]>(isEnvBrowser() ? MOCK_CASES : [])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [clock, setClock] = useState(() => Math.floor(Date.now() / 1000))

  const refresh = useCallback(async () => {
    if (isEnvBrowser()) return
    setLoading(true)
    try {
      setCases(await fetchNui<HeatCase[]>('getCases'))
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'unknown')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    if (!visible) return
    const first = window.setTimeout(() => void refresh(), 0)
    const id = window.setInterval(() => {
      setClock(Math.floor(Date.now() / 1000))
      void refresh()
    }, 5000)
    return () => {
      window.clearTimeout(first)
      window.clearInterval(id)
    }
  }, [visible, refresh])

  const closeCase = useCallback(async (id: number) => {
    if (isEnvBrowser()) {
      setCases((list) => list.filter((c) => c.id !== id))
      return
    }
    try {
      await fetchNui('closeCase', { id })
      await refresh()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'unknown')
    }
  }, [refresh])

  return {
    cases,
    loading,
    error,
    clearError: () => setError(null),
    refresh,
    closeCase,
    now: clock,
    setWaypoint: (c: HeatCase) => void fetchNui('setWaypoint', { x: c.x, y: c.y }),
  }
}
