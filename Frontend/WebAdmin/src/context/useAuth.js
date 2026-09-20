// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { useContext } from 'react';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import AuthContext from './AuthContext';

// Xuất giá trị có tên để tái sử dụng ở nơi khác.
export const useAuth = () => {
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const ctx = useContext(AuthContext);
  // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
  if (!ctx) {
    // Phát sinh lỗi để thông báo trạng thái bất thường.
    throw new Error('useAuth phải được sử dụng bên trong AuthProvider');
  }
  // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
  return ctx;
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default useAuth;