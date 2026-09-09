import { motion } from 'framer-motion';
import { LayoutDashboard, Film, Users, CreditCard, MessageSquare, Settings, LogOut } from 'lucide-react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/useAuth';

const menuItems = [
  { icon: LayoutDashboard, label: 'Dashboard', path: '/' },
  { icon: Film, label: 'Phim & Series', path: '/movies' },
  { icon: Users, label: 'Người dùng', path: '/users' },
  { icon: CreditCard, label: 'Gói dịch vụ', path: '/subscriptions' },
  { icon: MessageSquare, label: 'AI Chatbot', path: '/ai-chat' },
  { icon: Settings, label: 'Cấu hình', path: '/settings' },
];

const Sidebar = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { logout } = useAuth();

  const handleLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  return (
    <motion.aside
      initial={{ x: -250 }} animate={{ x: 0 }}
      className="w-64 bg-[#0f172a] text-white h-screen fixed left-0 top-0 z-50 border-r border-slate-800"
    >
      <div className="p-6 flex items-center gap-3">
        <div className="w-10 h-10 bg-blue-600 rounded-xl flex items-center justify-center font-bold text-xl shadow-lg shadow-blue-500/50">C</div>
        <span className="text-xl font-bold bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">CineStream</span>
      </div>

      <nav className="mt-6 px-4 space-y-2">
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <Link key={item.path} to={item.path}>
              <motion.div
                whileHover={{ x: 5 }} whileTap={{ scale: 0.95 }}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-300 ${
                  isActive ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/30' : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <item.icon size={20} />
                <span className="font-medium">{item.label}</span>
              </motion.div>
            </Link>
          );
        })}
      </nav>

      <div className="absolute bottom-6 w-full px-4 border-t border-slate-800 pt-6">
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-4 py-3 text-red-400 hover:bg-red-500/10 w-full rounded-xl transition-colors"
        >
          <LogOut size={20} />
          <span className="font-medium">Đăng xuất</span>
        </button>
      </div>
    </motion.aside>
  );
};

export default Sidebar;