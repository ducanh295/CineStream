// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import axiosInstance from './axios';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const categoryApi = {
  // GET /api/categories
  getAll: () => axiosInstance.get('/categories'),

  // GET /api/categories/{id}
  getById: (id) => axiosInstance.get(`/categories/${id}`),

  // POST /api/categories -> { name, description }
  create: (data) => axiosInstance.post('/categories', data),

  // PUT /api/categories/{id} -> { name, description }
  update: (id, data) => axiosInstance.put(`/categories/${id}`, data),

  // DELETE /api/categories/{id}
  delete: (id) => axiosInstance.delete(`/categories/${id}`),
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default categoryApi;