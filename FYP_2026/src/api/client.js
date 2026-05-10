/**
 * api/client.js
 * Axios instance wired to our Django backend.
 * - Attaches Bearer token from localStorage on every request
 * - Auto-refreshes expired access tokens using /auth/token/refresh/
 * - Clears session and redirects to /login on permanent 401
 */
import axios from 'axios';

const BASE_URL = '/api/v1';

export const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
  timeout: 20000,
});

// ── Request: attach access token ──────────────────────────────────────────
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('itms_access_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// ── Response: silent token refresh on 401 ────────────────────────────────
let _isRefreshing = false;
let _queue = [];

const processQueue = (error, token = null) => {
  _queue.forEach((p) => (error ? p.reject(error) : p.resolve(token)));
  _queue = [];
};

apiClient.interceptors.response.use(
  (res) => res,
  async (err) => {
    const originalRequest = err.config;

    if (
      err.response?.status === 401 &&
      !originalRequest._retry &&
      !originalRequest.url?.includes('/auth/token/refresh/') &&
      !originalRequest.url?.includes('/auth/login/')
    ) {
      if (_isRefreshing) {
        return new Promise((resolve, reject) => {
          _queue.push({ resolve, reject });
        })
          .then((token) => {
            originalRequest.headers.Authorization = `Bearer ${token}`;
            return apiClient(originalRequest);
          })
          .catch((e) => Promise.reject(e));
      }

      originalRequest._retry = true;
      _isRefreshing = true;

      const refresh = localStorage.getItem('itms_refresh_token');
      if (!refresh) {
        _isRefreshing = false;
        _clearSession();
        return Promise.reject(err);
      }

      try {
        const { data } = await axios.post(`${BASE_URL}/auth/token/refresh/`, {
          refresh,
        });
        localStorage.setItem('itms_access_token', data.access);
        if (data.refresh) localStorage.setItem('itms_refresh_token', data.refresh);
        apiClient.defaults.headers.common.Authorization = `Bearer ${data.access}`;
        processQueue(null, data.access);
        originalRequest.headers.Authorization = `Bearer ${data.access}`;
        return apiClient(originalRequest);
      } catch (refreshErr) {
        processQueue(refreshErr, null);
        _clearSession();
        return Promise.reject(refreshErr);
      } finally {
        _isRefreshing = false;
      }
    }

    return Promise.reject(err);
  },
);

function _clearSession() {
  localStorage.removeItem('itms_access_token');
  localStorage.removeItem('itms_refresh_token');
  localStorage.removeItem('itms_user');
  // Trigger a redirect – handled by AuthContext listener
  window.dispatchEvent(new Event('itms:session_expired'));
}

export default apiClient;
