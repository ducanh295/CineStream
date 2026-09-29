// Cấu hình lõi, mọi trang trong Web Admin đều dùng chung
import axios from 'axios';

 
const axiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request Interceptor: tự động gắn Bearer Token vào mọi request
axiosInstance.interceptors.request.use(
  (config) => {
     
    const token = localStorage.getItem('token');
     
    if (token) {
       
      config.headers.Authorization = `Bearer ${token}`;
    }
     
    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor: bóc tách data, chuẩn hóa lỗi trả về cho các trang gọi API
axiosInstance.interceptors.response.use(
  // Backend luôn bọc response trong ApiResponse { success, data, message, errors }
  (response) => response.data,
  (error) => {
    // Có phản hồi từ server nhưng là lỗi (400/401/403/404/500...)
    if (error.response) {
       
      const { status, data } = error.response;

      // Phân nhánh xử lý theo giá trị trạng thái hiện tại.
      switch (status) {
        case 401:
           
          console.error('Phiên đăng nhập đã hết hạn hoặc không hợp lệ.');
           
          localStorage.removeItem('token');
           
          localStorage.removeItem('user');
           
          if (window.location.pathname !== '/login') {
             
            window.location.href = '/login';
          }
          // Kết thúc nhánh hoặc vòng lặp đang xử lý.
          break;
        case 403:
           
          console.error('Bạn không có quyền thực hiện hành động này.');
          // Kết thúc nhánh hoặc vòng lặp đang xử lý.
          break;
        case 404:
           
          console.error('Không tìm thấy tài nguyên.');
          // Kết thúc nhánh hoặc vòng lặp đang xử lý.
          break;
        case 500:
           
          console.error('Lỗi máy chủ nội bộ.');
          // Kết thúc nhánh hoặc vòng lặp đang xử lý.
          break;
        default:
           
          console.error('Đã xảy ra lỗi:', status);
      }

      // data thường đã là ApiResponse { success:false, message, errors } -> trả thẳng ra
      // để các trang gọi API chỉ cần đọc err.message
      const normalized =
        data && typeof data === 'object'
          ? data
          : { success: false, message: 'Đã xảy ra lỗi không xác định.' };
       
      return Promise.reject({ ...normalized, status });
    }

    // Gửi request đi nhưng không nhận được phản hồi (backend chưa chạy, sai URL, mất mạng...)
    if (error.request) {
       
      console.error('Không thể kết nối tới máy chủ. Kiểm tra Backend đã chạy chưa (https://localhost:7145).');
       
      return Promise.reject({
        success: false,
        message: 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra Backend đã chạy chưa.',
        status: 0,
      });
    }

    // Lỗi khác (thiết lập request sai...)
    return Promise.reject({ success: false, message: error.message });
  }
);

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default axiosInstance;