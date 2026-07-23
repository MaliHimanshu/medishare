// src/pages/RegisterPage.jsx
import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { toast } from 'react-toastify';
import { FiMail, FiUser, FiPhone, FiMapPin, FiArrowRight, FiCheck } from 'react-icons/fi';
import Input from '../components/ui/Input';
import Button from '../components/ui/Button';
import Logo from '../components/ui/Logo';
import { useAuth } from '../context/AuthContext';

// ── Role Config ─────────────────────────────────────────────
const roles = [
  {
    value: 'DONOR',
    label: 'Donor',
    icon: '🤲',
    desc: 'Donate unused medical equipment',
    color: 'border-blue-200 hover:border-blue-500 hover:bg-blue-50',
    activeColor: 'border-blue-500 bg-blue-50',
    badge: 'bg-blue-100 text-blue-700',
  },
  {
    value: 'NGO',
    label: 'NGO',
    icon: '🏢',
    desc: 'Request equipment for your organization',
    color: 'border-teal-200 hover:border-teal-500 hover:bg-teal-50',
    activeColor: 'border-teal-500 bg-teal-50',
    badge: 'bg-teal-100 text-teal-700',
  },
  {
    value: 'RECIPIENT',
    label: 'Hospital / Clinic',
    icon: '🏥',
    desc: 'Procure equipment for patient care',
    color: 'border-purple-200 hover:border-purple-500 hover:bg-purple-50',
    activeColor: 'border-purple-500 bg-purple-50',
    badge: 'bg-purple-100 text-purple-700',
  },
];

// ── Validation ──────────────────────────────────────────────
function validate(fields) {
  const errors = {};
  if (!fields.name.trim()) errors.name = 'Full name is required';
  if (!fields.email.trim()) {
    errors.email = 'Email is required';
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(fields.email)) {
    errors.email = 'Enter a valid email address';
  }
  if (fields.phone && !/^\d{10}$/.test(fields.phone.replace(/\D/g, ''))) {
    errors.phone = 'Enter a valid 10-digit phone number';
  }
  if (!fields.password) {
    errors.password = 'Password is required';
  } else if (fields.password.length < 8) {
    errors.password = 'Password must be at least 8 characters';
  } else if (!/(?=.*[A-Z])(?=.*\d)/.test(fields.password)) {
    errors.password = 'Must include at least one uppercase letter and one number';
  }
  if (!fields.confirmPassword) {
    errors.confirmPassword = 'Please confirm your password';
  } else if (fields.password !== fields.confirmPassword) {
    errors.confirmPassword = 'Passwords do not match';
  }
  return errors;
}

export default function RegisterPage() {
  const { register } = useAuth();
  const navigate = useNavigate();

  const [fields, setFields] = useState({
    name: '',
    email: '',
    phone: '',
    address: '',
    password: '',
    confirmPassword: '',
  });
  const [selectedRole, setSelectedRole] = useState('DONOR');
  const [errors, setErrors]   = useState({});
  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFields((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const validation = validate(fields);
    if (Object.keys(validation).length) {
      setErrors(validation);
      toast.error('Please fix the form errors');
      return;
    }
    setLoading(true);
    const payload = {
      name: fields.name.trim(),
      email: fields.email.trim(),
      password: fields.password,
      role: selectedRole,
      ...(fields.phone && { phone: fields.phone.trim() }),
      ...(fields.address && { address: fields.address.trim() }),
    };
    const result = await register(payload);
    setLoading(false);

    if (result.success) {
      toast.success('Account created! Welcome to MediShare 🎉');
      navigate('/dashboard', { replace: true });
    } else {
      toast.error(result.message || 'Registration failed. Please try again.');
    }
  };

  const passwordStrength = (() => {
    const p = fields.password;
    if (!p) return 0;
    let score = 0;
    if (p.length >= 8) score++;
    if (/[A-Z]/.test(p)) score++;
    if (/[0-9]/.test(p)) score++;
    if (/[^A-Za-z0-9]/.test(p)) score++;
    return score;
  })();

  const strengthLabel  = ['', 'Weak', 'Fair', 'Good', 'Strong'][passwordStrength];
  const strengthColor  = ['', 'bg-red-400', 'bg-yellow-400', 'bg-blue-400', 'bg-green-400'][passwordStrength];

  return (
    <div className="min-h-screen flex">

      {/* ── Left Panel (Brand) ───────────────────────────── */}
      <div className="hidden lg:flex lg:w-2/5 gradient-hero relative overflow-hidden flex-col justify-between p-12">
        <div className="absolute top-20 left-20 w-64 h-64 rounded-full opacity-20 animate-float"
             style={{ background: 'radial-gradient(circle, #3b6cf8 0%, transparent 70%)' }} />
        <div className="absolute bottom-20 right-10 w-72 h-72 rounded-full opacity-15 animate-float"
             style={{ background: 'radial-gradient(circle, #2ecfb3 0%, transparent 70%)', animationDelay: '1s' }} />

        <div className="relative z-10">
          <Link to="/">
            <Logo variant="full" size="md" className="brightness-0 invert" />
          </Link>
        </div>

        <div className="relative z-10">
          <h2 className="text-3xl font-black text-white mb-4 leading-tight">
            Join the largest<br />
            <span style={{ color: 'var(--color-accent)' }}>medical sharing</span><br />
            network in India
          </h2>
          <p className="text-white/65 text-base leading-relaxed mb-8">
            Create your free account and start connecting with healthcare organizations today.
          </p>

          <div className="space-y-3">
            {[
              { icon: '🔒', text: 'Secure & verified accounts' },
              { icon: '⚡', text: 'Get matched in minutes' },
              { icon: '📊', text: 'Real-time impact tracking' },
              { icon: '🤝', text: '500+ trusted organizations' },
            ].map((item) => (
              <div key={item.text} className="flex items-center gap-3">
                <span className="text-xl">{item.icon}</span>
                <span className="text-white/75 text-sm font-medium">{item.text}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="relative z-10 glass rounded-[var(--radius-lg)] p-5">
          <div className="flex items-center gap-2 mb-2">
            {[...Array(5)].map((_, i) => (
              <span key={i} className="text-yellow-400 text-sm">★</span>
            ))}
            <span className="text-white/60 text-xs ml-1">4.9/5</span>
          </div>
          <p className="text-white/80 text-sm italic mb-3">
            "The best platform for medical equipment sharing. We've helped 200+ patients."
          </p>
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-full gradient-primary flex items-center justify-center text-white text-xs font-bold">R</div>
            <div>
              <p className="text-white text-sm font-semibold">Rajesh Kumar</p>
              <p className="text-white/50 text-xs">Aarogya NGO</p>
            </div>
          </div>
        </div>
      </div>

      {/* ── Right Panel (Form) ───────────────────────────── */}
      <div className="flex-1 flex items-start justify-center p-6 sm:p-12 bg-white overflow-y-auto">
        <div className="w-full max-w-lg py-8 animate-fade-in">

          {/* Mobile Logo */}
          <div className="lg:hidden mb-8 text-center">
            <Link to="/">
              <Logo variant="full" size="lg" className="mx-auto" />
            </Link>
          </div>

          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-black text-[var(--color-text)] mb-2">Create account</h1>
            <p className="text-[var(--color-text-muted)] text-sm">
              Already have an account?{' '}
              <Link to="/login" className="text-[var(--color-primary)] font-semibold hover:underline">
                Sign in here
              </Link>
            </p>
          </div>

          {/* Role Selector */}
          <div className="mb-6">
            <label className="block text-sm font-bold text-[var(--color-text)] mb-3">
              I am joining as <span className="text-[var(--color-error)]">*</span>
            </label>
            <div className="grid grid-cols-3 gap-3">
              {roles.map((role) => (
                <button
                  key={role.value}
                  type="button"
                  onClick={() => setSelectedRole(role.value)}
                  className={`
                    flex flex-col items-center gap-1.5 p-3 rounded-[var(--radius-md)]
                    border-2 transition-all duration-200 text-center
                    ${selectedRole === role.value ? role.activeColor : `border-[var(--color-border)] ${role.color}`}
                  `}
                >
                  <span className="text-2xl">{role.icon}</span>
                  <span className="text-xs font-bold text-[var(--color-text)]">{role.label}</span>
                  <span className="text-[10px] text-[var(--color-text-muted)] leading-tight hidden sm:block">{role.desc}</span>
                  {selectedRole === role.value && (
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${role.badge}`}>
                      Selected ✓
                    </span>
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4" noValidate>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Input
                label="Full Name"
                name="name"
                type="text"
                placeholder="John Doe"
                value={fields.name}
                onChange={handleChange}
                error={errors.name}
                leftIcon={<FiUser size={17} />}
                required
                autoFocus
              />
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
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Input
                label="Phone Number"
                name="phone"
                type="tel"
                placeholder="9876543210"
                value={fields.phone}
                onChange={handleChange}
                error={errors.phone}
                leftIcon={<FiPhone size={17} />}
                hint="Optional"
              />
              <Input
                label="Address / City"
                name="address"
                type="text"
                placeholder="Ahmedabad, Gujarat"
                value={fields.address}
                onChange={handleChange}
                error={errors.address}
                leftIcon={<FiMapPin size={17} />}
                hint="Optional"
              />
            </div>

            {/* Password + Strength */}
            <div>
              <Input
                label="Password"
                name="password"
                type="password"
                placeholder="Min 8 chars, uppercase + number"
                value={fields.password}
                onChange={handleChange}
                error={errors.password}
                required
              />
              {fields.password && (
                <div className="mt-2 flex items-center gap-2">
                  <div className="flex-1 flex gap-1">
                    {[1, 2, 3, 4].map((s) => (
                      <div
                        key={s}
                        className={`h-1.5 flex-1 rounded-full transition-all duration-300 ${
                          s <= passwordStrength ? strengthColor : 'bg-gray-200'
                        }`}
                      />
                    ))}
                  </div>
                  <span className={`text-xs font-semibold ${
                    passwordStrength <= 1 ? 'text-red-500'
                    : passwordStrength === 2 ? 'text-yellow-500'
                    : passwordStrength === 3 ? 'text-blue-500'
                    : 'text-green-500'
                  }`}>
                    {strengthLabel}
                  </span>
                </div>
              )}
            </div>

            <Input
              label="Confirm Password"
              name="confirmPassword"
              type="password"
              placeholder="Repeat your password"
              value={fields.confirmPassword}
              onChange={handleChange}
              error={errors.confirmPassword}
              required
            />

            <Button
              type="submit"
              variant="primary"
              size="lg"
              fullWidth
              loading={loading}
              rightIcon={<FiArrowRight size={18} />}
              className="mt-6"
            >
              Create Free Account
            </Button>

            <p className="text-center text-xs text-[var(--color-text-muted)]">
              By registering, you agree to our{' '}
              <a href="#" className="text-[var(--color-primary)] hover:underline">Terms of Service</a>{' '}
              and{' '}
              <a href="#" className="text-[var(--color-primary)] hover:underline">Privacy Policy</a>.
            </p>
          </form>
        </div>
      </div>
    </div>
  );
}
