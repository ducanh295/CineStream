 
import { createContext, useState, useCallback } from 'react';
 
import authApi from '../api/authApi';

 
const AuthContext = createContext(null);

 
const STORAGE_TOKEN_KEY = 'token';
 
const STORAGE_USER_KEY = 'user';

// Role Admin = 1 theo enum UserRole bên Backend (User = 0, Admin = 1)
const ADMIN_ROLE = 1;

// Hàm đọc thông tin người dùng từ localStorage, nếu có lỗi khi phân tích JSON, trả về null. 
const readStoredUser = () => {
   
  const raw = localStorage.getItem(STORAGE_USER_KEY);
  // Bao bọc thao tác có thể lỗi để xử lý an toàn.
  try {
     
    return raw ? JSON.parse(raw) : null;
  } catch {
     
    return null;
  }
};

// Xuất giá trị có tên để tái sử dụng ở nơi khác.
export const AuthProvider = ({ children }) => {
  // Đọc localStorage ngay khi khởi tạo state -> không cần useEffect/loading riêng
  const [user, setUser] = useState(readStoredUser);
   
  const [token, setToken] = useState(() => localStorage.getItem(STORAGE_TOKEN_KEY));

  // hàm lưu trữ thông tin phiên đăng nhập vào localStorage và cập nhật state. 
  const persistSession = (newToken, newUser) => {
     
    localStorage.setItem(STORAGE_TOKEN_KEY, newToken);
     
    localStorage.setItem(STORAGE_USER_KEY, JSON.stringify(newUser));
     
    setToken(newToken);
     
    setUser(newUser);
  };

  // hàm xóa thông tin phiên đăng nhập khỏi localStorage và cập nhật state. 
  const clearSession = () => {
     
    localStorage.removeItem(STORAGE_TOKEN_KEY);
     
    localStorage.removeItem(STORAGE_USER_KEY);
     
    setToken(null);
     
    setUser(null);
  };

  //hàm đăng nhập, nhận thông tin người dùng và token từ API, kiểm tra quyền truy cập, lưu trữ thông tin phiên đăng nhập hoặc ném lỗi nếu không thành công. 
  const login = useCallback(async ({ usernameOrEmail, password }) => {
     
    const result = await authApi.login({ usernameOrEmail, password });

     
    if (!result?.success || !result?.data) {
      // Phát sinh lỗi để thông báo trạng thái bất thường.
      throw new Error(result?.message || 'Đăng nhập thất bại. Vui lòng thử lại!');
    }

    // token và user được trả về từ API sau khi đăng nhập thành công.  
    const { token: newToken, user: newUser } = result.data;

     
    if (newUser.role !== ADMIN_ROLE) {
      // Phát sinh lỗi để thông báo trạng thái bất thường.
      throw new Error('Tài khoản này không có quyền truy cập trang quản trị!');
    }

     
    persistSession(newToken, newUser);
     
    return newUser;
  }, []);

  //hàm đăng xuất, xóa thông tin phiên đăng nhập khỏi localStorage và cập nhật state. 
  const logout = useCallback(() => {
     
    clearSession();
  }, []);

  //hàm làm mới thông tin hồ sơ người dùng bằng cách gọi API, cập nhật localStorage và state nếu thành công, hoặc trả về null nếu không thành công. 
  const refreshProfile = useCallback(async () => {
     
    const result = await authApi.getMe();
     
    if (result?.success && result?.data) {
       
      localStorage.setItem(STORAGE_USER_KEY, JSON.stringify(result.data));
       
      setUser(result.data);
       
      return result.data;
    }
     
    return null;
  }, []);

   
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

   
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default AuthContext;