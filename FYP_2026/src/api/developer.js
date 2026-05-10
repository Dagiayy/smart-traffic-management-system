/**
 * api/developer.js  —  Developer Panel endpoints
 */
import apiClient from './client';

export const devApi = {
  // ── AI Sessions ──────────────────────────────────────────────────────
  sessions: (params) => apiClient.get('/dev/ai-sessions/', { params }),
  sessionDetail: (id) => apiClient.get(`/dev/ai-sessions/${id}/`),
  startSession: (data) => apiClient.post('/dev/ai-sessions/', data),
  stopSession: (id) => apiClient.post(`/dev/ai-sessions/${id}/stop/`),
  sessionEpisodes: (id) => apiClient.get(`/dev/ai-sessions/${id}/episodes/`),

  // ── Scenarios ────────────────────────────────────────────────────────
  scenarios: () => apiClient.get('/dev/scenarios/'),
  scenarioReplay: (id) => apiClient.get(`/dev/scenarios/${id}/replay/`),

  // ── Experiments ──────────────────────────────────────────────────────
  experiments: () => apiClient.get('/dev/experiments/'),
  createExperiment: (data) => apiClient.post('/dev/experiments/', data),

  // ── System logs ──────────────────────────────────────────────────────
  systemLogs: (params) => apiClient.get('/dev/system-logs/', { params }),

  // ── Performance comparison ────────────────────────────────────────────
  performanceComparison: () => apiClient.get('/dev/performance-comparison/'),

  // ── Live RL params update ─────────────────────────────────────────────
  updateRLParams: (params) => apiClient.put('/dev/rl-params/', params),
};
