import Link from 'next/link';
import Image from 'next/image';

export default function HomePage() {
  return (
    <main className="min-h-screen bg-gradient-to-br from-[#081F37] via-[#0D3A6E] to-[#122A47] text-white flex items-center justify-center p-6 md:p-12">
      <div className="w-full max-w-6xl grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-12 items-center">
        {/* Left Side: Content */}
        <section className="lg:col-span-7 space-y-6">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/10 backdrop-blur-md border border-white/10 text-xs font-semibold uppercase tracking-wider text-brand-orange-light">
            <span className="w-2 h-2 rounded-full bg-brand-orange animate-pulse"></span>
            FasoTransport
          </div>
          <h1 className="font-display text-4xl md:text-5xl lg:text-6xl font-bold leading-tight">
            Gérez vos trajets au Burkina Faso en toute simplicité.
          </h1>
          <p className="max-w-xl text-white/75 text-base md:text-lg leading-relaxed">
            Une plateforme moderne de gestion et de réservation de transport interurbain au Burkina Faso. Suivez vos horaires, gérez les places en temps réel et validez les billets QR en toute sécurité.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 pt-2">
            <Link 
              href="/login" 
              className="inline-flex items-center justify-center rounded-xl bg-brand-orange px-6 py-3.5 font-semibold text-white transition duration-300 hover:bg-[#D66512] hover:scale-[1.02] active:scale-[0.98] shadow-lg shadow-brand-orange/20"
            >
              Accès administration
            </Link>
            <Link 
              href="/dashboard" 
              className="inline-flex items-center justify-center rounded-xl border border-white/20 bg-white/5 px-6 py-3.5 font-semibold text-white transition duration-300 hover:bg-white/10 hover:scale-[1.02] active:scale-[0.98]"
            >
              Ouvrir le tableau de bord
            </Link>
          </div>

          <div className="grid gap-4 sm:grid-cols-3 pt-6 border-t border-white/10">
            <div className="rounded-2xl bg-white/5 p-4 border border-white/5 backdrop-blur-sm">
              <p className="font-semibold text-brand-orange mb-1">Réservations</p>
              <p className="text-sm text-white/70">Flux de réservation et billets QR connectés au backend.</p>
            </div>
            <div className="rounded-2xl bg-white/5 p-4 border border-white/5 backdrop-blur-sm">
              <p className="font-semibold text-brand-orange mb-1">Horaires</p>
              <p className="text-sm text-white/70">Gestion des horaires et des places disponibles en direct.</p>
            </div>
            <div className="rounded-2xl bg-white/5 p-4 border border-white/5 backdrop-blur-sm">
              <p className="font-semibold text-brand-orange mb-1">TransChat</p>
              <p className="text-sm text-white/70">Support voyageur intégré dans le tableau de bord admin.</p>
            </div>
          </div>
        </section>

        {/* Right Side: Beautiful Image Card with Glassmorphism */}
        <div className="lg:col-span-5 relative w-full aspect-[4/3] lg:aspect-square rounded-3xl overflow-hidden border border-white/15 shadow-2xl group">
          <Image 
            src="/burkina_transport.png" 
            alt="Burkina Transport" 
            fill
            className="object-cover transition duration-700 group-hover:scale-105"
            priority
          />
          {/* Gradients and Overlays */}
          <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/20 to-transparent" />
          
          <div className="absolute bottom-6 left-6 right-6 p-5 rounded-2xl bg-white/10 backdrop-blur-md border border-white/10 text-white space-y-1">
            <span className="text-xs uppercase tracking-wider text-brand-orange font-bold">Innovation & Connexion</span>
            <h3 className="font-display text-lg font-semibold">Le transport moderne burkinabè</h3>
            <p className="text-xs text-white/80">Faciliter la mobilité urbaine et interurbaine de Ouagadougou à Bobo-Dioulasso.</p>
          </div>
        </div>
      </div>
    </main>
  );
}

