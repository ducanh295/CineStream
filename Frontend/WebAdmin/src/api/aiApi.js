// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import axiosInstance from './axios';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const aiApi = {
  // POST /api/ai/chat -> { message }
  sendMessage: (message) => axiosInstance.post('/ai/chat', { message }),

  // GET /api/ai/history?limit=30
  getHistory: (limit = 30) => axiosInstance.get('/ai/history', { params: { limit } }),

  // DELETE /api/ai/history
  clearHistory: () => axiosInstance.delete('/ai/history'),

  // GET /api/ai/config - Quan tri vien lay cau hinh API Key
  getConfig: () => axiosInstance.get('/ai/config'),

  // POST /api/ai/config - Quan tri vien luu/cap nhat API Key
  updateConfig: (data) => axiosInstance.post('/ai/config', data),

  // DELETE /api/ai/config - Quan tri vien xoa/khoi phuc API Key mac dinh
  deleteConfig: () => axiosInstance.delete('/ai/config'),
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default aiApi;