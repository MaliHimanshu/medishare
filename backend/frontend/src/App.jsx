// src/App.jsx
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { useAuth } from './context/AuthContext';
import Navbar from './components/layout/Navbar';
import Footer from './components/layout/Footer';
import ProtectedRoute from './components/auth/ProtectedRoute';
import LandingPage    from './pages/LandingPage';
import LoginPage      from './pages/LoginPage';
import RegisterPage   from './pages/RegisterPage';
import DashboardPage  from './pages/DashboardPage';
import Logo from './components/ui/Logo';

// Pages that should NOT show the standard Navbar/Footer
const FULL_SCREEN_ROUTES = ['/login', '/register', '/dashboard'];

// Global loading screen (shown while AuthContext initialises)
function AppLoadingScreen() {
  return (
    <div className="min-h-screen gradient-hero flex flex-col items-center justify-center gap-6">
      <Logo variant="icon" size="xl" className="animate-float" />
      <div className="flex items-center gap-2 text-white/70">
        <svg className="animate-spin h-5 w-5" fill="none" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
        </svg>
        <span className="text-sm font-medium tracking-wide">Loading MediShare...</span>
      </div>
    </div>
  );
}

function AppContent() {
  const { isLoading, isAuthenticated } = useAuth();
  const location = useLocation();

  if (isLoading) return <AppLoadingScreen />;

  const isFullScreen = FULL_SCREEN_ROUTES.some((r) => location.pathname.startsWith(r));

  return (
    <div className="flex flex-col min-h-screen">
      {!isFullScreen && <Navbar />}

      <main className="flex-1">
        <Routes>
          {/* Public */}
          <Route path="/"         element={<LandingPage />} />
          <Route path="/login"    element={isAuthenticated ? <Navigate to="/dashboard" replace /> : <LoginPage />} />
          <Route path="/register" element={isAuthenticated ? <Navigate to="/dashboard" replace /> : <RegisterPage />} />

          {/* Protected */}
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <DashboardPage />
              </ProtectedRoute>
            }
          />

          {/* Catch-all */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>

      {!isFullScreen && <Footer />}
    </div>
  );
}

export default function App() {
  return <AppContent />;
}