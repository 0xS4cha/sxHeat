import type { LucideIcon } from 'lucide-react'
import { RefreshCw } from 'lucide-react'
import type { ReactNode } from 'react'
import { Button } from './Button'
import { PanelHeader } from './Panel'

interface PageHeaderProps {
  title: ReactNode
  subtitle: ReactNode
  icon: LucideIcon
  watermark?: string
  refreshLabel: string
  loading?: boolean
  onRefresh: () => void
  actions?: ReactNode
  className?: string
}

export function PageHeader({ title, subtitle, icon, watermark, refreshLabel, loading, onRefresh, actions, className = 'border-l border-help-line' }: PageHeaderProps) {
  return (
    <PanelHeader
      className={`h-[68px] shrink-0 px-6 ${className}`}
      subtitle={subtitle}
      title={title}
      icon={icon}
      watermark={watermark}
      actions={
        <>
          {actions}
          <Button
            size="sm"
            icon={RefreshCw}
            iconClassName={loading ? 'animate-spin' : ''}
            onClick={onRefresh}
            disabled={loading}
            title={refreshLabel}
          >
            <span className="hidden sm:inline">{refreshLabel}</span>
          </Button>
        </>
      }
    />
  )
}
