// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { createContext, useState, useCallback } from 'react';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import authApi from '../api/authApi';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const AuthContext = createContext(null);

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const STORAGE_TOKEN_KEY = 'token';
// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const STORAGE_USER_KEY = 'user';

// Role Admin = 1 theo enum UserRole bên Backend (User = 0, Admin = 1)
const ADMIN_ROLE = 1;

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const readStoredUser = () => {
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const raw = localStorage.getItem(STORAGE_USER_KEY);
  // Bao bọc thao tác có thể lỗi để xử lý an toàn.
  try {
    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
    return raw ? JSON.parse(raw) : null;
  } catch {
    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
    return null;
  }
};

// Xuất giá trị có tên để tái sử dụng ở nơi khác.
export const AuthProvider = ({ children }) => {
  // Đọc localStorage ngay khi khởi tạo state -> không cần useEffect/loading riêng
  const [user, setUser] = useState(readStoredUser);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [token, setToken] = useState(() => localStorage.getItem(STORAGE_TOKEN_KEY));

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const persistSession = (newToken, newUser) => {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    localStorage.setItem(STORAGE_TOKEN_KEY, newToken);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    localStorage.setItem(STORAGE_USER_KEY, JSON.stringify(newUser));
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setToken(newToken);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setUser(newUser);
  };

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const clearSession = () => {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    localStorage.removeItem(STORAGE_TOKEN_KEY);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    localStorage.removeItem(STORAGE_USER_KEY);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setToken(null);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setUser(null);
  };

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const login = useCallback(async ({ usernameOrEmail, password }) => {
    // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
    const result = await authApi.login({ usernameOrEmail, password });

    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (!result?.success || !result?.data) {
      // Phát sinh lỗi để thông báo trạng thái bất thường.
      throw new Error(result?.message || 'Đăng nhập thất bại. Vui lòng thử lại!');
    }

    // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
    const { token: newToken, user: newUser } = result.data;

    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (newUser.role !== ADMIN_ROLE) {
      // Phát sinh lỗi để thông báo trạng thái bất thường.
      throw new Error('Tài khoản này không có quyền truy cập trang quản trị!');
    }

    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    persistSession(newToken, newUser);
    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
    return newUser;
  }, []);

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const logout = useCallback(() => {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    clearSession();
  }, []);

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const refreshProfile = useCallback(async () => {
    // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
    const result = await authApi.getMe();
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (result?.success && result?.data) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      localStorage.setItem(STORAGE_USER_KEY, JSON.stringify(result.data));
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setUser(result.data);
      // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
      return result.data;
    }
    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
    return null;
  }, []);

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const value = {
    user,
    token,
    initializing: false,
    isAuthenticated: Boolean(token && user),
    isAdmin: user?.role === ADMIN_ROLE,
    login,
    logout,
    refreshProfile,
  };

  // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default AuthContext;