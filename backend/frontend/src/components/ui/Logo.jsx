// src/components/ui/Logo.jsx
// Renders MediShare logo in horizontal or icon-only variant

export default function Logo({ variant = 'full', size = 'md', className = '' }) {
  const sizes = {
    sm:   { full: 'h-7',  icon: 'h-7 w-7' },
    md:   { full: 'h-9',  icon: 'h-9 w-9' },
    lg:   { full: 'h-12', icon: 'h-12 w-12' },
    xl:   { full: 'h-16', icon: 'h-16 w-16' },
  };

  const sizeClass = sizes[size]?.[variant === 'full' ? 'full' : 'icon'] || sizes.md.full;

  if (variant === 'icon') {
    return (
      <img
        src="/logo_icon.png"
        alt="MediShare"
        className={`${sizeClass} object-contain ${className}`}
      />
    );
  }

  return (
    <img
      src="/logo.png"
      alt="MediShare"
      className={`${sizeClass} object-contain ${className}`}
    />
  );
}
