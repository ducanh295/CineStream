import axiosInstance from './axios';

const aiApi = {
  // POST /api/ai/chat -> { message }
  sendMessage: (message) => axiosInstance.post('/ai/chat', { message }),

  // GET /api/ai/history?limit=30
  getHistory: (limit = 30) => axiosInstance.get('/ai/history', { params: { limit } }),

  // DELETE /api/ai/history
  clearHistory: () => axiosInstance.delete('/ai/history'),
};

export default aiApi;