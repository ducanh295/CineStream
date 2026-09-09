import { motion } from 'framer-motion';
import { UserPlus, ShieldCheck, Mail, Calendar, Search } from 'lucide-react';

const Users = () => {
  return (
    <div className="space-y-6">
      {/* Header với nút Thêm người dùng sử dụng icon UserPlus */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white">Quản lý người dùng</h1>
          <p className="text-slate-400 mt-1">Quản lý tài khoản, phân quyền và lịch sử đăng nhập hệ thống.</p>
        </div>
        <motion.button 
          whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}
          className="bg-purple-600 hover:bg-purple-700 text-white px-6 py-3 rounded-xl flex items-center gap-2 font-bold shadow-lg shadow-purple-600/30 transition-all"
        >
          <UserPlus size={20} /> Thêm thành viên
        </motion.button>
      </div>

      {/* Thanh tìm kiếm nhanh */}
      <div className="relative max-w-md">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
        <input 
          type="text" 
          placeholder="Tìm email hoặc tên người dùng..." 
          className="w-full bg-slate-900 border border-slate-800 text-white rounded-xl py-3 pl-10 pr-4 focus:ring-2 focus:ring-purple-500 outline-none transition-all" 
        />
      </div>

      {/* Danh sách người dùng dạng Card hiện đại */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {[1, 2, 3, 4].map((i) => (
          <motion.div 
            initial={{ opacity: 0, y: 20 }} 
            animate={{ opacity: 1, y: 0 }} 
            transition={{ delay: i * 0.1 }}
            key={i} 
            className="bg-slate-900 border border-slate-800 p-5 rounded-2xl flex items-center gap-4 hover:border-purple-500/50 transition-all group cursor-pointer"
          >
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-slate-800 to-slate-700 flex items-center justify-center border-2 border-slate-800 group-hover:border-purple-500/50 transition-all">
               <ShieldCheck className="text-slate-500 group-hover:text-purple-400 transition-colors" />
            </div>
            <div className="flex-1">
              <h3 className="text-white font-bold italic text-slate-500">Đang tải tên người dùng...</h3>
              <div className="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-3 mt-1 text-slate-500 text-sm">
                <span className="flex items-center gap-1"><Mail size={14} /> user@cinestream.com</span>
                <span className="flex items-center gap-1"><Calendar size={14} /> 20/09/2024</span>
              </div>
            </div>
            <div className="flex flex-col items-end gap-2">
              <span className="bg-purple-500/10 text-purple-400 text-[10px] px-2 py-1 rounded-md font-bold border border-purple-500/20 uppercase tracking-tighter">Admin</span>
              <div className="w-2 h-2 rounded-full bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]"></div>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
};

export default Users;