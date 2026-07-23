// src/components/ui/Button.jsx
import { forwardRef } from 'react';

const variants = {
  primary: `
    bg-[var(--color-primary)] hover:bg-[var(--color-primary-dark)]
    text-white shadow-md hover:shadow-lg
    hover:shadow-[0_4px_20px_rgba(59,108,248,0.4)]
  `,
  accent: `
    bg-[var(--color-accent)] hover:bg-[var(--color-accent-dark)]
    text-white shadow-md hover:shadow-lg
    hover:shadow-[0_4px_20px_rgba(46,207,179,0.4)]
  `,
  secondary: `
    bg-[var(--color-surface-2)] hover:bg-[var(--color-border)]
    text-[var(--color-primary)] border border-[var(--color-border)]
  `,
  outline: `
    border-2 border-[var(--color-primary)] text-[var(--color-primary)]
    hover:bg-[var(--color-primary)] hover:text-white bg-transparent
  `,
  'outline-white': `
    border-2 border-white text-white
    hover:bg-white hover:text-[var(--color-primary)] bg-transparent
  `,
  ghost: `
    text-[var(--color-primary)] hover:bg-[var(--color-surface-2)] bg-transparent
  `,
  danger: `
    bg-[var(--color-error)] hover:bg-red-700
    text-white shadow-md
  `,
};

const sizes = {
  sm:  'px-4 py-2 text-sm rounded-[10px]',
  md:  'px-6 py-3 text-base rounded-[12px]',
  lg:  'px-8 py-4 text-lg rounded-[14px]',
  xl:  'px-10 py-5 text-xl rounded-[16px]',
};

const Button = forwardRef(function Button(
  {
    children,
    variant = 'primary',
    size = 'md',
    loading = false,
    disabled = false,
    fullWidth = false,
    className = '',
    leftIcon,
    rightIcon,
    ...props
  },
  ref
) {
  const isDisabled = disabled || loading;

  return (
    <button
      ref={ref}
      disabled={isDisabled}
      className={`
        inline-flex items-center justify-center gap-2
        font-semibold transition-all duration-200
        cursor-pointer select-none
        ${variants[variant] || variants.primary}
        ${sizes[size] || sizes.md}
        ${fullWidth ? 'w-full' : ''}
        ${isDisabled ? 'opacity-60 cursor-not-allowed' : 'active:scale-[0.97]'}
        ${className}
      `}
      {...props}
    >
      {loading ? (
        <>
          <svg
            className="animate-spin h-4 w-4"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
          </svg>
          <span>Loading...</span>
        </>
      ) : (
        <>
          {leftIcon && <span className="flex-shrink-0">{leftIcon}</span>}
          {children}
          {rightIcon && <span className="flex-shrink-0">{rightIcon}</span>}
        </>
      )}
    </button>
  );
});

export default Button;
