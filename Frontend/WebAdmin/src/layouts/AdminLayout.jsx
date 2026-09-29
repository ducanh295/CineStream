 
import { Outlet } from 'react-router-dom';
 
import Sidebar from './Sidebar';
 
import { motion, AnimatePresence } from 'framer-motion';
 
import { useAuth } from '../context/useAuth';

 
const AdminLayout = () => {
   
  const { user } = useAuth();

   
  const displayName = user?.profile?.displayName || user?.username || 'Quản trị viên';
   
  const initials = displayName.trim().charAt(0).toUpperCase() || 'A';

   
  return (
    <div className="flex min-h-screen overflow-x-hidden bg-[#020617]">
      {/* Hiển thị phần tử giao diện Sidebar và nội dung con của nó. */}
      <Sidebar />
      {/* Hiển thị phần tử giao diện main và nội dung con của nó. */}
      <main className="ml-64 min-h-screen min-w-0 w-[calc(100%-16rem)]">
        {/* Hiển thị phần tử giao diện header và nội dung con của nó. */}
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
          {/* Hiển thị phần tử giao diện AnimatePresence và nội dung con của nó. */}
          <AnimatePresence mode="wait">
            {/* Hiển thị phần tử giao diện giao diện và nội dung con của nó. */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
            >
              {/* Hiển thị phần tử giao diện Outlet và nội dung con của nó. */}
              <Outlet />
            </motion.div>
          </AnimatePresence>
        </div>
      </main>
    </div>
  );
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default AdminLayout;
