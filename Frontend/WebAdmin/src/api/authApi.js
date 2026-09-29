 
import axiosInstance from './axios';

 
const authApi = {
  // POST /api/auth/login -> { usernameOrEmail, password }
  login: (credentials) => axiosInstance.post('/auth/login', credentials),

  // POST /api/auth/register -> { username, email, password }
  register: (payload) => axiosInstance.post('/auth/register', payload),

  // GET /api/auth/me (cần Bearer token)
  getMe: () => axiosInstance.get('/auth/me'),

  // GET /api/auth/admin-check (cần Bearer token + role Admin)
  checkAdmin: () => axiosInstance.get('/auth/admin-check'),
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default authApi;