import axiosInstance from './axios';

const movieApi = {
   // GET /api/movies?categoryId=&search=
  getAll: (params) => axiosInstance.get('/movies', { params }),

  // GET /api/movies/{id}
  getById: (id) => axiosInstance.get(`/movies/${id}`),

  // GET /api/movies/{id}/playback
  getPlayback: (id) => axiosInstance.get(`/movies/${id}/playback`),

  // POST /api/movies -> CreateMovieDto
  create: (data) => axiosInstance.post('/movies', data),

  // PUT /api/movies/{id} -> UpdateMovieDto
  update: (id, data) => axiosInstance.put(`/movies/${id}`, data),

  // DELETE /api/movies/{id}
  delete: (id) => axiosInstance.delete(`/movies/${id}`),

  // GET /api/movies/available-streams -> Quét kho luồng phát HLS và video mẫu CDN
  getAvailableStreams: () => axiosInstance.get('/movies/available-streams'),

  // Quản lý Tập phim (Episodes) & Mùa phim (Seasons)
  getSeasons: (seriesId) => axiosInstance.get(`/series/${seriesId}/seasons`),
  getEpisodes: (seasonId) => axiosInstance.get(`/seasons/${seasonId}/episodes`),
  addEpisode: (data) => axiosInstance.post('/episodes', data),

  // Đề xuất phim
  getRecommendations: () => axiosInstance.get('/movies/recommendations'),
};

export default movieApi;