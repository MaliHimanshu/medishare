// src/pages/LandingPage.jsx
import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  FiHeart, FiShare2, FiActivity, FiTruck,
  FiMessageSquare, FiBell, FiArrowRight, FiCheck,
  FiStar, FiUsers, FiPackage, FiZap
} from 'react-icons/fi';
import Button from '../components/ui/Button';
import Logo from '../components/ui/Logo';

// ── Animated Counter ─────────────────────────────────────────
function Counter({ end, suffix = '', duration = 2000 }) {
  const [count, setCount] = useState(0);
  const ref = useRef(null);
  const started = useRef(false);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !started.current) {
          started.current = true;
          const step = end / (duration / 16);
          let current = 0;
          const timer = setInterval(() => {
            current += step;
            if (current >= end) {
              setCount(end);
              clearInterval(timer);
            } else {
              setCount(Math.floor(current));
            }
          }, 16);
        }
      },
      { threshold: 0.5 }
    );
    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, [end, duration]);

  return <span ref={ref}>{count.toLocaleString()}{suffix}</span>;
}

// ── Feature Card ─────────────────────────────────────────────
function FeatureCard({ icon, title, desc, color, delay }) {
  return (
    <div
      className={`
        group p-6 rounded-[var(--radius-xl)] border border-[var(--color-border)]
        hover:border-[var(--color-primary)] hover:shadow-[var(--shadow-lg)]
        bg-white transition-all duration-300 hover:-translate-y-1
        animate-fade-in-up opacity-0
      `}
      style={{ animationDelay: `${delay}ms`, animationFillMode: 'forwards' }}
    >
      <div
        className={`
          w-12 h-12 rounded-[var(--radius-md)] flex items-center justify-center mb-4
          ${color} group-hover:scale-110 transition-transform duration-300
        `}
      >
        {icon}
      </div>
      <h3 className="font-bold text-[var(--color-text)] text-lg mb-2">{title}</h3>
      <p className="text-[var(--color-text-muted)] text-sm leading-relaxed">{desc}</p>
    </div>
  );
}

// ── Step Card ─────────────────────────────────────────────────
function StepCard({ step, title, desc, icon, isLast }) {
  return (
    <div className="flex gap-6 items-start">
      <div className="flex flex-col items-center">
        <div className="w-12 h-12 rounded-full gradient-primary flex items-center justify-center text-white font-bold text-lg flex-shrink-0 shadow-[var(--shadow-md)]">
          {step}
        </div>
        {!isLast && <div className="w-0.5 h-16 bg-gradient-to-b from-[var(--color-primary)] to-[var(--color-accent)] mt-2 opacity-30" />}
      </div>
      <div className="pb-8">
        <div className="flex items-center gap-2 mb-2">
          <span className="text-[var(--color-accent)]">{icon}</span>
          <h3 className="font-bold text-[var(--color-text)] text-lg">{title}</h3>
        </div>
        <p className="text-[var(--color-text-muted)] text-sm leading-relaxed">{desc}</p>
      </div>
    </div>
  );
}

// ── Testimonial Card ─────────────────────────────────────────
function TestimonialCard({ name, role, org, quote, avatar }) {
  return (
    <div className="p-6 rounded-[var(--radius-xl)] bg-white border border-[var(--color-border)] shadow-[var(--shadow-sm)] hover:shadow-[var(--shadow-md)] transition-all duration-300">
      <div className="flex items-center gap-1 mb-4">
        {[...Array(5)].map((_, i) => (
          <FiStar key={i} size={14} className="text-yellow-400 fill-yellow-400" />
        ))}
      </div>
      <p className="text-[var(--color-text)] text-sm leading-relaxed mb-6 italic">"{quote}"</p>
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-full gradient-primary flex items-center justify-center text-white font-bold text-sm">
          {avatar}
        </div>
        <div>
          <p className="font-bold text-sm text-[var(--color-text)]">{name}</p>
          <p className="text-xs text-[var(--color-text-muted)]">{role} · {org}</p>
        </div>
      </div>
    </div>
  );
}

// ── Main Landing Page ─────────────────────────────────────────
export default function LandingPage() {
  return (
    <div className="flex-1">

      {/* ── HERO ───────────────────────────────────────────── */}
      <section className="relative min-h-screen gradient-hero flex items-center overflow-hidden">

        {/* Animated background orbs */}
        <div className="absolute top-20 left-10 w-72 h-72 rounded-full opacity-20 animate-float"
             style={{ background: 'radial-gradient(circle, #3b6cf8 0%, transparent 70%)' }} />
        <div className="absolute bottom-20 right-10 w-96 h-96 rounded-full opacity-15 animate-float"
             style={{ background: 'radial-gradient(circle, #2ecfb3 0%, transparent 70%)', animationDelay: '1.5s' }} />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full opacity-5"
             style={{ background: 'radial-gradient(circle, #3b6cf8 0%, transparent 70%)' }} />

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-32 relative z-10">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">

            {/* Left Content */}
            <div>
              {/* Pill badge */}
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full glass mb-6 animate-fade-in">
                <span className="w-2 h-2 rounded-full bg-[var(--color-accent)] animate-pulse" />
                <span className="text-white/80 text-sm font-medium">Smart Medical Equipment Network</span>
              </div>

              <h1 className="text-5xl sm:text-6xl lg:text-7xl font-black text-white leading-[1.05] tracking-tight mb-6 animate-fade-in-up">
                Share Medical{' '}
                <span className="gradient-text" style={{ WebkitTextFillColor: 'transparent' }}>
                  Equipment,
                </span>
                <br />
                Save Lives
              </h1>

              <p className="text-white/65 text-lg leading-relaxed mb-10 max-w-lg animate-fade-in-up delay-200">
                MediShare connects hospitals, NGOs, and donors to redistribute
                medical equipment where it's needed most. Join thousands making
                healthcare more accessible.
              </p>

              <div className="flex flex-wrap gap-4 animate-fade-in-up delay-300">
                <Link to="/register">
                  <Button variant="accent" size="lg" rightIcon={<FiArrowRight />}>
                    Start Donating
                  </Button>
                </Link>
                <a href="#how-it-works">
                  <Button variant="outline-white" size="lg">
                    Learn How it Works
                  </Button>
                </a>
              </div>

              {/* Trust badges */}
              <div className="flex flex-wrap items-center gap-6 mt-12 animate-fade-in-up delay-400">
                {['HIPAA Compliant', 'Verified NGOs', 'Free to Join'].map((badge) => (
                  <div key={badge} className="flex items-center gap-2">
                    <div className="w-5 h-5 rounded-full bg-[var(--color-accent)] flex items-center justify-center flex-shrink-0">
                      <FiCheck size={11} className="text-white font-bold" />
                    </div>
                    <span className="text-white/70 text-sm font-medium">{badge}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Right: Floating Card Mockup */}
            <div className="hidden lg:flex justify-center items-center">
              <div className="relative">
                {/* Main card */}
                <div className="w-80 rounded-[var(--radius-xl)] glass p-6 animate-float shadow-[var(--shadow-lg)]">
                  <div className="flex items-center gap-3 mb-4">
                    <Logo variant="icon" size="sm" />
                    <div>
                      <p className="text-white font-bold text-sm">MediShare</p>
                      <p className="text-white/60 text-xs">Equipment Donated</p>
                    </div>
                    <span className="ml-auto text-[var(--color-accent)] text-xs font-bold px-2 py-1 bg-teal-500/20 rounded-full">Live</span>
                  </div>
                  {[
                    { name: 'Wheelchair', donor: 'City Hospital', qty: 5 },
                    { name: 'Oxygen Tank', donor: 'Hope NGO', qty: 12 },
                    { name: 'Stethoscope', donor: 'Dr. Mehta', qty: 8 },
                  ].map((item) => (
                    <div key={item.name} className="flex items-center gap-3 py-3 border-b border-white/10 last:border-0">
                      <div className="w-8 h-8 rounded-lg bg-[var(--color-primary)]/30 flex items-center justify-center">
                        <FiPackage size={14} className="text-[var(--color-primary-light)]" />
                      </div>
                      <div className="flex-1">
                        <p className="text-white text-sm font-semibold">{item.name}</p>
                        <p className="text-white/50 text-xs">{item.donor}</p>
                      </div>
                      <span className="text-[var(--color-accent)] text-sm font-bold">×{item.qty}</span>
                    </div>
                  ))}
                </div>

                {/* Floating badge top-right */}
                <div className="absolute -top-4 -right-4 glass rounded-[var(--radius-md)] px-4 py-3 animate-float"
                     style={{ animationDelay: '0.7s' }}>
                  <p className="text-white text-xs font-medium">Equipment Shared</p>
                  <p className="text-[var(--color-accent)] text-2xl font-black">2,400+</p>
                </div>

                {/* Floating badge bottom-left */}
                <div className="absolute -bottom-4 -left-4 glass rounded-[var(--radius-md)] px-4 py-3 animate-float"
                     style={{ animationDelay: '1.2s' }}>
                  <p className="text-white text-xs font-medium">NGOs Connected</p>
                  <p className="text-[var(--color-primary-light)] text-2xl font-black">180+</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Wave divider */}
        <div className="absolute bottom-0 left-0 right-0">
          <svg viewBox="0 0 1440 80" fill="none" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none">
            <path d="M0,40 C360,80 1080,0 1440,40 L1440,80 L0,80 Z" fill="white"/>
          </svg>
        </div>
      </section>

      {/* ── STATS ──────────────────────────────────────────── */}
      <section className="py-16 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-8">
            {[
              { label: 'Equipment Shared',  end: 2400, suffix: '+', icon: <FiPackage size={20} />, color: 'text-[var(--color-primary)]' },
              { label: 'Hospitals Joined',  end: 320,  suffix: '+', icon: <FiActivity size={20} />, color: 'text-[var(--color-accent)]' },
              { label: 'NGO Partners',      end: 180,  suffix: '+', icon: <FiUsers size={20} />, color: 'text-[var(--color-primary)]' },
              { label: 'Lives Impacted',    end: 15000, suffix: '+', icon: <FiHeart size={20} />, color: 'text-[var(--color-accent)]' },
            ].map((stat) => (
              <div key={stat.label} className="text-center">
                <div className={`flex justify-center mb-2 ${stat.color}`}>{stat.icon}</div>
                <div className={`text-4xl sm:text-5xl font-black mb-1 ${stat.color}`}>
                  <Counter end={stat.end} suffix={stat.suffix} />
                </div>
                <p className="text-[var(--color-text-muted)] text-sm font-medium">{stat.label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── FEATURES ───────────────────────────────────────── */}
      <section id="features" className="py-24 bg-[var(--color-surface)]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <span className="text-sm font-bold text-[var(--color-primary)] uppercase tracking-widest">Features</span>
            <h2 className="text-4xl sm:text-5xl font-black text-[var(--color-text)] mt-3 mb-4">
              Everything you need to{' '}
              <span className="gradient-text">share care</span>
            </h2>
            <p className="text-[var(--color-text-muted)] max-w-xl mx-auto leading-relaxed">
              A complete platform for medical equipment donation, request management, and healthcare networking.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              {
                icon: <FiHeart size={22} className="text-pink-500" />,
                title: 'Donate Equipment',
                desc: 'Easily list unused medical equipment for donation. Reach hospitals and NGOs that need it most.',
                color: 'bg-pink-50',
                delay: 0,
              },
              {
                icon: <FiShare2 size={22} className="text-blue-500" />,
                title: 'Request Resources',
                desc: 'Submit equipment requests and get matched with donors in your region within hours.',
                color: 'bg-blue-50',
                delay: 100,
              },
              {
                icon: <FiActivity size={22} className="text-teal-500" />,
                title: 'Real-Time Tracking',
                desc: 'Monitor donation and request statuses in real time with full transparency.',
                color: 'bg-teal-50',
                delay: 200,
              },
              {
                icon: <FiTruck size={22} className="text-orange-500" />,
                title: 'Hospital Network',
                desc: 'Connect with a verified network of hospitals, clinics, and healthcare providers.',
                color: 'bg-orange-50',
                delay: 300,
              },
              {
                icon: <FiMessageSquare size={22} className="text-purple-500" />,
                title: 'AI Health Chatbot',
                desc: 'Get instant answers about equipment availability and donation processes via our AI assistant.',
                color: 'bg-purple-50',
                delay: 400,
              },
              {
                icon: <FiBell size={22} className="text-indigo-500" />,
                title: 'Smart Notifications',
                desc: 'Stay updated with real-time alerts for donation matches, approvals, and urgent requests.',
                color: 'bg-indigo-50',
                delay: 500,
              },
            ].map((f) => (
              <FeatureCard key={f.title} {...f} />
            ))}
          </div>
        </div>
      </section>

      {/* ── HOW IT WORKS ───────────────────────────────────── */}
      <section id="how-it-works" className="py-24 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-20 items-center">

            <div>
              <span className="text-sm font-bold text-[var(--color-primary)] uppercase tracking-widest">How it Works</span>
              <h2 className="text-4xl sm:text-5xl font-black text-[var(--color-text)] mt-3 mb-4">
                Get started in{' '}
                <span className="gradient-text">3 simple steps</span>
              </h2>
              <p className="text-[var(--color-text-muted)] leading-relaxed mb-12">
                MediShare makes it effortless to connect donors with those in need.
                No complicated processes, just meaningful impact.
              </p>

              <div>
                {[
                  {
                    step: 1,
                    icon: <FiUsers size={18} />,
                    title: 'Create Your Account',
                    desc: 'Sign up as a Donor, Hospital, or NGO. Your role determines your access to the platform\'s features.',
                    isLast: false,
                  },
                  {
                    step: 2,
                    icon: <FiPackage size={18} />,
                    title: 'List or Request Equipment',
                    desc: 'Donors list available equipment with details. Recipients submit requests specifying what they need.',
                    isLast: false,
                  },
                  {
                    step: 3,
                    icon: <FiZap size={18} />,
                    title: 'Connect & Deliver Impact',
                    desc: 'Our platform matches donors with recipients. Track the process end-to-end and receive confirmation.',
                    isLast: true,
                  },
                ].map((s) => (
                  <StepCard key={s.step} {...s} />
                ))}
              </div>
            </div>

            {/* Visual Panel */}
            <div className="relative hidden lg:block">
              <div className="rounded-[var(--radius-xl)] gradient-hero p-8 relative overflow-hidden">
                <div className="absolute top-0 right-0 w-48 h-48 opacity-10"
                     style={{ background: 'radial-gradient(circle, #2ecfb3, transparent)' }} />
                <div className="space-y-4">
                  {['Wheelchair donated ✓', 'NGO Hope matched ✓', 'Delivery confirmed ✓'].map((t, i) => (
                    <div key={t} className="glass rounded-[var(--radius-lg)] p-4 flex items-center gap-3"
                         style={{ animationDelay: `${i * 0.3}s` }}>
                      <div className="w-8 h-8 rounded-full bg-[var(--color-accent)] flex items-center justify-center flex-shrink-0">
                        <FiCheck size={14} className="text-white" />
                      </div>
                      <p className="text-white font-medium text-sm">{t}</p>
                    </div>
                  ))}
                </div>
                <div className="mt-8 pt-6 border-t border-white/20 text-center">
                  <p className="text-white/60 text-sm mb-1">Total Impact This Month</p>
                  <p className="text-white text-5xl font-black">847</p>
                  <p className="text-[var(--color-accent)] text-sm font-semibold mt-1">equipment items shared</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── TESTIMONIALS ───────────────────────────────────── */}
      <section className="py-24 bg-[var(--color-surface)]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <span className="text-sm font-bold text-[var(--color-primary)] uppercase tracking-widest">Testimonials</span>
            <h2 className="text-4xl sm:text-5xl font-black text-[var(--color-text)] mt-3 mb-4">
              Trusted by <span className="gradient-text">healthcare heroes</span>
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {[
              {
                name: 'Dr. Priya Mehta',
                role: 'Head of Procurement',
                org: 'City General Hospital',
                quote: 'MediShare helped us acquire 20 wheelchairs for our rehab ward in under a week. The process was seamless and completely transparent.',
                avatar: 'P',
              },
              {
                name: 'Rajesh Kumar',
                role: 'Director',
                org: 'Aarogya NGO',
                quote: 'We\'ve been able to serve 3x more patients since joining MediShare. The equipment matching system is incredibly efficient.',
                avatar: 'R',
              },
              {
                name: 'Sunita Sharma',
                role: 'Donor',
                org: 'Private Contributor',
                quote: 'I donated my father\'s unused medical equipment and within days it was helping a family in need. This platform is truly life-changing.',
                avatar: 'S',
              },
            ].map((t) => (
              <TestimonialCard key={t.name} {...t} />
            ))}
          </div>
        </div>
      </section>

      {/* ── CTA BANNER ─────────────────────────────────────── */}
      <section id="about" className="py-24 relative overflow-hidden">
        <div className="absolute inset-0 gradient-primary animate-gradient" />
        <div className="absolute inset-0 opacity-20"
             style={{ backgroundImage: 'radial-gradient(circle at 20% 50%, rgba(255,255,255,0.3) 0%, transparent 50%), radial-gradient(circle at 80% 50%, rgba(255,255,255,0.2) 0%, transparent 50%)' }} />

        <div className="max-w-4xl mx-auto px-4 text-center relative z-10">
          <div className="w-16 h-16 rounded-[var(--radius-lg)] bg-white/20 flex items-center justify-center mx-auto mb-6">
            <Logo variant="icon" size="md" />
          </div>

          <h2 className="text-4xl sm:text-5xl font-black text-white mb-6 leading-tight">
            Ready to make a difference?
          </h2>
          <p className="text-white/80 text-lg mb-10 max-w-xl mx-auto leading-relaxed">
            Join 500+ healthcare organizations on MediShare. Start donating or
            requesting medical equipment today — it's completely free.
          </p>

          <div className="flex flex-wrap gap-4 justify-center">
            <Link to="/register">
              <Button
                variant="accent"
                size="lg"
                className="bg-white text-[var(--color-primary)] hover:bg-white/90 shadow-xl"
                rightIcon={<FiArrowRight />}
              >
                Join MediShare Free
              </Button>
            </Link>
            <Link to="/login">
              <Button variant="outline-white" size="lg">
                Sign In
              </Button>
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
