/**
 * store/authStore.js
 * Zustand-based auth store replacing @base44/sdk authentication.
 * Persists tokens in localStorage so sessions survive page refresh.
 */
import { create } from 'zustand';
import { authApi } from '../api/auth';

const KEYS = {
  access: 'itms_access_token',
  refresh: 'itms_refresh_token',
  user: 'itms_user',
};

export const useAuthStore = create((set, get) => ({
  user: (() => {
    try { return JSON.parse(localStorage.getItem(KEYS.user) || 'null'); } catch { return null; }
  })(),
  accessToken: localStorage.getItem(KEYS.access),
  isAuthenticated: !!localStorage.getItem(KEYS.access),
  isLoading: false,
  error: null,

  // ── Login ───────────────────────────────────────────────────────────────
  login: async (phoneOrEmail, password) => {
    set({ isLoading: true, error: null });
    try {
      const { data } = await authApi.login(phoneOrEmail, password);
      localStorage.setItem(KEYS.access, data.access);
      localStorage.setItem(KEYS.refresh, data.refresh);
      localStorage.setItem(KEYS.user, JSON.stringify(data.user));
      set({
        user: data.user,
        accessToken: data.access,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      });
      return data.user;
    } catch (err) {
      const msg =
        err.response?.data?.error ||
        err.response?.data?.detail ||
        'Login failed. Please check your credentials.';
      set({ isLoading: false, error: msg, isAuthenticated: false });
      throw new Error(msg);
    }
  },

  // ── Bootstrap (on page load) ────────────────────────────────────────────
  bootstrap: async () => {
    const token = localStorage.getItem(KEYS.access);
    if (!token) {
      set({ isLoading: false, isAuthenticated: false });
      return;
    }
    set({ isLoading: true });
    try {
      const { data: user } = await authApi.me();
      localStorage.setItem(KEYS.user, JSON.stringify(user));
      set({ user, isAuthenticated: true, isLoading: false });
    } catch {
      // Token invalid / expired — clear everything
      Object.values(KEYS).forEach((k) => localStorage.removeItem(k));
      set({ user: null, accessToken: null, isAuthenticated: false, isLoading: false });
    }
  },

  // ── Logout ──────────────────────────────────────────────────────────────
  logout: async () => {
    const refresh = localStorage.getItem(KEYS.refresh);
    try { if (refresh) await authApi.logout(refresh); } catch { /* ignore */ }
    Object.values(KEYS).forEach((k) => localStorage.removeItem(k));
    set({ user: null, accessToken: null, isAuthenticated: false, error: null });
  },

  // ── Force-clear (session expired event) ────────────────────────────────
  forceLogout: () => {
    Object.values(KEYS).forEach((k) => localStorage.removeItem(k));
    set({ user: null, accessToken: null, isAuthenticated: false });
  },

  clearError: () => set({ error: null }),
}));
