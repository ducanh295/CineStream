import { useContext } from 'react';
import AuthContext from './AuthContext';

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth phải được sử dụng bên trong AuthProvider');
  }
  return ctx;
};

export default useAuth;