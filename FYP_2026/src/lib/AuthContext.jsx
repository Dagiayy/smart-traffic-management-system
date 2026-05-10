/**
 * lib/AuthContext.jsx
 * Replaces the @base44/sdk AuthContext.
 * Wraps useAuthStore so the rest of the app can keep using useAuth().
 */
import React, { createContext, useContext, useEffect } from 'react';
import { useAuthStore } from '../store/authStore';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const store = useAuthStore();

  // Bootstrap: verify stored token on mount
  useEffect(() => {
    store.bootstrap();
  }, []);

  // Listen for session-expired events fired by the Axios interceptor
  useEffect(() => {
    const handler = () => store.forceLogout();
    window.addEventListener('itms:session_expired', handler);
    return () => window.removeEventListener('itms:session_expired', handler);
  }, [store.forceLogout]);

  const value = {
    user: store.user,
    isAuthenticated: store.isAuthenticated,
    isLoadingAuth: store.isLoading,
    isLoadingPublicSettings: false,
    authError: store.error ? { type: 'auth_required', message: store.error } : null,
    authChecked: !store.isLoading,
    appPublicSettings: null,
    login: store.login,
    logout: store.logout,
    navigateToLogin: () => store.logout(),
    checkUserAuth: store.bootstrap,
    checkAppState: store.bootstrap,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
}
