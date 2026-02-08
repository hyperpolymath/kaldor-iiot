// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Axios client with interceptors.
// Interceptors use mutable config patterns best expressed in JS.

import axios from 'axios'

const api = axios.create({
  baseURL: '/api/v1',
  timeout: 10000,
})

// Add auth token to all requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export const authAPI = {
  login: (username, password) =>
    api.post('/auth/login', { username, password }),
  register: (username, email, password) =>
    api.post('/auth/register', { username, email, password }),
}

export const loomsAPI = {
  getAll: () => api.get('/looms'),
  getById: (id) => api.get(`/looms/${id}`),
  updateConfig: (id, config) => api.post(`/looms/${id}/config`, config),
}

export const measurementsAPI = {
  get: (loomId, params) => api.get('/measurements', { params: { loom_id: loomId, ...params } }),
}

export const alertsAPI = {
  getAll: (params) => api.get('/alerts', { params }),
  acknowledge: (id) => api.post(`/alerts/${id}/acknowledge`),
}

export const analyticsAPI = {
  getSummary: (loomId) => api.get('/analytics/summary', { params: { loom_id: loomId } }),
}

export default api
