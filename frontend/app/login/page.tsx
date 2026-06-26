'use client';

import { FormEvent, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Eye, EyeOff, Lock, Mail } from 'lucide-react';
import { apiPost } from '../../lib/api';
import { setAdminTokens } from '../../lib/auth';

export default function LoginPage() {
  const [showPw, setShowPw] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [form, setForm] = useState({
    email: 'admin@fasotransport.bf',
    password: 'Password123!',
  });
  const router = useRouter();

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await apiPost('/auth/login', {
        email: form.email.trim(),
        password: form.password,
      });

      setAdminTokens(response.accessToken, response.refreshToken);
      router.push('/dashboard');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Connexion impossible');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-navy to-navy-2 px-4">
      <div className="bg-white rounded-2xl p-10 w-full max-w-[400px] shadow-2xl">
        <div className="mb-8">
          <p className="font-display text-3xl font-bold text-navy">🚌 FasoTransport</p>
          <p className="text-sm text-gray-500 mt-1">Connexion au panneau d'administration</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="label">Adresse Email</label>
            <div className="relative">
              <Mail size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
              <input
                type="email"
                className="input pl-9"
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
                placeholder="admin@fasotransport.bf"
                required
              />
            </div>
          </div>

          <div>
            <label className="label">Mot de Passe</label>
            <div className="relative">
              <Lock size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
              <input
                type={showPw ? 'text' : 'password'}
                className="input pl-9 pr-10"
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
                placeholder="••••••••"
                required
              />
              <button
                type="button"
                onClick={() => setShowPw(!showPw)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showPw ? <EyeOff size={15} /> : <Eye size={15} />}
              </button>
            </div>
          </div>

          {error ? (
            <div className="rounded-lg border border-red-100 bg-red-50 px-3 py-2 text-sm text-red-600">{error}</div>
          ) : null}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-navy text-white py-3 rounded-xl text-sm font-semibold hover:bg-navy-2 transition-colors disabled:opacity-70 font-display"
          >
            {loading ? 'Connexion...' : 'Se connecter →'}
          </button>
        </form>

        <div className="mt-6 p-3.5 bg-navy-light rounded-xl text-xs text-navy-2">
          <p className="font-bold text-navy mb-1">Demo — Identifiants</p>
          <p>admin@fasotransport.bf</p>
          <p>Mot de passe : Password123!</p>
        </div>
      </div>
    </div>
  );
}
