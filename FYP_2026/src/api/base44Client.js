/**
 * base44Client.js — REPLACED
 * This project now uses a Django DRF backend.
 * Authentication is handled by src/lib/AuthContext.jsx + src/store/authStore.js
 * API calls use src/api/client.js (Axios)
 */
export const base44 = {
  auth: {
    me: () => Promise.reject(new Error('base44 is removed — use Django API')),
    logout: () => {},
    redirectToLogin: () => window.location.replace('/login'),
  },
};
