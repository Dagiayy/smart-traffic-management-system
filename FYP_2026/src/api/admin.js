/**
 * api/admin.js  —  Admin Panel endpoints
 */
import apiClient from './client';

// ── Dashboard & Analytics ─────────────────────────────────────────────────
export const dashboardApi = {
  summary: () => apiClient.get('/admin/dashboard/summary/'),
  violationAnalytics: (params) => apiClient.get('/admin/analytics/violations/', { params }),
  fineAnalytics: (params) => apiClient.get('/admin/analytics/fines/', { params }),
  complianceAnalytics: () => apiClient.get('/admin/analytics/compliance/'),
  officerPerformance: () => apiClient.get('/admin/analytics/officer-performance/'),
};

// ── Violations ────────────────────────────────────────────────────────────
export const violationsApi = {
  list: (params) => apiClient.get('/admin/violations/', { params }),
  detail: (id) => apiClient.get(`/admin/violations/${id}/`),
  update: (id, data) => apiClient.patch(`/admin/violations/${id}/`, data),
  confirm: (id, notes = '') =>
    apiClient.patch(`/admin/violations/${id}/`, { status: 'CONFIRMED', admin_notes: notes }),
  dismiss: (id, notes = '') =>
    apiClient.patch(`/admin/violations/${id}/`, { status: 'DISMISSED', admin_notes: notes }),
  underReview: (id, notes = '') =>
    apiClient.patch(`/admin/violations/${id}/`, { status: 'UNDER_REVIEW', admin_notes: notes }),
  evidence: (params) => apiClient.get('/admin/evidence/', { params }),
  hotspotMap: (params) => apiClient.get('/admin/hotspot-map/', { params }),
};

// ── Fines ─────────────────────────────────────────────────────────────────
export const finesApi = {
  list: (params) => apiClient.get('/admin/fines/', { params }),
  detail: (id) => apiClient.get(`/admin/fines/${id}/`),
  update: (id, data) => apiClient.patch(`/admin/fines/${id}/`, data),
  rules: () => apiClient.get('/admin/fine-rules/'),
  createRule: (data) => apiClient.post('/admin/fine-rules/', data),
  updateRule: (id, data) => apiClient.put(`/admin/fine-rules/${id}/`, data),
  deleteRule: (id) => apiClient.delete(`/admin/fine-rules/${id}/`),
};

// ── Disputes ──────────────────────────────────────────────────────────────
export const disputesApi = {
  list: (params) => apiClient.get('/admin/disputes/', { params }),
  detail: (id) => apiClient.get(`/admin/disputes/${id}/`),
  decide: (id, decision, reason) =>
    apiClient.post(`/admin/disputes/${id}/decide/`, { decision, reason }),
};

// ── Traffic Control (intersections + signal override) ────────────────────
export const trafficApi = {
  intersections: () => apiClient.get('/admin/intersections/'),
  intersectionDetail: (id) => apiClient.get(`/admin/intersections/${id}/`),
  manualOverride: (id, data) =>
    apiClient.post(`/admin/intersections/${id}/manual-override/`, data),
  releaseOverride: (id) =>
    apiClient.delete(`/admin/intersections/${id}/manual-override/`),
};

// ── Users ─────────────────────────────────────────────────────────────────
export const usersApi = {
  list: (params) => apiClient.get('/admin/users/', { params }),
  create: (data) => apiClient.post('/admin/users/', data),
  update: (id, data) => apiClient.patch(`/admin/users/${id}/`, data),
  detail: (id) => apiClient.get(`/admin/users/${id}/`),
};

// ── System settings ───────────────────────────────────────────────────────
export const settingsApi = {
  get: () => apiClient.get('/admin/settings/'),
  update: (data) => apiClient.put('/admin/settings/', data),
};
