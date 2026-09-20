// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import axiosInstance from './axios';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const userApi = {
  getAllUsers: (params) => axiosInstance.get('/admin/users', { params }),
  getUserById: (id) => axiosInstance.get(`/admin/users/${id}`),
  lockUser: (id, reason) => axiosInstance.post(`/admin/users/${id}/lock`, { reason }),
  unlockUser: (id) => axiosInstance.post(`/admin/users/${id}/unlock`),
  deleteUser: (id) => axiosInstance.delete(`/admin/users/${id}`),
  setPremium: (id, data) => axiosInstance.put(`/admin/users/${id}/premium`, data),
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default userApi;