'use client';

import { Bell } from 'lucide-react';
import { ReactNode } from 'react';
import AdminAvatar from './AdminAvatar';

type TopbarProfile = {
  fullName?: string;
  avatarUrl?: string | null;
};

interface TopbarProps {
  title: string;
  children?: ReactNode;
  profile?: TopbarProfile | null;
}

export default function Topbar({ title, children, profile }: TopbarProps) {
  return (
    <div className="h-14 bg-white border-b border-gray-100 px-6 flex items-center justify-between flex-shrink-0">
      <p className="font-display text-base font-bold text-navy">{title}</p>
      <div className="flex items-center gap-2.5">
        {children}
        <AdminAvatar name={profile?.fullName} avatarUrl={profile?.avatarUrl} size="sm" className="border border-gray-100 bg-white" />
        <div className="relative">
          <button className="w-8 h-8 rounded-lg bg-gray-50 border border-gray-100 flex items-center justify-center hover:bg-gray-100 transition-colors">
            <Bell size={15} className="text-gray-500" />
          </button>
          <span className="absolute -top-1 -right-1 w-4 h-4 bg-brand-orange rounded-full text-[9px] text-white flex items-center justify-center font-bold">
            3
          </span>
        </div>
      </div>
    </div>
  );
}
