// src/components/auth/ProtectedRoute.jsx
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import Logo from '../ui/Logo';

export default function ProtectedRoute({ children }) {
  const { isAuthenticated, isLoading } = useAuth();
  const location = useLocation();

  // Show branded loading screen while checking auth
  if (isLoading) {
    return (
      <div className="min-h-screen gradient-hero flex flex-col items-center justify-center gap-6">
        <Logo variant="icon" size="lg" />
        <div className="flex items-center gap-2 text-white/70">
          <svg className="animate-spin h-5 w-5" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
          </svg>
          <span className="text-sm font-medium">Verifying session...</span>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    // Preserve intended destination for redirect after login
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return children;
}
