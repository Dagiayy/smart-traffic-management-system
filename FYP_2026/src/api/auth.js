/**
 * api/auth.js  —  Django auth endpoints
 */
import apiClient from './client';

export const authApi = {
  /** Login with phone/email + password. Returns { access, refresh, user } */
  login: (phoneOrEmail, password) =>
    apiClient.post('/auth/login/', { phone_or_email: phoneOrEmail, password }),

  /** Get current authenticated user */
  me: () => apiClient.get('/auth/me/'),

  /** Update own profile */
  updateMe: (data) => apiClient.put('/auth/me/', data),

  /** Logout — blacklists refresh token */
  logout: (refresh) => apiClient.post('/auth/logout/', { refresh }),

  /** Send OTP for password reset */
  sendOtp: (phoneOrEmail, purpose = 'reset') =>
    apiClient.post('/auth/otp/send/', { phone_or_email: phoneOrEmail, purpose }),

  /** Verify OTP — returns { otp_token } */
  verifyOtp: (phoneOrEmail, code) =>
    apiClient.post('/auth/otp/verify/', { phone_or_email: phoneOrEmail, code }),

  /** Reset password using the one-time token from OTP verification */
  resetPassword: (phoneOrEmail, newPassword, otpToken) =>
    apiClient.post('/auth/password/reset/', {
      phone_or_email: phoneOrEmail,
      new_password: newPassword,
      otp_token: otpToken,
    }),

  /** Refresh access token */
  refreshToken: (refresh) =>
    apiClient.post('/auth/token/refresh/', { refresh }),
};
