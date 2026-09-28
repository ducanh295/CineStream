// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { useState } from 'react';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { motion } from 'framer-motion';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { Lock, User, ArrowRight, Loader2 } from 'lucide-react';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { useNavigate, useLocation } from 'react-router-dom';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { useAuth } from '../context/useAuth';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const Login = () => {
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const navigate = useNavigate();
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const location = useLocation();
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const { login } = useAuth();

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [usernameOrEmail, setUsernameOrEmail] = useState('');
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [password, setPassword] = useState('');
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [loading, setLoading] = useState(false);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [error, setError] = useState(location.state?.error || '');

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const handleLogin = async (e) => {
     
    e.preventDefault();
     
    setLoading(true);
     
    setError('');

    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
       
      await login({ usernameOrEmail, password });
       
      navigate('/', { replace: true });
    } catch (err) {
       
      setError(err.message || 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin!');
    } finally {
       
      setLoading(false);
    }
  };

  // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
  return (
    <div className="min-h-screen bg-[#020617] flex items-center justify-center p-6 relative overflow-hidden">
      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
      <div className="absolute top-0 left-0 w-full h-full opacity-10 bg-radial-[circle_at_center] from-blue-500 via-transparent to-transparent blur-3xl"></div>

      {/* Hiển thị phần tử giao diện giao diện và nội dung con của nó. */}
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }}
        className="w-full max-w-md bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-3xl p-10 shadow-2xl relative z-10"
      >
        {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
        <div className="text-center mb-10">
          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="w-16 h-16 bg-blue-600 rounded-2xl mx-auto flex items-center justify-center font-bold text-3xl shadow-lg shadow-blue-500/50 mb-6 text-white">C</div>
          {/* Hiển thị phần tử giao diện h2 và nội dung con của nó. */}
          <h2 className="text-4xl font-extrabold text-white tracking-tight">CineStream Admin</h2>
          {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
          <p className="text-slate-500 mt-2 text-sm uppercase tracking-[0.2em]">Hệ thống quản trị nội dung</p>
        </div>

        {/* Hiển thị phần tử giao diện form và nội dung con của nó. */}
        <form onSubmit={handleLogin} className="space-y-6">
          {error && (
            <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-sm p-3 rounded-xl text-center">
              {error}
            </div>
          )}

          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="space-y-1">
            {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
            <label className="text-slate-400 text-xs font-bold uppercase ml-1">Tên đăng nhập hoặc Email</label>
            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div className="relative">
              {/* Hiển thị phần tử giao diện User và nội dung con của nó. */}
              <User className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
              {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
              <input
                type="text"
                value={usernameOrEmail}
                onChange={(e) => setUsernameOrEmail(e.target.value)}
                required
                placeholder="admin hoặc admin@cinestream.com"
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 pl-10 outline-none focus:ring-2 focus:ring-blue-500 transition-all shadow-inner"
              />
            </div>
          </div>

          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="space-y-1">
            {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
            <label className="text-slate-400 text-xs font-bold uppercase ml-1">Mật khẩu</label>
            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div className="relative">
              {/* Hiển thị phần tử giao diện Lock và nội dung con của nó. */}
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
              {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                placeholder="••••••••"
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 pl-10 outline-none focus:ring-2 focus:ring-blue-500 transition-all shadow-inner"
              />
            </div>
          </div>

          {/* Hiển thị phần tử giao diện giao diện và nội dung con của nó. */}
          <motion.button
            type="submit"
            disabled={loading}
            whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}
            className="w-full bg-linear-to-r from-blue-600 to-indigo-600 text-white py-4 rounded-xl font-bold text-lg flex items-center justify-center gap-2 shadow-xl shadow-blue-600/30 hover:shadow-blue-500/50 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? (
              <><Loader2 className="animate-spin" size={20} /> Đang xác thực...</>
            ) : (
              <>Đăng nhập hệ thống <ArrowRight size={20} /></>
            )}
          </motion.button>
        </form>
      </motion.div>
    </div>
  );
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default Login;