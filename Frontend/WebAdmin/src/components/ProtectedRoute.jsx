 
import { Navigate, Outlet, useLocation } from 'react-router-dom';
 
import { useAuth } from '../context/useAuth';

 
const ProtectedRoute = () => {
   
  const { isAuthenticated, isAdmin, initializing, logout } = useAuth();
   
  const location = useLocation();

  // Đang đọc localStorage lúc mới load app, tránh nháy màn hình Login rồi lại vào Dashboard
  if (initializing) {
     
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#020617] text-slate-400">
        Đang tải...
      </div>
    );
  }

  // Chưa đăng nhập -> đuổi về trang Login
  if (!isAuthenticated) {
     
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  // Đã đăng nhập nhưng KHÔNG phải Admin -> hủy phiên và đuổi về Login kèm thông báo
  if (!isAdmin) {
     
    logout();
     
    return (
      <Navigate
        to="/login"
        replace
        state={{ error: 'Tài khoản này không có quyền truy cập trang quản trị!' }}
      />
    );
  }

   
  return <Outlet />;
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default ProtectedRoute;