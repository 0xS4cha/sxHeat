import { useState } from 'react'
import { AlertCircle, Inbox, Siren, X } from 'lucide-react'
import { Button, KeyBadge, PageHeader, Panel, Tabs } from '../components/ui'
import { useCases } from '../hooks/useCases'
import { useTranslation } from '../hooks/useTranslation'
import { fetchNui } from '../utils/fetchNui'
import { CaseCard } from './CaseCard'

type Filter = 'all' | 'fresh' | 'stale'

export function Reports({ visible }: { visible: boolean }) {
  const { t } = useTranslation()
  const [filter, setFilter] = useState<Filter>('all')
  const data = useCases(visible)
  const list = data.cases.filter((c) => filter === 'all' || (filter === 'stale' ? c.stale : !c.stale))

  return (
    <div className="flex h-full w-full flex-col overflow-hidden">
      <PageHeader
        title={t('header_title')}
        subtitle={t('header_subtitle')}
        icon={Siren}
        watermark="DISPATCH"
        className=""
        refreshLabel={t('btn_refresh')}
        loading={data.loading}
        onRefresh={() => void data.refresh()}
        actions={
          <Button size="sm" onClick={() => void fetchNui('close')}>
            {t('btn_close')}
            <KeyBadge label="ESC" size={20} />
          </Button>
        }
      />

      {data.error && (
        <div className="flex items-center justify-between gap-3 bg-help-danger px-6 py-2 text-[15px] font-semibold uppercase tracking-wide text-help-panel">
          <span className="flex items-center gap-2">
            <AlertCircle className="h-4 w-4" />
            {t(`error_${data.error}`)}
          </span>
          <button type="button" onClick={data.clearError}>
            <X className="h-4 w-4" />
          </button>
        </div>
      )}

      <main className="flex-1 space-y-6 overflow-auto p-6">
        <Tabs
          value={filter}
          onChange={setFilter}
          options={[
            { value: 'all', label: t('filter_all', { count: data.cases.length }) },
            { value: 'fresh', label: t('filter_fresh', { count: data.cases.filter((c) => !c.stale).length }) },
            { value: 'stale', label: t('filter_stale', { count: data.cases.filter((c) => c.stale).length }) },
          ]}
        />

        {list.length === 0 ? (
          <Panel header={{ title: t('empty_title'), icon: Inbox }} bodyClassName="px-4 py-4 text-[15px] text-white/65">
            {t('empty_desc')}
          </Panel>
        ) : (
          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
            {list.map((item, index) => (
              <CaseCard
                key={item.id}
                item={item}
                index={index}
                now={data.now}
                onClose={(id) => void data.closeCase(id)}
                onWaypoint={data.setWaypoint}
              />
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
