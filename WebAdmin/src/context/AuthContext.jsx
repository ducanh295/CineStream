import { createContext, useState, useCallback } from 'react';
import authApi from '../api/authApi';

// eslint-disable-next-line react-refresh/only-export-components
const AuthContext = createContext(null);

const STORAGE_TOKEN_KEY = 'token';
const STORAGE_USER_KEY = 'user';

// Role Admin = 1 theo enum UserRole bên Backend (User = 0, Admin = 1)
const ADMIN_ROLE = 1;

const readStoredUser = () => {
  const raw = localStorage.getItem(STORAGE_USER_KEY);
  try {
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
};

export const AuthProvider = ({ children }) => {
  // Đọc localStorage ngay khi khởi tạo state -> không cần useEffect/loading riêng
  const [user, setUser] = useState(readStoredUser);
  const [token, setToken] = useState(() => localStorage.getItem(STORAGE_TOKEN_KEY));

  const persistSession = (newToken, newUser) => {
    localStorage.setItem(STORAGE_TOKEN_KEY, newToken);
    localStorage.setItem(STORAGE_USER_KEY, JSON.stringify(newUser));
    setToken(newToken);
    setUser(newUser);
  };

  const clearSession = () => {
    localStorage.removeItem(STORAGE_TOKEN_KEY);
    localStorage.removeItem(STORAGE_USER_KEY);
    setToken(null);
    setUser(null);
  };

  const login = useCallback(async ({ usernameOrEmail, password }) => {
    const result = await authApi.login({ usernameOrEmail, password });

    if (!result?.success || !result?.data) {
      throw new Error(result?.message || 'Đăng nhập thất bại. Vui lòng thử lại!');
    }

    const { token: newToken, user: newUser } = result.data;

    if (newUser.role !== ADMIN_ROLE) {
      throw new Error('Tài khoản này không có quyền truy cập trang quản trị!');
    }

    persistSession(newToken, newUser);
    return newUser;
  }, []);

  const logout = useCallback(() => {
    clearSession();
  }, []);

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

export default AuthContext;