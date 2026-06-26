'use client';

import { FormEvent, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getAdminToken } from '../../lib/auth';
import { authGet, authPost, authDelete } from '../../lib/api';
import DashboardLayout from '../../components/DashboardLayout';
import { Route, PlusCircle, MapPin, Clock3, Banknote, Trash2, Loader2, X } from 'lucide-react';

type RouteModel = {
  id: string;
  origin: string;
  destination: string;
  basePrice: number;
  distanceKm: number;
  durationMin: number;
};

export default function RoutesPage() {
  const router = useRouter();
  const [routes, setRoutes] = useState<RouteModel[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [selectedRoute, setSelectedRoute] = useState<RouteModel | null>(null);
  const [form, setForm] = useState({
    origin: '',
    destination: '',
    distanceKm: 300,
    durationMin: 240,
    basePrice: 7000,
  });
  const [isCalculating, setIsCalculating] = useState(false);

  const stats = useMemo(() => {
    if (!routes.length) {
      return { total: 0, avgDistance: 0, avgDuration: 0, avgPrice: 0 };
    }
    const totals = routes.reduce(
      (acc, item) => {
        acc.distance += Number(item.distanceKm || 0);
        acc.duration += Number(item.durationMin || 0);
        acc.price += Number(item.basePrice || 0);
        return acc;
      },
      { distance: 0, duration: 0, price: 0 },
    );
    return {
      total: routes.length,
      avgDistance: Math.round(totals.distance / routes.length),
      avgDuration: Math.round(totals.duration / routes.length),
      avgPrice: Math.round(totals.price / routes.length),
    };
  }, [routes]);

  async function loadRoutes() {
    const token = getAdminToken();
    if (!token) { router.replace('/login'); return; }
    const data = await authGet('/routes');
    setRoutes(data);
  }

  useEffect(() => { loadRoutes(); }, []);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    const token = getAdminToken();
    if (!token) { router.replace('/login'); return; }
    await authPost('/routes', form);
    setForm({ origin: '', destination: '', distanceKm: 300, durationMin: 240, basePrice: 7000 });
    setShowForm(false);
    await loadRoutes();
  }

  async function handleDelete(id: string) {
    if (!window.confirm('Voulez-vous vraiment supprimer cette route ?')) return;
    try {
      await authDelete(`/routes/${id}`);
      setSelectedRoute(null);
      await loadRoutes();
    } catch (e: any) {
      alert(e.message || 'Erreur lors de la suppression');
    }
  }

  async function geocodeCity(city: string) {
    const res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(city)}, Burkina Faso`);
    const data = await res.json();
    if (!data || data.length === 0) return null;
    return { lat: parseFloat(data[0].lat), lon: parseFloat(data[0].lon) };
  }

  async function handleAutoCalculate() {
    if (!form.origin || !form.destination) return;
    setIsCalculating(true);
    try {
      const p1 = await geocodeCity(form.origin);
      const p2 = await geocodeCity(form.destination);
      if (p1 && p2) {
        const res = await fetch(`https://router.project-osrm.org/route/v1/driving/${p1.lon},${p1.lat};${p2.lon},${p2.lat}?overview=false`);
        const data = await res.json();
        if (data && data.routes && data.routes.length > 0) {
          const distanceKm = Math.round(data.routes[0].distance / 1000);
          const durationMin = Math.round(data.routes[0].duration / 60);
          setForm(prev => ({ ...prev, distanceKm, durationMin }));
        }
      }
    } catch (e) {
      console.error('Erreur lors du calcul automatique:', e);
    } finally {
      setIsCalculating(false);
    }
  }

  return (
    <DashboardLayout title="Gestion des routes">
      <div className="space-y-6">
        <section className="card border-0 bg-gradient-to-r from-navy to-navy-2 text-white">
          <div className="flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <p className="m-0 text-xs uppercase tracking-[0.14em] text-white/70">Administration réseau</p>
              <h2 className="m-0 mt-2 text-2xl font-display">Planifier les routes inter-villes</h2>
              <p className="m-0 mt-2 text-sm text-white/75">Créez un itinéraire propre et complet avant de programmer vos horaires.</p>
            </div>
            <button className="btn-orange" onClick={() => setShowForm(!showForm)}>
              <PlusCircle size={14} /> {showForm ? 'Masquer le formulaire' : 'Nouvelle route'}
            </button>
          </div>
          <div className="mt-5 grid grid-cols-1 gap-3 sm:grid-cols-3">
            <div className="rounded-xl border border-white/15 bg-white/10 p-3">
              <p className="m-0 text-xs text-white/70">Total routes</p>
              <p className="m-0 mt-1 text-xl font-display">{stats.total}</p>
            </div>
            <div className="rounded-xl border border-white/15 bg-white/10 p-3">
              <p className="m-0 text-xs text-white/70">Distance moyenne</p>
              <p className="m-0 mt-1 text-xl font-display">{stats.avgDistance} km</p>
            </div>
            <div className="rounded-xl border border-white/15 bg-white/10 p-3">
              <p className="m-0 text-xs text-white/70">Prix moyen</p>
              <p className="m-0 mt-1 text-xl font-display">{stats.avgPrice.toLocaleString('fr-FR')} FCFA</p>
            </div>
          </div>
        </section>

        {showForm && (
          <form className="card space-y-5" onSubmit={onSubmit}>
            <div className="flex items-center justify-between">
              <div>
                <h3 className="m-0 text-lg">Créer une route</h3>
                <p className="m-0 mt-1 text-sm text-gray-500">Renseignez les données commerciales et opérationnelles du trajet.</p>
              </div>
              <span className="pill pill-blue">Nouveau</span>
            </div>
            <div className="grid-2">
              <div className="form-group">
                <label>Ville de départ</label>
                <input className="input" required value={form.origin} onChange={(e) => setForm({ ...form, origin: e.target.value })} onBlur={handleAutoCalculate} placeholder="Ex: Ouagadougou" />
              </div>
              <div className="form-group">
                <label>Ville de destination</label>
                <input className="input" required value={form.destination} onChange={(e) => setForm({ ...form, destination: e.target.value })} onBlur={handleAutoCalculate} placeholder="Ex: Bobo-Dioulasso" />
              </div>
            </div>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
              <div className="form-group relative">
                <label>
                  Distance (km)
                  {isCalculating && <Loader2 size={12} className="inline ml-2 animate-spin text-orange" />}
                </label>
                <input className="input" type="number" min={1} required value={form.distanceKm} onChange={(e) => setForm({ ...form, distanceKm: Number(e.target.value) })} />
              </div>
              <div className="form-group relative">
                <label>
                  Durée (minutes)
                  {isCalculating && <Loader2 size={12} className="inline ml-2 animate-spin text-orange" />}
                </label>
                <input className="input" type="number" min={1} required value={form.durationMin} onChange={(e) => setForm({ ...form, durationMin: Number(e.target.value) })} />
              </div>
              <div className="form-group">
                <label>Prix de base (FCFA)</label>
                <input className="input" type="number" min={1} required value={form.basePrice} onChange={(e) => setForm({ ...form, basePrice: Number(e.target.value) })} />
              </div>
            </div>
            <div className="flex justify-end">
              <button type="submit" className="btn-primary">Créer la route</button>
            </div>
          </form>
        )}

        {routes.length === 0 ? (
          <div className="card text-center py-12">
            <div className="w-12 h-12 rounded-xl bg-navy-3 text-navy flex items-center justify-center mx-auto mb-4">
              <Route size={22} />
            </div>
            <p className="m-0">Aucune route enregistrée pour le moment</p>
          </div>
        ) : (
          <section className="grid">
            {routes.map((r) => (
              <article
                className="card relative cursor-pointer hover:shadow-lg hover:-translate-y-0.5 transition-all duration-200"
                key={r.id}
                onClick={() => setSelectedRoute(r)}
              >
                <button
                  onClick={(e) => { e.stopPropagation(); handleDelete(r.id); }}
                  className="absolute top-4 right-4 text-gray-400 hover:text-red-500 transition-colors"
                  title="Supprimer la route"
                >
                  <Trash2 size={18} />
                </button>
                <h4 className="m-0 flex items-center gap-2 text-base font-display text-navy pr-8">
                  <Route size={16} /> {r.origin} → {r.destination}
                </h4>
                <div className="mt-4 space-y-3">
                  <div className="flex items-center justify-between text-sm text-gray-600">
                    <span className="inline-flex items-center gap-1"><MapPin size={14} /> Distance</span>
                    <strong>{r.distanceKm} km</strong>
                  </div>
                  <div className="flex items-center justify-between text-sm text-gray-600">
                    <span className="inline-flex items-center gap-1"><Clock3 size={14} /> Durée</span>
                    <strong>{Math.floor((r.durationMin || 0) / 60)}h {(r.durationMin || 0) % 60}min</strong>
                  </div>
                  <div className="flex items-center justify-between text-sm text-gray-600">
                    <span className="inline-flex items-center gap-1"><Banknote size={14} /> Prix de base</span>
                    <strong>{r.basePrice.toLocaleString('fr-FR')} FCFA</strong>
                  </div>
                </div>
                <p className="m-0 mt-4 text-xs text-gray-400 flex items-center gap-1">Cliquez pour voir les détails</p>
              </article>
            ))}
          </section>
        )}

        {/* Modal de détails */}
        {selectedRoute && (
          <div
            className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4"
            onClick={() => setSelectedRoute(null)}
          >
            <div
              className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6 relative animate-[fadeIn_0.2s_ease]"
              onClick={(e) => e.stopPropagation()}
            >
              <button
                onClick={() => setSelectedRoute(null)}
                className="absolute top-4 right-4 text-gray-400 hover:text-gray-700 transition-colors"
              >
                <X size={20} />
              </button>

              <div className="flex items-center gap-3 mb-6">
                <div className="w-10 h-10 rounded-xl bg-navy flex items-center justify-center text-white">
                  <Route size={18} />
                </div>
                <div>
                  <h3 className="m-0 text-lg font-display text-navy">Détails de la route</h3>
                  <p className="m-0 text-sm text-gray-500">{selectedRoute.origin} → {selectedRoute.destination}</p>
                </div>
              </div>

              <div className="space-y-4">
                <div className="rounded-xl bg-gray-50 p-4 space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-500 flex items-center gap-2"><MapPin size={14} /> Ville de départ</span>
                    <strong className="text-navy">{selectedRoute.origin}</strong>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-500 flex items-center gap-2"><MapPin size={14} /> Ville d'arrivée</span>
                    <strong className="text-navy">{selectedRoute.destination}</strong>
                  </div>
                </div>

                <div className="rounded-xl bg-gray-50 p-4 space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-500 flex items-center gap-2"><MapPin size={14} /> Distance</span>
                    <strong>{selectedRoute.distanceKm} km</strong>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-500 flex items-center gap-2"><Clock3 size={14} /> Durée estimée</span>
                    <strong>{Math.floor((selectedRoute.durationMin || 0) / 60)}h {(selectedRoute.durationMin || 0) % 60}min</strong>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-500 flex items-center gap-2"><Banknote size={14} /> Prix de base</span>
                    <strong className="text-green-600">{selectedRoute.basePrice.toLocaleString('fr-FR')} FCFA</strong>
                  </div>
                </div>
              </div>

              <div className="mt-6 flex gap-3">
                <button
                  onClick={() => setSelectedRoute(null)}
                  className="flex-1 py-2.5 rounded-xl border border-gray-200 text-gray-600 text-sm font-medium hover:bg-gray-50 transition-colors"
                >
                  Fermer
                </button>
                <button
                  onClick={() => handleDelete(selectedRoute.id)}
                  className="flex-1 py-2.5 rounded-xl bg-red-50 text-red-600 text-sm font-medium hover:bg-red-100 transition-colors flex items-center justify-center gap-2"
                >
                  <Trash2 size={14} /> Supprimer cette route
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
