// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { Navigate, Outlet, useLocation } from 'react-router-dom';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { useAuth } from '../context/useAuth';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const ProtectedRoute = () => {
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const { isAuthenticated, isAdmin, initializing, logout } = useAuth();
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const location = useLocation();

  // Đang đọc localStorage lúc mới load app, tránh nháy màn hình Login rồi lại vào Dashboard
  if (initializing) {
    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#020617] text-slate-400">
        Đang tải...
      </div>
    );
  }

  // Chưa đăng nhập -> đuổi về trang Login
  if (!isAuthenticated) {
    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  // Đã đăng nhập nhưng KHÔNG phải Admin -> hủy phiên và đuổi về Login kèm thông báo
  if (!isAdmin) {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    logout();
    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
    return (
      <Navigate
        to="/login"
        replace
        state={{ error: 'Tài khoản này không có quyền truy cập trang quản trị!' }}
      />
    );
  }

  // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
  return <Outlet />;
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default ProtectedRoute;