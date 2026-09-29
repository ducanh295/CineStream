 
import axiosInstance from './axios';

 
const systemApi = {
  // AI & Chatbot
  getChatLogs: (params) => axiosInstance.get('/ai/chat-logs', { params }),
  updateAiConfig: (data) => axiosInstance.post('/ai/config', data),

  // Upload File (Poster, Trailer, Video)
  uploadFile: (formData) => {
     
    return axiosInstance.post('/storage/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    });
  },

  // Dashboard Statistics
  getDashboardOverview: () => axiosInstance.get('/system/dashboard-overview'),
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default systemApi;