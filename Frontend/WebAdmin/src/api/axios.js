// Cấu hình lõi, mọi trang trong Web Admin đều dùng chung
import axios from 'axios';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const axiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request Interceptor: tự động gắn Bearer Token vào mọi request
axiosInstance.interceptors.request.use(
  (config) => {
    // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
    const token = localStorage.getItem('token');
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (token) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      config.headers.Authorization = `Bearer ${token}`;
    }
    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
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
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const { status, data } = error.response;

      // Phân nhánh xử lý theo giá trị trạng thái hiện tại.
      switch (status) {
        case 401:
          // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
          console.error('Phiên đăng nhập đã hết hạn hoặc không hợp lệ.');
          // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
          localStorage.removeItem('token');
          // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
          localStorage.removeItem('user');
          // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
          if (window.location.pathname !== '/login') {
            // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
            window.location.href = '/login';
          }
          // Kết thúc nhánh hoặc vòng lặp đang xử lý.
          break;
        case 403:
          // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
          console.error('Bạn không có quyền thực hiện hành động này.');
          // Kết thúc nhánh hoặc vòng lặp đang xử lý.
          break;
        case 404:
          // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
          console.error('Không tìm thấy tài nguyên.');
          // Kết thúc nhánh hoặc vòng lặp đang xử lý.
          break;
        case 500:
          // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
          console.error('Lỗi máy chủ nội bộ.');
          // Kết thúc nhánh hoặc vòng lặp đang xử lý.
          break;
        default:
          // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
          console.error('Đã xảy ra lỗi:', status);
      }

      // data thường đã là ApiResponse { success:false, message, errors } -> trả thẳng ra
      // để các trang gọi API chỉ cần đọc err.message
      const normalized =
        data && typeof data === 'object'
          ? data
          : { success: false, message: 'Đã xảy ra lỗi không xác định.' };
      // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
      return Promise.reject({ ...normalized, status });
    }

    // Gửi request đi nhưng không nhận được phản hồi (backend chưa chạy, sai URL, mất mạng...)
    if (error.request) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      console.error('Không thể kết nối tới máy chủ. Kiểm tra Backend đã chạy chưa (https://localhost:7145).');
      // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
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