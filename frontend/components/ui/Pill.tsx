type PillType =
  | 'ACTIVE'
  | 'COMPLETED'
  | 'VALIDE'
  | 'SCHEDULED'
  | 'PASSENGER'
  | 'DEPARTED'
  | 'AGENT'
  | 'MAINTENANCE'
  | 'SUSPENDED'
  | 'CANCELLED'
  | 'ADMIN'
  | 'PAID'
  | 'PENDING'
  | string;

const pillMap: Record<string, string> = {
  ACTIVE: 'pill pill-green',
  COMPLETED: 'pill pill-green',
  VALIDE: 'pill pill-green',
  PAID: 'pill pill-green',
  SCHEDULED: 'pill pill-blue',
  PASSENGER: 'pill pill-blue',
  DEPARTED: 'pill pill-orange',
  AGENT: 'pill pill-orange',
  MAINTENANCE: 'pill pill-orange',
  PENDING: 'pill pill-orange',
  SUSPENDED: 'pill pill-red',
  CANCELLED: 'pill pill-red',
  ADMIN: 'pill pill-gray',
};

export default function Pill({ type, label }: { type: PillType; label?: string }) {
  return <span className={pillMap[type] ?? 'pill pill-gray'}>{label ?? type}</span>;
}
