// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { Outlet } from 'react-router-dom';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import Sidebar from './Sidebar';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { motion, AnimatePresence } from 'framer-motion';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { useAuth } from '../context/useAuth';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const AdminLayout = () => {
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const { user } = useAuth();

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const displayName = user?.profile?.displayName || user?.username || 'Quản trị viên';
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const initials = displayName.trim().charAt(0).toUpperCase() || 'A';

  // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
  return (
    <div className="flex min-h-screen overflow-x-hidden bg-[#020617]">
      {/* Hiển thị phần tử giao diện Sidebar và nội dung con của nó. */}
      <Sidebar />
      {/* Hiển thị phần tử giao diện main và nội dung con của nó. */}
      <main className="ml-64 min-h-screen min-w-0 w-[calc(100%-16rem)]">
        {/* Hiển thị phần tử giao diện header và nội dung con của nó. */}
        <header className="h-16 border-b border-slate-800 flex items-center justify-end px-8 bg-[#020617]/50 backdrop-blur-md sticky top-0 z-40">
          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="flex items-center gap-4">
            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div className="text-right">
              {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
              <p className="text-sm font-semibold text-white">{displayName}</p>
              {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
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

        {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
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
