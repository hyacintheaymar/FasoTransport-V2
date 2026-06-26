'use client';

import { ChangeEvent, useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Camera, Upload, X } from 'lucide-react';
import { authGet, authPatch } from '../../lib/api';
import { getAdminToken } from '../../lib/auth';
import DashboardLayout from '../../components/DashboardLayout';

type Profile = {
  id: string;
  fullName: string;
  email: string;
  phone: string;
  role: string;
  isActive: boolean;
  createdAt: string;
  avatarUrl?: string | null;
};

export default function AccountPage() {
  const router = useRouter();
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [preview, setPreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const initials = useMemo(() => {
    const name = profile?.fullName?.trim();
    if (!name) return 'A';
    const parts = name.split(/\s+/).filter(Boolean);
    if (!parts.length) return 'A';
    if (parts.length === 1) return parts[0].slice(0, 1).toUpperCase();
    return `${parts[0].slice(0, 1)}${parts[parts.length - 1].slice(0, 1)}`.toUpperCase();
  }, [profile?.fullName]);

  const avatarSrc = preview || profile?.avatarUrl || '';

  async function refreshProfile() {
    const data = await authGet('/auth/me');
    setProfile(data);
  }

  function handleFileChange(e: ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.size > 2 * 1024 * 1024) {
      setError('Image trop grande (max 2 MB).');
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result;
      if (typeof result === 'string') {
        setPreview(result);
      }
    };
    reader.readAsDataURL(file);
  }

  async function saveAvatar() {
    if (!preview) return;
    setSaving(true);
    setError('');
    try {
      const updated = await authPatch('/auth/me/avatar', { avatarUrl: preview });
      setProfile(updated);
      setPreview(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Mise à jour impossible');
    } finally {
      setSaving(false);
    }
  }

  async function removeAvatar() {
    setSaving(true);
    setError('');
    try {
      const updated = await authPatch('/auth/me/avatar', { avatarUrl: null });
      setProfile(updated);
      setPreview(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Suppression impossible');
    } finally {
      setSaving(false);
    }
  }

  useEffect(() => {
    const token = getAdminToken();
    if (!token) {
      router.replace('/login');
      return;
    }

    refreshProfile()
      .catch(() => setProfile(null))
      .finally(() => setLoading(false));
  }, [router]);

  return (
    <DashboardLayout title="Mon compte">
      <div>
        {loading ? (
          <div className="text-center py-10">
            <div className="loading mx-auto mb-4" />
            <p>Chargement du profil...</p>
          </div>
        ) : profile ? (
          <div className="space-y-6">
            <div className="card overflow-hidden border border-gray-100 p-0">
              <div className="bg-gradient-to-r from-navy to-navy-2 px-6 py-6 text-white">
                <p className="text-xs uppercase tracking-[0.25em] text-white/70">Compte administrateur</p>
                <h3 className="mt-2 text-2xl font-bold font-display">Photo de profil</h3>
                <p className="mt-1 text-sm text-white/75">Ajoutez une photo pour rendre votre compte plus identifiable dans l’interface.</p>
              </div>

              <div className="grid gap-6 p-6 md:grid-cols-[240px_1fr]">
                <div className="flex flex-col items-center gap-4 rounded-3xl border border-gray-100 bg-gray-50 p-5">
                  <div className="relative">
                    <div className="flex h-40 w-40 items-center justify-center overflow-hidden rounded-full bg-white shadow-sm ring-8 ring-white">
                      {avatarSrc ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={avatarSrc} alt="Photo de profil" className="h-full w-full object-cover" />
                      ) : (
                        <span className="text-5xl font-bold text-navy font-display">{initials}</span>
                      )}
                    </div>
                    <button
                      type="button"
                      className="absolute bottom-2 right-2 inline-flex h-10 w-10 items-center justify-center rounded-full bg-brand-orange text-white shadow-lg hover:bg-brand-orange/90"
                      onClick={() => fileInputRef.current?.click()}
                      disabled={saving}
                      title="Choisir une photo"
                    >
                      <Camera size={16} />
                    </button>
                  </div>

                  <input ref={fileInputRef} type="file" accept="image/*" className="hidden" onChange={handleFileChange} />

                  <div className="w-full space-y-2">
                    <button type="button" className="btn btn-primary w-full" onClick={() => fileInputRef.current?.click()} disabled={saving}>
                      <Upload size={14} />
                      Choisir une image
                    </button>
                    <button type="button" className="btn btn-outline w-full" onClick={removeAvatar} disabled={saving || (!profile.avatarUrl && !preview)}>
                      <X size={14} />
                      Supprimer la photo
                    </button>
                  </div>
                </div>

                <div className="space-y-4">
                  <div className="card bg-white/80">
                    <h3>Aperçu & actions</h3>
                    <div className="space-y-4">
                      {preview ? (
                        <div className="rounded-2xl border border-dashed border-brand-orange/40 bg-brand-orange/5 p-4">
                          <p className="mb-3 text-sm font-semibold text-navy">Nouvelle photo prête</p>
                          <div className="flex items-center gap-4">
                            <div className="h-20 w-20 overflow-hidden rounded-xl bg-white shadow-sm">
                              {/* eslint-disable-next-line @next/next/no-img-element */}
                              <img src={preview} alt="Aperçu" className="h-full w-full object-cover" />
                            </div>
                            <div className="text-sm text-gray-600">
                              <p className="m-0">Validez pour enregistrer cette image sur votre profil.</p>
                              <p className="m-0 mt-1">La photo est automatiquement acceptée en carré par le mobile; ici elle est affichée telle quelle.</p>
                            </div>
                          </div>
                          <div className="mt-4 flex gap-3">
                            <button type="button" className="btn btn-primary" onClick={saveAvatar} disabled={saving}>
                              {saving ? 'Enregistrement...' : 'Enregistrer la photo'}
                            </button>
                            <button type="button" className="btn btn-outline" onClick={() => setPreview(null)} disabled={saving}>
                              Annuler l’aperçu
                            </button>
                          </div>
                        </div>
                      ) : (
                        <p className="text-sm text-gray-600">
                          Utilisez le bouton photo pour choisir une image. Vous pourrez ensuite l’enregistrer ou la supprimer.
                        </p>
                      )}
                      {error ? <div className="rounded-lg border border-red-100 bg-red-50 px-3 py-2 text-sm text-red-600">{error}</div> : null}
                    </div>
                  </div>

                  <div className="grid gap-4 md:grid-cols-2">
                    <div className="card">
                      <h3>Informations personnelles</h3>
                      <div className="space-y-4">
                        <div>
                          <label className="label">Nom complet</label>
                          <p className="m-0 font-medium text-gray-800">{profile.fullName || '-'}</p>
                        </div>
                        <div>
                          <label className="label">Adresse email</label>
                          <p className="m-0 font-medium text-gray-800">{profile.email}</p>
                        </div>
                        <div>
                          <label className="label">Téléphone</label>
                          <p className="m-0 font-medium text-gray-800">{profile.phone || '-'}</p>
                        </div>
                      </div>
                    </div>

                    <div className="card">
                      <h3>Détails du compte</h3>
                      <div className="space-y-4">
                        <div>
                          <label className="label">Rôle</label>
                          <div>
                            <span className="badge badge-info">
                              {profile.role === 'ADMIN' && 'Administrateur'}
                              {profile.role === 'AGENT' && 'Agent'}
                              {profile.role === 'PASSENGER' && 'Passager'}
                            </span>
                          </div>
                        </div>
                        <div>
                          <label className="label">Statut</label>
                          <div>
                            <span className={`badge ${profile.isActive ? 'badge-success' : 'badge-danger'}`}>
                              {profile.isActive ? 'Actif' : 'Inactif'}
                            </span>
                          </div>
                        </div>
                        <div>
                          <label className="label">Créé le</label>
                          <p className="m-0 font-medium text-gray-800">{new Date(profile.createdAt).toLocaleString('fr-FR')}</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        ) : (
          <div className="card text-center py-10">
            <p className="text-red-600 mb-4">⚠️ Impossible de charger le profil</p>
            <button className="btn-outline btn-sm" onClick={() => router.refresh()}>
              Réessayer
            </button>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
