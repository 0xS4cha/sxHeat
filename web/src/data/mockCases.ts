import type { HeatCase } from '../types/heat'

const now = Math.floor(Date.now() / 1000)

export const MOCK_CASES: HeatCase[] = [
  {
    id: 14, crimes: { shooting: 1, murder: 1 }, lastCrime: 'murder', heat: 82,
    description: { sex: 'male', outfit: '4F2A9C', mask: true, weapon: 'pistol', vehicle: { label: 'Sultan RS', color: 'black', plate: '82S**174' } },
    x: 120.4, y: -1290.2, radius: 180, street: 'Strawberry Ave, Strawberry', createdAt: now - 240, lastSeen: now - 40, stale: false,
  },
  {
    id: 12, crimes: { carjacking: 1 }, lastCrime: 'carjacking', heat: 34,
    description: { sex: 'female', outfit: 'A11B07', hat: true, glasses: true, vehicle: { label: 'Comet', color: 'red', plate: null } },
    x: -620.1, y: -230.8, radius: 420, street: 'Portola Dr, Rockford Hills', createdAt: now - 900, lastSeen: now - 600, stale: true,
  },
  {
    id: 11, crimes: { threat: 2, assault: 1 }, lastCrime: 'assault', heat: 18,
    description: { sex: 'male', outfit: '0C77E1', bag: true, weapon: 'melee' },
    x: 300.0, y: -900.0, radius: 330, street: 'Vespucci Blvd, Pillbox Hill', createdAt: now - 1500, lastSeen: now - 300, stale: false,
  },
]
