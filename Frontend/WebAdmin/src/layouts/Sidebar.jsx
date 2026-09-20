// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { motion } from 'framer-motion';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { LayoutDashboard, Film, Tag, Users, CreditCard, MessageSquare, Settings, LogOut } from 'lucide-react';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { Link, useLocation, useNavigate } from 'react-router-dom';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { useAuth } from '../context/useAuth';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const menuItems = [
  { icon: LayoutDashboard, label: 'Dashboard', path: '/' },
  { icon: Film, label: 'Phim & Series', path: '/movies' },
  { icon: Users, label: 'Người dùng', path: '/users' },
  { icon: Tag, label: 'Thể loại', path: '/categories' },
  { icon: CreditCard, label: 'Gói dịch vụ', path: '/subscriptions' },
  { icon: MessageSquare, label: 'AI Chatbot', path: '/ai-chat' },
  { icon: Settings, label: 'Cấu hình', path: '/settings' },
];

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const Sidebar = () => {
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const location = useLocation();
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const navigate = useNavigate();
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const { logout } = useAuth();

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const handleLogout = () => {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    logout();
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    navigate('/login', { replace: true });
  };

  // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
  return (
    <motion.aside
      initial={{ x: -250 }} animate={{ x: 0 }}
      className="w-64 bg-[#0f172a] text-white h-screen fixed left-0 top-0 z-50 border-r border-slate-800"
    >
      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
      <div className="p-6 flex items-center gap-3">
        {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
        <div className="w-10 h-10 bg-blue-600 rounded-xl flex items-center justify-center font-bold text-xl shadow-lg shadow-blue-500/50">C</div>
        {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
        <span className="text-xl font-bold bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">CineStream</span>
      </div>

      {/* Hiển thị phần tử giao diện nav và nội dung con của nó. */}
      <nav className="mt-6 px-4 space-y-2">
        {menuItems.map((item) => {
          // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
          const isActive = location.pathname === item.path;
          // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
          return (
            <Link key={item.path} to={item.path}>
              {/* Hiển thị phần tử giao diện giao diện và nội dung con của nó. */}
              <motion.div
                whileHover={{ x: 5 }} whileTap={{ scale: 0.95 }}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-300 ${
                  isActive ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/30' : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                }`}
              >
                {/* Hiển thị phần tử giao diện giao diện và nội dung con của nó. */}
                <item.icon size={20} />
                {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                <span className="font-medium">{item.label}</span>
              </motion.div>
            </Link>
          );
        })}
      </nav>

      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
      <div className="absolute bottom-6 w-full px-4 border-t border-slate-800 pt-6">
        {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-4 py-3 text-red-400 hover:bg-red-500/10 w-full rounded-xl transition-colors"
        >
          {/* Hiển thị phần tử giao diện LogOut và nội dung con của nó. */}
          <LogOut size={20} />
          {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
          <span className="font-medium">Đăng xuất</span>
        </button>
      </div>
    </motion.aside>
  );
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default Sidebar;