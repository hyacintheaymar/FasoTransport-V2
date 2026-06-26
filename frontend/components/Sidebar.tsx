'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  LayoutDashboard,
  Route,
  Clock,
  Bus,
  Ticket,
  User,
  LogOut,
  ChevronRight,
  MessageSquare,
} from 'lucide-react';
import { clsx } from 'clsx';
import { apiPost } from '../lib/api';
import { clearAdminToken, getAdminToken } from '../lib/auth';
import AdminAvatar from './AdminAvatar';

type SidebarProfile = {
  fullName?: string;
  email?: string;
  avatarUrl?: string | null;
};

const nav = [
  {
    section: 'PRINCIPAL',
    items: [{ label: 'Dashboard', href: '/dashboard', icon: LayoutDashboard }],
  },
  {
    section: 'GESTION',
    items: [
      { label: 'Routes', href: '/routes', icon: Route },
      { label: 'Horaires', href: '/schedules', icon: Clock },
      { label: 'Bus', href: '/buses', icon: Bus },
      { label: 'Reservations', href: '/bookings', icon: Ticket },
      { label: 'TransChat', href: '/chat', icon: MessageSquare },
      { label: 'Mon compte', href: '/account', icon: User },
    ],
  },
];

type SidebarProps = {
  profile?: SidebarProfile | null;
};

export default function Sidebar({ profile }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const fullName = profile?.fullName?.trim() || 'Administrateur';
  const email = profile?.email?.trim() || 'Super Admin';

  async function handleLogout() {
    const token = getAdminToken();
    try {
      if (token) {
        await apiPost('/auth/logout', {}, token);
      }
    } finally {
      clearAdminToken();
      router.push('/login');
    }
  }

  return (
    <aside className="w-[220px] bg-navy flex flex-col flex-shrink-0 h-screen">
      <div className="px-5 py-5 border-b border-white/10">
        <p className="font-display text-xl text-white tracking-tight">FasoTransport</p>
        <p className="text-[11px] text-white/40 mt-0.5">Admin Dashboard</p>
      </div>

      <nav className="flex-1 py-3 overflow-y-auto">
        {nav.map((group) => (
          <div key={group.section}>
            <p className="px-5 py-2 text-[10px] text-white/30 uppercase tracking-widest">{group.section}</p>
            {group.items.map(({ label, href, icon: Icon }) => {
              const active = pathname === href || pathname.startsWith(`${href}/`);
              return (
                <Link
                  key={href}
                  href={href}
                  className={clsx(
                    'group relative flex items-center gap-2.5 px-5 py-2.5 text-[13px] font-medium transition-all border-l-[3px]',
                    active
                      ? 'bg-white/12 text-white border-l-brand-orange shadow-[inset_0_0_0_1px_rgba(255,255,255,0.06)]'
                      : 'text-white/55 hover:bg-white/6 hover:text-white border-l-transparent',
                  )}
                >
                  <Icon size={16} />
                  <span>{label}</span>
                  <ChevronRight
                    size={14}
                    className={clsx(
                      'ml-auto transition-all',
                      active ? 'text-brand-orange opacity-100 translate-x-0' : 'opacity-0 -translate-x-1 group-hover:opacity-70 group-hover:translate-x-0',
                    )}
                  />
                </Link>
              );
            })}
          </div>
        ))}
      </nav>

      <div className="px-5 py-4 border-t border-white/10">
        <div className="flex items-center gap-2.5">
          <AdminAvatar name={fullName} avatarUrl={profile?.avatarUrl} size="sm" className="bg-white/10 text-white" />
          <div>
            <p className="text-white text-xs font-semibold">{fullName}</p>
            <p className="text-white/40 text-[10px]">{email}</p>
          </div>
          <button
            className="ml-auto text-white/40 hover:text-white transition-colors"
            onClick={handleLogout}
            title="Deconnexion"
          >
            <LogOut size={14} />
          </button>
        </div>
      </div>
    </aside>
  );
}
