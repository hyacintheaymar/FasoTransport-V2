'use client';

import { FormEvent, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getAdminToken } from '../../lib/auth';
import { authGet, authPost, authDelete } from '../../lib/api';
import DashboardLayout from '../../components/DashboardLayout';
import { Clock3, PlusCircle, CalendarClock, UserCheck, Bus, Armchair, Route, Trash2 } from 'lucide-react';

type RouteModel = {
  id: string;
  origin: string;
  destination: string;
  basePrice: number;
  durationMin: number;
};

type BusModel = {
  id: string;
  label: string;
  capacity: number;
};

type AgentModel = {
  id: string;
  fullName: string;
  email: string;
};

type ScheduleModel = {
  id: string;
  busLabel: string;
  origin?: string;
  destination?: string;
  agentName?: string | null;
  agentEmail?: string | null;
  agent?: {
    id?: string;
    fullName?: string;
    email?: string;
  } | null;
  departureTime: string;
  arrivalTime: string;
  availableSeats: number;
  totalSeats: number;
  price: number;
  status: string;
};

export default function SchedulesPage() {
  const router = useRouter();
  const [routes, setRoutes] = useState<RouteModel[]>([]);
  const [buses, setBuses] = useState<BusModel[]>([]);
  const [agents, setAgents] = useState<AgentModel[]>([]);
  const [schedules, setSchedules] = useState<ScheduleModel[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    routeId: '',
    busLabel: '',
    agentId: '',
    departureTime: '',
    arrivalTime: '',
    availableSeats: 30,
    totalSeats: 30,
    price: 7000,
  });

  const stats = useMemo(() => {
    const assigned = schedules.filter((s) => !!s.agentId).length;
    const seats = schedules.reduce((acc, s) => acc + Number(s.availableSeats || 0), 0);
    return {
      total: schedules.length,
      assigned,
      seats,
    };
  }, [schedules]);

  async function loadData() {
    const token = getAdminToken();
    if (!token) {
      router.replace('/login');
      return;
    }

    const [routesData, busesData, agentsData, schedulesData] = await Promise.all([
      authGet('/routes'),
      authGet('/buses'),
      authGet('/users/agents'),
      authGet('/schedules'),
    ]);

    setRoutes(routesData);
    setBuses(busesData);
    setAgents(agentsData);
    setSchedules(schedulesData);
  }

  useEffect(() => {
    loadData();
  }, []);

  useEffect(() => {
    if (form.routeId) {
      const route = routes.find((r: any) => r.id === form.routeId);
      if (route) {
        let newForm = { ...form };
        let changed = false;

        if (form.price !== route.basePrice) {
          newForm.price = route.basePrice;
          changed = true;
        }

        if (form.departureTime && route.durationMin) {
          const departure = new Date(form.departureTime);
          const arrival = new Date(departure.getTime() + route.durationMin * 60000);
          const arrivalStr = new Date(arrival.getTime() - arrival.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
          if (newForm.arrivalTime !== arrivalStr) {
            newForm.arrivalTime = arrivalStr;
            changed = true;
          }
        }

        if (changed) setForm(newForm);
      }
    }
  }, [form.routeId, form.departureTime, routes]);

  useEffect(() => {
    if (form.busLabel) {
      const bus = buses.find((b: any) => b.label === form.busLabel);
      if (bus && bus.capacity) {
        if (form.totalSeats !== bus.capacity || form.availableSeats !== bus.capacity) {
          setForm(prev => ({ ...prev, totalSeats: bus.capacity, availableSeats: bus.capacity }));
        }
      }
    }
  }, [form.busLabel, buses]);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    const token = getAdminToken();
    if (!token) {
      router.replace('/login');
      return;
    }

    const payload: any = { ...form };
    if (!payload.agentId) {
      delete payload.agentId;
    }

    try {
      await authPost('/schedules', payload);
      setForm({
        routeId: '',
        busLabel: '',
        agentId: '',
        departureTime: '',
        arrivalTime: '',
        availableSeats: 30,
        totalSeats: 30,
        price: 7000,
      });
      setShowForm(false);
      await loadData();
    } catch (err: any) {
      alert(err.message || 'Erreur lors de la création de l\'horaire');
    }
  }

  async function handleDelete(id: string) {
    if (!window.confirm('Voulez-vous vraiment supprimer cet horaire ?')) return;
    try {
      await authDelete(`/schedules/${id}`);
      await loadData();
    } catch (e: any) {
      alert(e.message || 'Erreur lors de la suppression');
    }
  }

  const getAgentLabel = (schedule: ScheduleModel) => {
    if (schedule.agentName) {
      return schedule.agentEmail
        ? `${schedule.agentName} (${schedule.agentEmail})`
        : schedule.agentName;
    }
    // fallback sur l'objet agent s'il est populé
    if (schedule.agent && schedule.agent.fullName) {
      return schedule.agent.email
        ? `${schedule.agent.fullName} (${schedule.agent.email})`
        : schedule.agent.fullName;
    }
    return 'Non assigné';
  };

  const getRouteLabel = (schedule: ScheduleModel) => {
    if (schedule.origin && schedule.destination) {
      return `${schedule.origin} → ${schedule.destination}`;
    }
    return 'Route liée';
  };

  return (
    <DashboardLayout title="Gestion des horaires">
      <div className="space-y-6">
        <section className="card border-0 bg-gradient-to-r from-gray-900 to-navy text-white">
          <div className="flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <p className="m-0 text-xs uppercase tracking-[0.14em] text-white/70">Exploitation terrain</p>
              <h2 className="m-0 mt-2 text-2xl font-display">Programmation des horaires</h2>
              <p className="m-0 mt-2 text-sm text-white/75">Associez route, bus et agent pour fluidifier le contrôle QR sur le terrain.</p>
            </div>
            <button className="btn-orange" onClick={() => setShowForm(!showForm)}>
              <PlusCircle size={14} /> {showForm ? 'Masquer le formulaire' : 'Créer un horaire'}
            </button>
          </div>

          <div className="mt-5 grid grid-cols-1 gap-3 sm:grid-cols-3">
            <div className="rounded-xl border border-white/15 bg-white/10 p-3">
              <p className="m-0 text-xs text-white/70">Horaires actifs</p>
              <p className="m-0 mt-1 text-xl font-display">{stats.total}</p>
            </div>
            <div className="rounded-xl border border-white/15 bg-white/10 p-3">
              <p className="m-0 text-xs text-white/70">Agents assignés</p>
              <p className="m-0 mt-1 text-xl font-display">{stats.assigned}</p>
            </div>
            <div className="rounded-xl border border-white/15 bg-white/10 p-3">
              <p className="m-0 text-xs text-white/70">Places disponibles</p>
              <p className="m-0 mt-1 text-xl font-display">{stats.seats}</p>
            </div>
          </div>
        </section>

        {showForm && (
          <form className="card space-y-5" onSubmit={onSubmit}>
            <div className="flex items-center justify-between">
              <div>
                <h3 className="m-0 text-lg">Créer un horaire</h3>
                <p className="m-0 mt-1 text-sm text-gray-500">Complétez l'affectation opérationnelle avant publication.</p>
              </div>
              <span className="pill pill-blue">Planification</span>
            </div>

            <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
              <div className="form-group">
                <label>Route</label>
                <select className="input" required value={form.routeId} onChange={(e) => setForm({ ...form, routeId: e.target.value })}>
                  <option value="">Sélectionnez une route</option>
                  {routes.map((route) => (
                    <option key={route.id} value={route.id}>
                      {route.origin} → {route.destination}
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label>Bus</label>
                <select className="input" required value={form.busLabel} onChange={(e) => setForm({ ...form, busLabel: e.target.value })}>
                  <option value="">Sélectionnez un bus</option>
                  {buses.map((bus) => (
                    <option key={bus.id} value={bus.label}>
                      {bus.label}
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label>Agent de scan</label>
                <select className="input" required value={form.agentId} onChange={(e) => setForm({ ...form, agentId: e.target.value })}>
                  <option value="">Sélectionnez un agent</option>
                  {agents.map((agent) => (
                    <option key={agent.id} value={agent.id}>
                      {agent.fullName} ({agent.email})
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="grid-2">
              <div className="form-group">
                <label>Départ</label>
                <input className="input" type="datetime-local" required value={form.departureTime} onChange={(e) => setForm({ ...form, departureTime: e.target.value })} />
              </div>
              <div className="form-group">
                <label>Arrivée</label>
                <input className="input" type="datetime-local" required value={form.arrivalTime} onChange={(e) => setForm({ ...form, arrivalTime: e.target.value })} />
              </div>
            </div>

            <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
              <div className="form-group">
                <label>Places totales</label>
                <input className="input" type="number" min={1} required value={form.totalSeats} onChange={(e) => setForm({ ...form, totalSeats: Number(e.target.value) })} />
              </div>
              <div className="form-group">
                <label>Places disponibles</label>
                <input className="input" type="number" min={1} required value={form.availableSeats} onChange={(e) => setForm({ ...form, availableSeats: Number(e.target.value) })} />
              </div>
              <div className="form-group">
                <label>Prix (FCFA)</label>
                <input className="input" type="number" min={1} required value={form.price} onChange={(e) => setForm({ ...form, price: Number(e.target.value) })} />
              </div>
            </div>

            <div className="flex justify-end">
              <button type="submit" className="btn-primary">Créer l'horaire</button>
            </div>
          </form>
        )}

        {schedules.length === 0 ? (
          <div className="card text-center py-12">
            <div className="w-12 h-12 rounded-xl bg-navy-3 text-navy flex items-center justify-center mx-auto mb-4">
              <Clock3 size={22} />
            </div>
            <p className="m-0">Aucun horaire enregistré pour le moment</p>
          </div>
        ) : (
          <div className="card p-0 overflow-x-auto">
            <table>
              <thead>
                <tr>
                  <th className="th">Route</th>
                  <th className="th">Bus</th>
                  <th className="th">Agent</th>
                  <th className="th">Départ</th>
                  <th className="th">Arrivée</th>
                  <th className="th">Places</th>
                  <th className="th">Prix</th>
                  <th className="th text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {schedules.map((schedule) => (
                  <tr key={schedule.id}>
                    <td className="td">
                      <span className="inline-flex items-center gap-1 text-gray-700"><Route size={14} /> {getRouteLabel(schedule)}</span>
                    </td>
                    <td className="td">
                      <span className="inline-flex items-center gap-1"><Bus size={14} /> {schedule.busLabel}</span>
                    </td>
                    <td className="td">
                      <span className="inline-flex items-center gap-1"><UserCheck size={14} /> {getAgentLabel(schedule)}</span>
                    </td>
                    <td className="td">
                      <span className="inline-flex items-center gap-1"><CalendarClock size={14} /> {new Date(schedule.departureTime).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' })}</span>
                    </td>
                    <td className="td">{new Date(schedule.arrivalTime).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' })}</td>
                    <td className="td">
                      <span className="inline-flex items-center gap-1"><Armchair size={14} /> {schedule.availableSeats}/{schedule.totalSeats || schedule.availableSeats}</span>
                    </td>
                    <td className="td">
                      <strong>{schedule.price.toLocaleString('fr-FR')} FCFA</strong>
                    </td>
                    <td className="td text-right">
                      <button 
                        onClick={() => handleDelete(schedule.id)} 
                        className="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors"
                        title="Supprimer l'horaire"
                      >
                        <Trash2 size={16} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
