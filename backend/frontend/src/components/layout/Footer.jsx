// src/components/layout/Footer.jsx
import { Link } from 'react-router-dom';
import Logo from '../ui/Logo';
import { FiGithub, FiTwitter, FiLinkedin, FiMail } from 'react-icons/fi';

const footerLinks = {
  Product: [
    { label: 'Features',   href: '/#features' },
    { label: 'How it Works', href: '/#how-it-works' },
    { label: 'Dashboard',  href: '/dashboard' },
  ],
  Company: [
    { label: 'About Us',  href: '/#about' },
    { label: 'Contact',   href: 'mailto:hello@medishare.app' },
    { label: 'Blog',      href: '#' },
  ],
  Legal: [
    { label: 'Privacy Policy', href: '#' },
    { label: 'Terms of Service', href: '#' },
    { label: 'Cookie Policy',  href: '#' },
  ],
};

const socials = [
  { icon: <FiGithub size={18} />,   href: '#', label: 'GitHub' },
  { icon: <FiTwitter size={18} />,  href: '#', label: 'Twitter' },
  { icon: <FiLinkedin size={18} />, href: '#', label: 'LinkedIn' },
  { icon: <FiMail size={18} />,     href: 'mailto:hello@medishare.app', label: 'Email' },
];

export default function Footer() {
  return (
    <footer className="bg-[var(--color-dark)] text-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

        {/* Top Section */}
        <div className="py-16 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-12">

          {/* Brand Column */}
          <div className="lg:col-span-2">
            <Logo variant="full" size="md" className="brightness-0 invert mb-4" />
            <p className="text-white/60 text-sm leading-relaxed max-w-xs mt-4">
              Smart Medical Equipment Network connecting hospitals, NGOs, and donors
              to build a stronger healthcare ecosystem.
            </p>

            {/* Socials */}
            <div className="flex items-center gap-3 mt-6">
              {socials.map((s) => (
                <a
                  key={s.label}
                  href={s.href}
                  aria-label={s.label}
                  className="
                    w-9 h-9 rounded-full
                    bg-white/10 hover:bg-[var(--color-primary)]
                    flex items-center justify-center
                    text-white/70 hover:text-white
                    transition-all duration-200
                  "
                >
                  {s.icon}
                </a>
              ))}
            </div>
          </div>

          {/* Link Columns */}
          {Object.entries(footerLinks).map(([title, links]) => (
            <div key={title}>
              <h4 className="text-sm font-bold text-white mb-4 uppercase tracking-wider">
                {title}
              </h4>
              <ul className="flex flex-col gap-3">
                {links.map((link) => (
                  <li key={link.label}>
                    {link.href.startsWith('mailto') || link.href.startsWith('#') ? (
                      <a
                        href={link.href}
                        className="text-sm text-white/60 hover:text-[var(--color-accent)] transition-colors"
                      >
                        {link.label}
                      </a>
                    ) : (
                      <Link
                        to={link.href}
                        className="text-sm text-white/60 hover:text-[var(--color-accent)] transition-colors"
                      >
                        {link.label}
                      </Link>
                    )}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Divider */}
        <div className="border-t border-white/10" />

        {/* Bottom Bar */}
        <div className="py-6 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-sm text-white/50">
            © {new Date().getFullYear()} MediShare. All rights reserved.
          </p>
          <p className="text-sm text-white/50">
            Built with ❤️ to save lives
          </p>
        </div>
      </div>
    </footer>
  );
}
