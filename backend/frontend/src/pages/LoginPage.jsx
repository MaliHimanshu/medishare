// src/pages/LoginPage.jsx
import { useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { toast } from 'react-toastify';
import { FiMail, FiArrowRight, FiCheck } from 'react-icons/fi';
import Input from '../components/ui/Input';
import Button from '../components/ui/Button';
import Logo from '../components/ui/Logo';
import { useAuth } from '../context/AuthContext';

// ── Form Validation ────────────────────────────────────────────
function validate(fields) {
  const errors = {};
  if (!fields.email.trim()) {
    errors.email = 'Email is required';
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(fields.email)) {
    errors.email = 'Enter a valid email address';
  }
  if (!fields.password) {
    errors.password = 'Password is required';
  } else if (fields.password.length < 6) {
    errors.password = 'Password must be at least 6 characters';
  }
  return errors;
}

export default function LoginPage() {
  const { login, isLoading } = useAuth();
  const navigate = useNavigate();
  const location  = useLocation();
  const from = location.state?.from?.pathname || '/dashboard';

  const [fields, setFields] = useState({ email: '', password: '' });
  const [errors, setErrors] = useState({});
  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFields((prev) => ({ ...prev, [name]: value }));
    // Clear field error on change
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const validation = validate(fields);
    if (Object.keys(validation).length) {
      setErrors(validation);
      return;
    }
    setLoading(true);
    const result = await login(fields.email, fields.password);
    setLoading(false);

    if (result.success) {
      toast.success('Welcome back! 🎉');
      navigate(from, { replace: true });
    } else {
      toast.error(result.message || 'Login failed');
    }
  };

  return (
    <div className="min-h-screen flex">

      {/* ── Left Panel (Brand) ───────────────────────────── */}
      <div className="hidden lg:flex lg:w-1/2 gradient-hero relative overflow-hidden flex-col justify-between p-12">
        {/* Background orbs */}
        <div className="absolute top-20 left-20 w-64 h-64 rounded-full opacity-20 animate-float"
             style={{ background: 'radial-gradient(circle, #3b6cf8 0%, transparent 70%)' }} />
        <div className="absolute bottom-20 right-10 w-80 h-80 rounded-full opacity-15 animate-float"
             style={{ background: 'radial-gradient(circle, #2ecfb3 0%, transparent 70%)', animationDelay: '1s' }} />

        {/* Logo */}
        <div className="relative z-10">
          <Link to="/">
            <Logo variant="full" size="md" className="brightness-0 invert" />
          </Link>
        </div>

        {/* Center Content */}
        <div className="relative z-10">
          <h2 className="text-4xl font-black text-white mb-4 leading-tight">
            Welcome back to<br />
            <span style={{ color: 'var(--color-accent)' }}>MediShare</span>
          </h2>
          <p className="text-white/65 text-lg leading-relaxed mb-8">
            Continue connecting with hospitals, NGOs, and donors to make healthcare more accessible.
          </p>
          {[
            'Real-time equipment matching',
            'Verified healthcare network',
            'Impact tracking dashboard',
          ].map((item) => (
            <div key={item} className="flex items-center gap-3 mb-4">
              <div className="w-5 h-5 rounded-full bg-[var(--color-accent)] flex items-center justify-center flex-shrink-0">
                <FiCheck size={11} className="text-white" />
              </div>
              <span className="text-white/80 text-sm font-medium">{item}</span>
            </div>
          ))}
        </div>

        {/* Bottom Quote */}
        <div className="relative z-10 glass rounded-[var(--radius-lg)] p-5">
          <p className="text-white/80 text-sm italic mb-3">
            "MediShare helped us get critical equipment for our patients in record time."
          </p>
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-full gradient-primary flex items-center justify-center text-white text-xs font-bold">P</div>
            <div>
              <p className="text-white text-sm font-semibold">Dr. Priya Mehta</p>
              <p className="text-white/50 text-xs">City General Hospital</p>
            </div>
          </div>
        </div>
      </div>

      {/* ── Right Panel (Form) ───────────────────────────── */}
      <div className="flex-1 flex items-center justify-center p-6 sm:p-12 bg-white">
        <div className="w-full max-w-md animate-fade-in">

          {/* Mobile Logo */}
          <div className="lg:hidden mb-8 text-center">
            <Link to="/">
              <Logo variant="full" size="lg" className="mx-auto" />
            </Link>
          </div>

          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-black text-[var(--color-text)] mb-2">Sign in</h1>
            <p className="text-[var(--color-text-muted)] text-sm">
              Don't have an account?{' '}
              <Link to="/register" className="text-[var(--color-primary)] font-semibold hover:underline">
                Create one free
              </Link>
            </p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-5" noValidate>
            <Input
              label="Email Address"
              name="email"
              type="email"
              placeholder="you@example.com"
              value={fields.email}
              onChange={handleChange}
              error={errors.email}
              leftIcon={<FiMail size={17} />}
              required
              autoComplete="email"
              autoFocus
            />

            <div>
              <Input
                label="Password"
                name="password"
                type="password"
                placeholder="Enter your password"
                value={fields.password}
                onChange={handleChange}
                error={errors.password}
                required
                autoComplete="current-password"
              />
              <div className="mt-2 text-right">
                <Link
                  to="/forgot-password"
                  className="text-xs text-[var(--color-primary)] hover:underline font-semibold"
                >
                  Forgot password?
                </Link>
              </div>
            </div>

            <Button
              type="submit"
              variant="primary"
              size="lg"
              fullWidth
              loading={loading || isLoading}
              rightIcon={<FiArrowRight size={18} />}
            >
              Sign In
            </Button>
          </form>

          {/* Divider */}
          <div className="flex items-center gap-4 my-6">
            <div className="flex-1 h-px bg-[var(--color-border)]" />
            <span className="text-xs text-[var(--color-text-muted)] font-medium">OR</span>
            <div className="flex-1 h-px bg-[var(--color-border)]" />
          </div>

          {/* Register Link */}
          <p className="text-center text-sm text-[var(--color-text-muted)]">
            New to MediShare?{' '}
            <Link to="/register" className="text-[var(--color-primary)] font-semibold hover:underline">
              Register as Donor, NGO, or Hospital →
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
