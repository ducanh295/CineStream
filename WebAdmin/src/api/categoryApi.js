import axiosInstance from './axios';

const categoryApi = {
  // Thể loại
  getCategories: () => axiosInstance.get('/categories'),
  createCategory: (data) => axiosInstance.post('/categories', data),
  updateCategory: (id, data) => axiosInstance.put(`/categories/${id}`, data),
  deleteCategory: (id) => axiosInstance.delete(`/categories/${id}`),

  // Diễn viên (Actors)
  getActors: (params) => axiosInstance.get('/actors', { params }),
  addActor: (data) => axiosInstance.post('/actors', data),
  updateActor: (id, data) => axiosInstance.put(`/actors/${id}`, data),
};

export default categoryApi;