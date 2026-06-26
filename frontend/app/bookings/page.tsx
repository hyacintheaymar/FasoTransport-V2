'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getAdminToken } from '../../lib/auth';
import { authGet } from '../../lib/api';
import DashboardLayout from '../../components/DashboardLayout';
import Pill from '../../components/ui/Pill';
import { Ticket } from 'lucide-react';

type BookingModel = {
  _id: string;
  bookingCode: string;
  seatNumber: number;
  amount: number;
  paymentStatus: string;
  validatedAt?: string;
  createdAt: string;
};

export default function BookingsPage() {
  const router = useRouter();
  const [bookings, setBookings] = useState<BookingModel[]>([]);
  const [loading, setLoading] = useState(true);

  async function loadBookings() {
    const token = getAdminToken();
    if (!token) {
      router.replace('/login');
      return;
    }

    try {
      const data = await authGet('/bookings');
      setBookings(data);
    } catch (err) {
      console.error('Erreur lors du chargement', err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadBookings();
  }, []);

  const validatedBookings = bookings.filter((b) => b.validatedAt).length;
  const totalRevenue = bookings.reduce((sum, b) => sum + b.amount, 0);

  return (
    <DashboardLayout title="Gestion des réservations">
      <div>
        <div className="mb-8">
          <h2 className="mb-1">Réservations</h2>
          <p className="m-0 text-gray-500">{bookings.length} réservation(s)</p>
        </div>

        {/* Stats */}
        <div className="grid-2 mb-8">
          <div className="stat-card">
            <div>
              <div className="stat-value">{validatedBookings}</div>
              <div className="stat-label">Réservations validées</div>
            </div>
          </div>
          <div className="stat-card">
            <div>
              <div className="stat-value">{totalRevenue.toLocaleString('fr-FR')}</div>
              <div className="stat-label">Revenu total (FCFA)</div>
            </div>
          </div>
        </div>

        {/* Table */}
        {loading ? (
          <div className="text-center py-10">
            <div className="loading mx-auto mb-4" />
            <p>Chargement des réservations...</p>
          </div>
        ) : bookings.length === 0 ? (
          <div className="card text-center py-12">
            <div className="w-12 h-12 rounded-xl bg-navy-3 text-navy flex items-center justify-center mx-auto mb-4">
              <Ticket size={22} />
            </div>
            <p className="m-0">Aucune réservation pour le moment</p>
          </div>
        ) : (
          <div className="card p-0 overflow-x-auto">
            <table>
              <thead>
                <tr>
                  <th className="th">Code de réservation</th>
                  <th className="th">Place</th>
                  <th className="th">Montant</th>
                  <th className="th">État du paiement</th>
                  <th className="th">Validation</th>
                  <th className="th">Date</th>
                </tr>
              </thead>
              <tbody>
                {bookings.map((booking) => (
                  <tr key={booking._id}>
                    <td className="td">
                      <strong>{booking.bookingCode}</strong>
                    </td>
                    <td className="td">{booking.seatNumber}</td>
                    <td className="td">
                      <strong>{booking.amount.toLocaleString('fr-FR')} FCFA</strong>
                    </td>
                    <td className="td">
                      <Pill
                        type={booking.paymentStatus}
                        label={booking.paymentStatus === 'PAID' ? 'Payé' : booking.paymentStatus === 'PENDING' ? 'En attente' : 'Annulé'}
                      />
                    </td>
                    <td className="td">
                      {booking.validatedAt ? (
                        <Pill type="VALIDE" label="Validée" />
                      ) : (
                        <Pill type="PENDING" label="En attente" />
                      )}
                    </td>
                    <td className="td text-xs">{new Date(booking.createdAt).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' })}</td>
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
