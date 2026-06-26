'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authGet } from '../lib/api';
import { getAdminToken } from '../lib/auth';
import Sidebar from './Sidebar';
import Topbar from './Topbar';
import TransChat from './TransChat';

type AdminProfile = {
  fullName?: string;
  email?: string;
  avatarUrl?: string | null;
};

interface DashboardLayoutProps {
  children: React.ReactNode;
  title: string;
}

export default function DashboardLayout({ children, title }: DashboardLayoutProps) {
  const router = useRouter();
  const [profile, setProfile] = useState<AdminProfile | null>(null);

  useEffect(() => {
    const token = getAdminToken();
    if (!token) {
      router.replace('/login');
      return;
    }

    authGet('/auth/me')
      .then((data) => setProfile(data))
      .catch(() => setProfile(null));
  }, [router]);

  return (
    <div className="main-layout">
      <Sidebar profile={profile} />
      <div className="content">
        <Topbar title={title} profile={profile} />
        <main className="main-content">{children}</main>
      </div>
      <TransChat />
    </div>
  );
}
