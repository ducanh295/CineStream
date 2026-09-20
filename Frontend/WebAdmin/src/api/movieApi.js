// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import axiosInstance from './axios';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
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

  // GET /api/movies/featured -> Lấy danh sách phim nổi bật hiển thị trên Banner
  getFeatured: (limit = 5) => axiosInstance.get('/movies/featured', { params: { limit } }),

  // PATCH /api/movies/{id}/toggle-featured -> Bật / Tắt trạng thái phim nổi bật (Admin)
  toggleFeatured: (id) => axiosInstance.patch(`/movies/${id}/toggle-featured`),

  // Quản lý Tập phim (Episodes) & Mùa phim (Seasons)
  getSeasons: (seriesId) => axiosInstance.get(`/series/${seriesId}/seasons`),
  getEpisodes: (seasonId) => axiosInstance.get(`/seasons/${seasonId}/episodes`),
  addEpisode: (data) => axiosInstance.post('/episodes', data),

  // Đề xuất phim
  getRecommendations: () => axiosInstance.get('/movies/recommendations'),
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default movieApi;