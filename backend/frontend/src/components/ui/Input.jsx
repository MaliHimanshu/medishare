// src/components/ui/Input.jsx
import { forwardRef, useState } from 'react';
import { FiEye, FiEyeOff } from 'react-icons/fi';

const Input = forwardRef(function Input(
  {
    label,
    error,
    hint,
    type = 'text',
    leftIcon,
    rightIcon,
    className = '',
    inputClassName = '',
    required = false,
    ...props
  },
  ref
) {
  const [showPassword, setShowPassword] = useState(false);
  const isPassword = type === 'password';
  const inputType = isPassword ? (showPassword ? 'text' : 'password') : type;

  return (
    <div className={`flex flex-col gap-1.5 ${className}`}>
      {label && (
        <label className="text-sm font-semibold text-[var(--color-text)]">
          {label}
          {required && <span className="text-[var(--color-error)] ml-1">*</span>}
        </label>
      )}

      <div className="relative flex items-center">
        {/* Left Icon */}
        {leftIcon && (
          <span className="absolute left-3.5 text-[var(--color-text-muted)] pointer-events-none z-10">
            {leftIcon}
          </span>
        )}

        {/* Input Field */}
        <input
          ref={ref}
          type={inputType}
          className={`
            w-full h-12
            ${leftIcon ? 'pl-10' : 'pl-4'}
            ${isPassword || rightIcon ? 'pr-12' : 'pr-4'}
            bg-[var(--color-surface)] border rounded-[var(--radius-md)]
            text-[var(--color-text)] placeholder:text-[var(--color-text-muted)]
            text-sm font-medium
            transition-all duration-200
            ${error
              ? 'border-[var(--color-error)] focus:border-[var(--color-error)] focus:ring-2 focus:ring-red-200'
              : 'border-[var(--color-border)] focus:border-[var(--color-primary)] focus:ring-2 focus:ring-blue-100'
            }
            ${inputClassName}
          `}
          {...props}
        />

        {/* Right Icon or Password Toggle */}
        {isPassword ? (
          <button
            type="button"
            onClick={() => setShowPassword((v) => !v)}
            className="absolute right-3.5 text-[var(--color-text-muted)] hover:text-[var(--color-primary)] transition-colors"
            tabIndex={-1}
          >
            {showPassword ? <FiEyeOff size={18} /> : <FiEye size={18} />}
          </button>
        ) : rightIcon ? (
          <span className="absolute right-3.5 text-[var(--color-text-muted)]">
            {rightIcon}
          </span>
        ) : null}
      </div>

      {/* Error or Hint */}
      {error && (
        <p className="text-xs text-[var(--color-error)] font-medium flex items-center gap-1">
          <svg className="w-3.5 h-3.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
          </svg>
          {error}
        </p>
      )}
      {hint && !error && (
        <p className="text-xs text-[var(--color-text-muted)]">{hint}</p>
      )}
    </div>
  );
});

export default Input;
