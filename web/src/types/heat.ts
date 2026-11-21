export interface SuspectVehicle {
  model?: number
  label?: string
  color?: string
  plate?: string | null
}

export interface SuspectDescription {
  sex?: 'male' | 'female' | 'unknown'
  outfit?: string
  hat?: boolean
  glasses?: boolean
  mask?: boolean
  bag?: boolean
  weapon?: string
  vehicle?: SuspectVehicle
}

export interface HeatCase {
  id: number
  crimes: Record<string, number>
  lastCrime: string
  heat: number
  description: SuspectDescription
  x: number
  y: number
  radius: number
  street?: string
  createdAt: number
  lastSeen: number
  stale: boolean
}
