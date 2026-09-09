import { motion } from 'framer-motion';
import { Plus, Search, Filter, Edit2, Trash2, PlayCircle } from 'lucide-react';

const Movies = () => {
  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white">Quản lý nội dung</h1>
          <p className="text-slate-400 mt-1">Danh sách phim lẻ, phim bộ và các tập phim.</p>
        </div>
        <motion.button 
          whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}
          className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-xl flex items-center gap-2 font-bold shadow-lg shadow-blue-600/30 transition-all"
        >
          <Plus size={20} /> Thêm phim mới
        </motion.button>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        {/* Thanh công cụ bảng */}
        <div className="p-4 border-b border-slate-800 flex flex-col md:flex-row gap-4 bg-slate-900/50">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
            <input type="text" placeholder="Tìm kiếm phim, diễn viên..." className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl py-2 pl-10 pr-4 focus:ring-2 focus:ring-blue-500 outline-none transition-all" />
          </div>
          <div className="flex gap-2">
            <button className="bg-slate-800 text-slate-300 px-4 py-2 rounded-xl border border-slate-700 flex items-center gap-2 hover:bg-slate-700"><Filter size={18} /> Lọc</button>
          </div>
        </div>

        {/* Bảng dữ liệu */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead className="bg-slate-800/50 text-slate-400 uppercase text-xs font-bold tracking-wider">
              <tr>
                <th className="px-6 py-4">Phim</th>
                <th className="px-6 py-4">Phân loại</th>
                <th className="px-6 py-4">Trạng thái</th>
                <th className="px-6 py-4 text-center">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800 text-slate-300">
              {[1, 2, 3, 4, 5].map((item, index) => (
                <motion.tr 
                  initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: index * 0.05 }}
                  key={item} className="hover:bg-slate-800/30 transition-colors group"
                >
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-16 bg-slate-800 rounded-lg flex items-center justify-center border border-slate-700 group-hover:border-blue-500 transition-all overflow-hidden relative">
                        <PlayCircle className="text-white/20 absolute z-10" />
                      </div>
                      <div>
                        <p className="font-bold text-white italic text-slate-500">Đang đồng bộ dữ liệu...</p>
                        <span className="text-xs text-slate-500 italic">ID: MOVIE-2024-{item}</span>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="px-3 py-1 rounded-full text-xs font-bold bg-blue-500/10 text-blue-400 border border-blue-500/20">Hành động</span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 rounded-full bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]"></div>
                      <span className="text-sm font-medium">Hoạt động</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center justify-center gap-2">
                      <button className="p-2 hover:bg-blue-500/10 hover:text-blue-400 rounded-lg transition-all"><Edit2 size={18} /></button>
                      <button className="p-2 hover:bg-red-500/10 hover:text-red-400 rounded-lg transition-all"><Trash2 size={18} /></button>
                    </div>
                  </td>
                </motion.tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
export default Movies;