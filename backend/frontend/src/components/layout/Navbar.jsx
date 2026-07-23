// src/components/layout/Navbar.jsx
import { useState, useEffect } from 'react';
import { Link, NavLink, useNavigate } from 'react-router-dom';
import { FiMenu, FiX, FiLogOut, FiUser, FiGrid } from 'react-icons/fi';
import Logo from '../ui/Logo';
import Button from '../ui/Button';
import { useAuth } from '../../context/AuthContext';

const navLinks = [
  { label: 'Features',     href: '/#features' },
  { label: 'How it Works', href: '/#how-it-works' },
  { label: 'About',        href: '/#about' },
];

export default function Navbar() {
  const [scrolled,    setScrolled]    = useState(false);
  const [mobileOpen,  setMobileOpen]  = useState(false);
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const { isAuthenticated, user, logout } = useAuth();
  const navigate = useNavigate();

  // Scroll effect
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const handleLogout = () => {
    logout();
    setUserMenuOpen(false);
    navigate('/');
  };

  const roleBadgeColor = {
    ADMIN:     'bg-purple-100 text-purple-700',
    DONOR:     'bg-blue-100 text-blue-700',
    NGO:       'bg-teal-100 text-teal-700',
    RECIPIENT: 'bg-orange-100 text-orange-700',
  };

  return (
    <>
      <nav
        className={`
          fixed top-0 left-0 right-0 z-50
          transition-all duration-300
          ${scrolled
            ? 'bg-white/95 backdrop-blur-xl shadow-[var(--shadow-md)] py-3'
            : 'bg-transparent py-5'
          }
        `}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between">

            {/* Logo */}
            <Link to="/" className="flex-shrink-0" onClick={() => setMobileOpen(false)}>
              <Logo
                variant="full"
                size="md"
                className={scrolled ? '' : 'brightness-0 invert'}
              />
            </Link>

            {/* Desktop Nav Links */}
            <div className="hidden md:flex items-center gap-8">
              {navLinks.map((link) => (
                <a
                  key={link.label}
                  href={link.href}
                  className={`
                    text-sm font-semibold transition-colors duration-200
                    ${scrolled
                      ? 'text-[var(--color-text-muted)] hover:text-[var(--color-primary)]'
                      : 'text-white/80 hover:text-white'
                    }
                  `}
                >
                  {link.label}
                </a>
              ))}
            </div>

            {/* Desktop CTA */}
            <div className="hidden md:flex items-center gap-3">
              {isAuthenticated ? (
                <div className="relative">
                  <button
                    onClick={() => setUserMenuOpen((v) => !v)}
                    className={`
                      flex items-center gap-2 px-4 py-2 rounded-full
                      border transition-all duration-200
                      ${scrolled
                        ? 'border-[var(--color-border)] text-[var(--color-text)] hover:border-[var(--color-primary)]'
                        : 'border-white/30 text-white hover:bg-white/10'
                      }
                    `}
                  >
                    <div className="w-7 h-7 rounded-full gradient-primary flex items-center justify-center text-white text-xs font-bold">
                      {user?.name?.charAt(0)?.toUpperCase() || 'U'}
                    </div>
                    <span className="text-sm font-semibold max-w-[120px] truncate">{user?.name}</span>
                  </button>

                  {/* Dropdown */}
                  {userMenuOpen && (
                    <div className="absolute right-0 top-full mt-2 w-56 bg-white rounded-[var(--radius-lg)] shadow-[var(--shadow-lg)] border border-[var(--color-border)] py-2 animate-scale-in">
                      <div className="px-4 py-3 border-b border-[var(--color-border)]">
                        <p className="font-semibold text-sm text-[var(--color-text)] truncate">{user?.name}</p>
                        <p className="text-xs text-[var(--color-text-muted)] truncate">{user?.email}</p>
                        <span className={`mt-1 inline-block text-xs px-2 py-0.5 rounded-full font-semibold ${roleBadgeColor[user?.role] || 'bg-gray-100 text-gray-700'}`}>
                          {user?.role}
                        </span>
                      </div>
                      <Link
                        to="/dashboard"
                        onClick={() => setUserMenuOpen(false)}
                        className="flex items-center gap-2 px-4 py-2.5 text-sm text-[var(--color-text)] hover:bg-[var(--color-surface)] transition-colors"
                      >
                        <FiGrid size={15} /> Dashboard
                      </Link>
                      <button
                        onClick={handleLogout}
                        className="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-[var(--color-error)] hover:bg-red-50 transition-colors"
                      >
                        <FiLogOut size={15} /> Sign Out
                      </button>
                    </div>
                  )}
                </div>
              ) : (
                <>
                  <NavLink to="/login">
                    <Button
                      variant={scrolled ? 'ghost' : 'outline-white'}
                      size="sm"
                    >
                      Login
                    </Button>
                  </NavLink>
                  <NavLink to="/register">
                    <Button variant="primary" size="sm">
                      Get Started
                    </Button>
                  </NavLink>
                </>
              )}
            </div>

            {/* Mobile Hamburger */}
            <button
              onClick={() => setMobileOpen((v) => !v)}
              className={`md:hidden p-2 rounded-lg transition-colors ${scrolled ? 'text-[var(--color-text)]' : 'text-white'}`}
            >
              {mobileOpen ? <FiX size={24} /> : <FiMenu size={24} />}
            </button>
          </div>
        </div>
      </nav>

      {/* Mobile Drawer */}
      {mobileOpen && (
        <div
          className="fixed inset-0 z-40 md:hidden"
          onClick={() => setMobileOpen(false)}
        >
          <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" />
          <div
            className="absolute top-0 right-0 h-full w-72 bg-white shadow-2xl animate-slide-right pt-20 px-6"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex flex-col gap-2">
              {navLinks.map((link) => (
                <a
                  key={link.label}
                  href={link.href}
                  onClick={() => setMobileOpen(false)}
                  className="text-[var(--color-text)] font-semibold py-3 px-4 rounded-xl hover:bg-[var(--color-surface-2)] transition-colors"
                >
                  {link.label}
                </a>
              ))}

              <div className="mt-4 border-t border-[var(--color-border)] pt-4 flex flex-col gap-3">
                {isAuthenticated ? (
                  <>
                    <div className="flex items-center gap-3 px-4 py-3 bg-[var(--color-surface)] rounded-xl">
                      <div className="w-10 h-10 rounded-full gradient-primary flex items-center justify-center text-white font-bold">
                        {user?.name?.charAt(0)?.toUpperCase() || 'U'}
                      </div>
                      <div>
                        <p className="font-semibold text-sm">{user?.name}</p>
                        <p className="text-xs text-[var(--color-text-muted)]">{user?.role}</p>
                      </div>
                    </div>
                    <Link
                      to="/dashboard"
                      onClick={() => setMobileOpen(false)}
                      className="flex items-center gap-2 px-4 py-3 rounded-xl hover:bg-[var(--color-surface-2)] transition-colors text-sm font-semibold text-[var(--color-text)]"
                    >
                      <FiGrid /> Dashboard
                    </Link>
                    <button
                      onClick={handleLogout}
                      className="flex items-center gap-2 px-4 py-3 rounded-xl hover:bg-red-50 transition-colors text-sm font-semibold text-[var(--color-error)]"
                    >
                      <FiLogOut /> Sign Out
                    </button>
                  </>
                ) : (
                  <>
                    <NavLink to="/login" onClick={() => setMobileOpen(false)}>
                      <Button variant="secondary" size="md" fullWidth>Login</Button>
                    </NavLink>
                    <NavLink to="/register" onClick={() => setMobileOpen(false)}>
                      <Button variant="primary" size="md" fullWidth>Get Started</Button>
                    </NavLink>
                  </>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Click outside to close user menu */}
      {userMenuOpen && (
        <div className="fixed inset-0 z-40" onClick={() => setUserMenuOpen(false)} />
      )}
    </>
  );
}
