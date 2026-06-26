'use client';

import clsx from 'clsx';

type AdminAvatarProps = {
  name?: string | null;
  avatarUrl?: string | null;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
};

const sizeMap = {
  sm: 'h-8 w-8 text-[11px]',
  md: 'h-10 w-10 text-xs',
  lg: 'h-20 w-20 text-xl',
};

function getInitials(name?: string | null) {
  if (!name?.trim()) return 'AD';
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return 'AD';
  if (parts.length === 1) return parts[0].slice(0, 1).toUpperCase();
  return `${parts[0].slice(0, 1)}${parts[parts.length - 1].slice(0, 1)}`.toUpperCase();
}

export default function AdminAvatar({ name, avatarUrl, size = 'md', className }: AdminAvatarProps) {
  return (
    <div
      className={clsx(
        'inline-flex items-center justify-center overflow-hidden rounded-full bg-brand-orange/10 text-brand-orange font-bold shrink-0',
        sizeMap[size],
        className,
      )}
    >
      {avatarUrl ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={avatarUrl} alt={name || 'Avatar'} className="h-full w-full object-cover" />
      ) : (
        <span className="font-display">{getInitials(name)}</span>
      )}
    </div>
  );
}