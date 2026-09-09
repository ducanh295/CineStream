import axiosInstance from './axios';

const userApi = {
  getAllUsers: (params) => axiosInstance.get('/users', { params }),
  getUserById: (id) => axiosInstance.get(`/users/${id}`),
  updateUserStatus: (id, status) => axiosInstance.patch(`/users/${id}/status`, { status }),
  getAdminStats: () => axiosInstance.get('/users/stats'),
};

export default userApi;