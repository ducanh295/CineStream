import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import { motion, AnimatePresence } from 'framer-motion';
import { useAuth } from '../context/useAuth';

const AdminLayout = () => {
  const { user } = useAuth();

  const displayName = user?.profile?.displayName || user?.username || 'Quản trị viên';
  const initials = displayName.trim().charAt(0).toUpperCase() || 'A';

  return (
    <div className="flex bg-[#020617] min-h-screen">
      <Sidebar />
      <main className="flex-1 ml-64 min-h-screen">
        <header className="h-16 border-b border-slate-800 flex items-center justify-end px-8 bg-[#020617]/50 backdrop-blur-md sticky top-0 z-40">
          <div className="flex items-center gap-4">
            <div className="text-right">
              <p className="text-sm font-semibold text-white">{displayName}</p>
              <p className="text-xs text-slate-400">{user?.email || ''}</p>
            </div>
            {user?.profile?.avatarUrl ? (
              <img
                src={user.profile.avatarUrl}
                alt={displayName}
                className="w-10 h-10 rounded-full object-cover border-2 border-slate-700 shadow-inner"
              />
            ) : (
              <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-blue-600 to-purple-600 border-2 border-slate-700 shadow-inner flex items-center justify-center text-white font-bold">
                {initials}
              </div>
            )}
          </div>
        </header>

        <div className="p-8">
          <AnimatePresence mode="wait">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
            >
              <Outlet />
            </motion.div>
          </AnimatePresence>
        </div>
      </main>
    </div>
  );
};

export default AdminLayout;