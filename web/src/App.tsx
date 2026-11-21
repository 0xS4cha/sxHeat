import { useCallback, useEffect, useState } from 'react'
import { NuiWrapper } from './components/NuiWrapper'
import { useNuiEvent } from './hooks/useNuiEvent'
import { Reports } from './pages/Reports'
import type { SetVisibleData } from './types/nui'
import { fetchNui } from './utils/fetchNui'
import { isEnvBrowser } from './utils/nui'

export default function App() {
  const [visible, setVisible] = useState(isEnvBrowser())
  const handleSetVisible = useCallback(({ visible: next }: SetVisibleData) => setVisible(next), [])
  useNuiEvent<SetVisibleData>('setVisible', handleSetVisible)

  useEffect(() => {
    void fetchNui('nuiReady', { ok: true })
  }, [])

  return (
    <NuiWrapper visible={visible}>
      <div className="flex h-full w-full font-help text-white antialiased selection:bg-help-accent/40">
        <Reports visible={visible} />
      </div>
    </NuiWrapper>
  )
}
