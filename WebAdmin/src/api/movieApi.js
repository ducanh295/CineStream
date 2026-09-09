import axiosInstance from './axios';

const movieApi = {
  // Phim lẻ & Series
  getAll: (params) => axiosInstance.get('/movies', { params }),
  getById: (id) => axiosInstance.get(`/movies/${id}`),
  create: (data) => axiosInstance.post('/movies', data),
  update: (id, data) => axiosInstance.put(`/movies/${id}`, data),
  delete: (id) => axiosInstance.delete(`/movies/${id}`),

  // Quản lý Tập phim (Episodes) & Mùa phim (Seasons)
  getSeasons: (seriesId) => axiosInstance.get(`/series/${seriesId}/seasons`),
  getEpisodes: (seasonId) => axiosInstance.get(`/seasons/${seasonId}/episodes`),
  addEpisode: (data) => axiosInstance.post('/episodes', data),

  // Đề xuất phim
  getRecommendations: () => axiosInstance.get('/movies/recommendations'),
};

export default movieApi;