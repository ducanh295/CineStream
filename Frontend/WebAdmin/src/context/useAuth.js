 
import { useContext } from 'react';
 
import AuthContext from './AuthContext';

// Xuất giá trị có tên để tái sử dụng ở nơi khác.
export const useAuth = () => {
   
  const ctx = useContext(AuthContext);
   
  if (!ctx) {
    // Phát sinh lỗi để thông báo trạng thái bất thường.
    throw new Error('useAuth phải được sử dụng bên trong AuthProvider');
  }
   
  return ctx;
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default useAuth;