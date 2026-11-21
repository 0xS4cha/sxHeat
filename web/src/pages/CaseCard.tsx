import { CarFront, Crosshair, MapPin, Navigation, RectangleHorizontal, Shirt, Siren, Timer, UserRound, X } from 'lucide-react'
import { Button, Panel, Row, SegmentBar, Tag, type Tone } from '../components/ui'
import { useConfirm } from '../hooks/useConfirm'
import { useTranslation } from '../hooks/useTranslation'
import type { HeatCase } from '../types/heat'

function heatTone(heat: number): Tone {
  if (heat >= 66) return 'danger'
  if (heat >= 33) return 'warning'
  return 'accent'
}

function ago(seconds: number, t: (key: string, r?: Record<string, string | number>) => string) {
  if (seconds < 60) return t('time_seconds', { count: Math.max(0, seconds) })
  return t('time_minutes', { count: Math.floor(seconds / 60) })
}

interface CaseCardProps {
  item: HeatCase
  now: number
  index: number
  onClose: (id: number) => void
  onWaypoint: (item: HeatCase) => void
}

export function CaseCard({ item, now, index, onClose, onWaypoint }: CaseCardProps) {
  const { t } = useTranslation()
  const confirm = useConfirm<boolean>()
  const d = item.description
  const accessories = (['mask', 'hat', 'glasses', 'bag'] as const).filter((k) => d[k]).map((k) => t(`acc_${k}`))
  const label = (icon: typeof Siren, text: string) => {
    const Icon = icon
    return (
      <span className="flex items-center gap-2">
        <Icon className="h-4 w-4 text-white/50" />
        {text}
      </span>
    )
  }

  return (
    <Panel
      delay={index * 0.05}
      className={item.stale ? 'opacity-80' : ''}
      header={{
        subtitle: `#${item.id} · ${item.street ?? t('desc_unknown')}`,
        title: t(`crime_${item.lastCrime}`),
        icon: Siren,
        watermark: `#${item.id}`,
        actions: item.stale ? <Tag tone="warning">{t('case_stale')}</Tag> : <Tag tone="danger" solid>{t('case_fresh')}</Tag>,
      }}
      footer={{
        label: (
          <span className="flex flex-wrap gap-1.5">
            {Object.entries(item.crimes).map(([crime, count]) => (
              <Tag key={crime}>{`${t(`crime_${crime}`)}${count > 1 ? ` ×${count}` : ''}`}</Tag>
            ))}
          </span>
        ),
        children: (
          <span className="flex items-center gap-1">
            <Button size="sm" variant="subtle" icon={Navigation} onClick={() => onWaypoint(item)}>
              {t('btn_waypoint')}
            </Button>
            <Button
              size="sm"
              variant={confirm.pending ? 'danger' : 'subtle'}
              icon={X}
              className={confirm.pending ? '' : 'hover:!text-help-danger'}
              onClick={() => confirm.request(true, () => onClose(item.id))}
            >
              {confirm.pending ? t('btn_confirm') : t('btn_close_case')}
            </Button>
          </span>
        ),
      }}
    >
      <Row label={t('report_heat')} index={0}>
        <span className="flex items-center gap-2.5">
          <SegmentBar value={item.heat} max={100} tone={heatTone(item.heat)} />
          <span className="min-w-[44px] text-right text-[17px] font-semibold tabular-nums text-white">{item.heat}%</span>
        </span>
      </Row>
      {d.sex && d.sex !== 'unknown' && <Row index={1} label={label(UserRound, t('desc_sex'))} value={t(`sex_${d.sex}`)} />}
      <Row
        index={2}
        label={label(Shirt, t('desc_outfit'))}
        value={[...accessories, d.outfit ?? '?'].join(' · ')}
        tone={item.stale ? 'warning' : undefined}
      />
      {d.vehicle && (
        <Row
          index={3}
          label={label(CarFront, t('desc_vehicle'))}
          value={`${d.vehicle.label ?? '?'}${d.vehicle.color ? ` · ${t(`color_${d.vehicle.color}`)}` : ''}`}
        />
      )}
      {d.vehicle && (
        <Row
          index={4}
          label={label(RectangleHorizontal, t('desc_plate'))}
          value={d.vehicle.plate ?? t('desc_unknown')}
          tone={d.vehicle.plate ? 'accent' : 'rgba(255,255,255,0.5)'}
        />
      )}
      {d.weapon && <Row index={5} label={label(Crosshair, t('desc_weapon'))} value={t(`weapon_${d.weapon}`)} tone="danger" />}
      <Row index={6} label={label(Timer, t('case_last_seen'))} value={ago(now - item.lastSeen, t)} />
      <Row index={7} last label={label(MapPin, t('case_zone'))} value={t('case_radius', { radius: Math.round(item.radius) })} />
    </Panel>
  )
}
