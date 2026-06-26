'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { apiGet } from '../../lib/api';
import { getAdminToken } from '../../lib/auth';
import { useRouter } from 'next/navigation';
import DashboardLayout from '../../components/DashboardLayout';
import { Route, Bus, Clock3, Ticket, Lightbulb, Headset, Send, type LucideIcon } from 'lucide-react';

type Overview = { totalBookings: number; totalRevenue: number; currency: string };

export default function DashboardPage() {
  const router = useRouter();
  const [data, setData] = useState<Overview | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = getAdminToken();
    if (!token) {
      router.replace('/login');
      return;
    }

    apiGet('/dashboard/overview', token)
      .then(setData)
      .catch(() => setData(null))
      .finally(() => setLoading(false));
  }, [router]);

  return (
    <DashboardLayout title="Tableau de bord">
      {loading ? (
        <div className="text-center py-10">
          <div className="loading mx-auto mb-4" />
          <p>Chargement des données...</p>
        </div>
      ) : data ? (
        <div>
          {/* Stats Cards */}
          <div className="grid">
            <div className="stat-card">
              <div>
                <div className="stat-value">{data.totalBookings}</div>
                <div className="stat-label">Réservations totales</div>
              </div>
              <div style={{ fontSize: '11px', opacity: 0.8 }}>Ce mois</div>
            </div>
            <div className="stat-card">
              <div>
                <div className="stat-value">{data.totalRevenue.toLocaleString('fr-FR')}</div>
                <div className="stat-label">Revenus générés</div>
              </div>
              <div style={{ fontSize: '11px', opacity: 0.8 }}>{data.currency}</div>
            </div>
          </div>

          {/* Quick Actions */}
          <div className="mt-8">
            <h2 className="mb-4">Actions rapides</h2>
            <div className="grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))' }}>
              <QuickActionCard
                href="/routes"
                icon={Route}
                title="Gérer les routes"
                description="Créer et modifier les trajets"
              />
              <QuickActionCard
                href="/buses"
                icon={Bus}
                title="Gérer les bus"
                description="Ajouter des véhicules à la flotte"
              />
              <QuickActionCard
                href="/schedules"
                icon={Clock3}
                title="Gérer les horaires"
                description="Créer des plannings de trajet"
              />
              <QuickActionCard
                href="/bookings"
                icon={Ticket}
                title="Voir les réservations"
                description="Consulter toutes les réservations"
              />
            </div>
          </div>

          {/* Info Cards */}
          <div className="grid-2 mt-8">
            <div className="card">
              <h3 className="flex items-center gap-2"><Lightbulb size={18} /> Conseils</h3>
              <ul className="mt-4 pl-5 text-sm leading-7 text-gray-600">
                <li>Vérifiez les horaires chaque semaine</li>
                <li>Mettez à jour les prix régulièrement</li>
                <li>Suivez les validations QR en temps réel</li>
              </ul>
            </div>
            <div className="card">
              <h3 className="flex items-center gap-2"><Headset size={18} /> Support</h3>
              <p className="mb-3 text-sm text-gray-500">
                Besoin d'aide? Contactez notre équipe support
              </p>
              <button className="btn-outline btn-sm"><Send size={14} /> Envoyer un message</button>
            </div>
          </div>
        </div>
      ) : (
        <div className="card text-center py-10">
          <p className="text-red-600 mb-4">⚠️ Impossible de charger le tableau de bord</p>
          <button className="btn-outline btn-sm" onClick={() => router.refresh()}>
            Réessayer
          </button>
        </div>
      )}
    </DashboardLayout>
  );
}

function QuickActionCard({
  href,
  icon: Icon,
  title,
  description,
}: {
  href: string;
  icon: LucideIcon;
  title: string;
  description: string;
}) {
  return (
    <Link href={href} className="card flex flex-col h-full no-underline hover:border-brand-orange hover:bg-brand-orange-light/20 transition-colors">
      <div>
        <div className="w-10 h-10 rounded-lg bg-navy-3 text-navy flex items-center justify-center mb-3">
          <Icon size={20} />
        </div>
        <h4 className="text-gray-900">{title}</h4>
        <p className="text-sm text-gray-500 m-0">{description}</p>
      </div>
    </Link>
  );
}
