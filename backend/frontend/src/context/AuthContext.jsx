// src/context/AuthContext.jsx
import { createContext, useContext, useEffect, useReducer, useCallback } from 'react';
import { loginUser, registerUser, getMe } from '../api/authApi';

// ── Constants ───────────────────────────────────────────────
const TOKEN_KEY = 'medishare_token';
const USER_KEY  = 'medishare_user';

// ── Initial State ───────────────────────────────────────────
const initialState = {
  user: null,
  token: localStorage.getItem(TOKEN_KEY) || null,
  isAuthenticated: false,
  isLoading: true,
  error: null,
};

// ── Reducer ─────────────────────────────────────────────────
function authReducer(state, action) {
  switch (action.type) {
    case 'AUTH_SUCCESS':
      return {
        ...state,
        user: action.payload.user,
        token: action.payload.token,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      };
    case 'AUTH_LOADING':
      return { ...state, isLoading: true, error: null };
    case 'AUTH_ERROR':
      return { ...state, isLoading: false, error: action.payload };
    case 'AUTH_READY':
      return { ...state, isLoading: false };
    case 'LOGOUT':
      return {
        ...initialState,
        token: null,
        isLoading: false,
      };
    default:
      return state;
  }
}

// ── Context ─────────────────────────────────────────────────
export const AuthContext = createContext(null);

// ── Provider ─────────────────────────────────────────────────
export function AuthProvider({ children }) {
  const [state, dispatch] = useReducer(authReducer, initialState);

  // Persist helpers
  const persistAuth = (token, user) => {
    localStorage.setItem(TOKEN_KEY, token);
    localStorage.setItem(USER_KEY, JSON.stringify(user));
  };

  const clearAuth = () => {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
  };

  // ── Check stored token on mount ──────────────────────────
  useEffect(() => {
    const storedToken = localStorage.getItem(TOKEN_KEY);
    if (!storedToken) {
      dispatch({ type: 'AUTH_READY' });
      return;
    }
    // Validate token by fetching current user
    getMe()
      .then((res) => {
        dispatch({
          type: 'AUTH_SUCCESS',
          payload: { user: res.data, token: storedToken },
        });
      })
      .catch(() => {
        clearAuth();
        dispatch({ type: 'AUTH_READY' });
      });
  }, []);

  // ── Login ─────────────────────────────────────────────────
  const login = useCallback(async (email, password) => {
    dispatch({ type: 'AUTH_LOADING' });
    try {
      const res = await loginUser(email, password);
      persistAuth(res.token, res.data);
      dispatch({
        type: 'AUTH_SUCCESS',
        payload: { user: res.data, token: res.token },
      });
      return { success: true };
    } catch (err) {
      const message = err.response?.data?.message || 'Login failed. Please try again.';
      dispatch({ type: 'AUTH_ERROR', payload: message });
      return { success: false, message };
    }
  }, []);

  // ── Register ──────────────────────────────────────────────
  const register = useCallback(async (data) => {
    dispatch({ type: 'AUTH_LOADING' });
    try {
      const res = await registerUser(data);
      persistAuth(res.token, res.data);
      dispatch({
        type: 'AUTH_SUCCESS',
        payload: { user: res.data, token: res.token },
      });
      return { success: true };
    } catch (err) {
      const message = err.response?.data?.message || 'Registration failed. Please try again.';
      dispatch({ type: 'AUTH_ERROR', payload: message });
      return { success: false, message };
    }
  }, []);

  // ── Logout ────────────────────────────────────────────────
  const logout = useCallback(() => {
    clearAuth();
    dispatch({ type: 'LOGOUT' });
  }, []);

  return (
    <AuthContext.Provider
      value={{
        ...state,
        login,
        register,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

// ── Hook ─────────────────────────────────────────────────────
export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>');
  return ctx;
}
