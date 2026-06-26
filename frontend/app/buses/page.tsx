'use client';

import { FormEvent, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getAdminToken } from '../../lib/auth';
import { authGet, authPost, authDelete } from '../../lib/api';
import DashboardLayout from '../../components/DashboardLayout';
import { Bus, PlusCircle, Trash2 } from 'lucide-react';

type BusModel = {
  id: string;
  label: string;
  plateNumber: string;
  capacity: number;
  companyName: string;
};

export default function BusesPage() {
  const router = useRouter();
  const [buses, setBuses] = useState<BusModel[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    label: '',
    plateNumber: '',
    capacity: 30,
    companyName: 'Faso Transport',
  });

  async function loadBuses() {
    const token = getAdminToken();
    if (!token) {
      router.replace('/login');
      return;
    }

    const data = await authGet('/buses');
    setBuses(data);
  }

  useEffect(() => {
    loadBuses();
  }, []);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    const token = getAdminToken();
    if (!token) {
      router.replace('/login');
      return;
    }

    await authPost('/buses', form);
    setForm({ label: '', plateNumber: '', capacity: 30, companyName: 'Faso Transport' });
    setShowForm(false);
    await loadBuses();
  }

  async function handleDelete(id: string) {
    if (!window.confirm('Voulez-vous vraiment supprimer ce bus ?')) return;
    try {
      await authDelete(`/buses/${id}`);
      await loadBuses();
    } catch (e: any) {
      alert(e.message || 'Erreur lors de la suppression');
    }
  }

  return (
    <DashboardLayout title="Gestion de la flotte">
      <div>
        <div className="flex-between mb-8">
          <div>
            <h2 className="mb-1">Véhicules</h2>
            <p className="m-0 text-gray-500">{buses.length} bus enregistré(s)</p>
          </div>
          <button className="btn-orange" onClick={() => setShowForm(!showForm)}>
            <PlusCircle size={14} /> {showForm ? 'Annuler' : 'Ajouter un bus'}
          </button>
        </div>

        {showForm && (
          <form className="card mb-6" onSubmit={onSubmit}>
            <h3>Ajouter un nouveau bus</h3>
            <div className="form-group">
              <label>Nom du bus</label>
              <input required value={form.label} onChange={(e) => setForm({ ...form, label: e.target.value })} placeholder="Ex: Faso Transport 1" />
            </div>
            <div className="form-group">
              <label>Plaque d'immatriculation</label>
              <input required value={form.plateNumber} onChange={(e) => setForm({ ...form, plateNumber: e.target.value })} placeholder="Ex: BF-1234-AB" />
            </div>
            <div className="grid-2">
              <div className="form-group">
                <label>Capacité (places)</label>
                <input type="number" required value={form.capacity} onChange={(e) => setForm({ ...form, capacity: Number(e.target.value) })} />
              </div>
              <div className="form-group">
                <label>Compagnie</label>
                <input required value={form.companyName} onChange={(e) => setForm({ ...form, companyName: e.target.value })} />
              </div>
            </div>
            <button type="submit" className="btn-primary">Enregistrer le bus</button>
          </form>
        )}

        {buses.length === 0 ? (
          <div className="card text-center py-12">
            <div className="w-12 h-12 rounded-xl bg-navy-3 text-navy flex items-center justify-center mx-auto mb-4">
              <Bus size={22} />
            </div>
            <p className="m-0">Aucun bus enregistré pour le moment</p>
          </div>
        ) : (
          <div className="grid">
            {buses.map((bus) => (
              <div className="card relative" key={bus.id}>
                <button 
                  onClick={() => handleDelete(bus.id)} 
                  className="absolute top-4 right-4 text-gray-400 hover:text-red-500 transition-colors"
                  title="Supprimer le bus"
                >
                  <Trash2 size={18} />
                </button>
                <h4 className="flex items-center gap-2 pr-8"><Bus size={16} /> {bus.label}</h4>
                <div className="space-y-3 mt-3">
                  <div className="flex items-center justify-between text-sm text-gray-500">
                    <span>Plaque</span>
                    <strong>{bus.plateNumber}</strong>
                  </div>
                  <div className="flex items-center justify-between text-sm text-gray-500">
                    <span>Capacité</span>
                    <strong>{bus.capacity} places</strong>
                  </div>
                  <div className="flex items-center justify-between text-sm text-gray-500">
                    <span>Compagnie</span>
                    <strong>{bus.companyName}</strong>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
