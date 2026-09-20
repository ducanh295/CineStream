// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import axiosInstance from './axios';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const systemApi = {
  // AI & Chatbot
  getChatLogs: (params) => axiosInstance.get('/ai/chat-logs', { params }),
  updateAiConfig: (data) => axiosInstance.post('/ai/config', data),

  // Upload File (Poster, Trailer, Video)
  uploadFile: (formData) => {
    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
    return axiosInstance.post('/storage/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    });
  },

  // Dashboard Statistics
  getDashboardOverview: () => axiosInstance.get('/system/dashboard-overview'),
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default systemApi;