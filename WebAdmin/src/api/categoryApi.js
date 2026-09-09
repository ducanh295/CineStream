import axiosInstance from './axios';

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

export default categoryApi;