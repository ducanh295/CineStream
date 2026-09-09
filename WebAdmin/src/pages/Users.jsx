import { useState } from 'react';
import { motion } from 'framer-motion';
import { UserPlus, ShieldCheck, Shield, Mail, Calendar, Search, Ban, CheckCircle2, Trash2 } from 'lucide-react';
import ConfirmDialog from '../components/ConfirmDialog';

// ⚠️ DỮ LIỆU MẪU tạm thời cho UsersController.
// Cấu trúc được thiết kế khớp sẵn với UserDto + ProfileDto đã thống nhất,
// khi có API thật chỉ cần thay useState này bằng gọi userApi.getAll().
const MOCK_USERS = [
  {
    id: 1,
    username: 'admin',
    email: 'admin@cinestream.com',
    role: 1, // Admin
    isActive: true,
    createdAt: '2024-01-15T00:00:00Z',
    profile: { displayName: 'Quản Trị Viên CineStream', avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150' },
  },
  {
    id: 2,
    username: 'user',
    email: 'user@cinestream.com',
    role: 0, // User
    isActive: true,
    createdAt: '2024-02-20T00:00:00Z',
    profile: { displayName: 'Khách Xem Phim', avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150' },
  },
  {
    id: 3,
    username: 'linhnhi1601',
    email: 'linhnhi1601@gmail.com',
    role: 0,
    isActive: false,
    createdAt: '2024-03-10T00:00:00Z',
    profile: { displayName: 'Linh Nhi', avatarUrl: null },
  },
];

const ROLE_LABEL = { 0: 'Người dùng', 1: 'Quản trị viên' };

const formatDate = (isoString) => {
  const d = new Date(isoString);
  return d.toLocaleDateString('vi-VN');
};

const Users = () => {
  const [users, setUsers] = useState(MOCK_USERS);
  const [search, setSearch] = useState('');
  const [toggleTarget, setToggleTarget] = useState(null); // user object đang chờ khóa/mở
  const [deleteTarget, setDeleteTarget] = useState(null);

  const filteredUsers = users.filter((u) => {
    const term = search.trim().toLowerCase();
    if (!term) return true;
    return (
      u.username.toLowerCase().includes(term) ||
      u.email.toLowerCase().includes(term) ||
      (u.profile?.displayName || '').toLowerCase().includes(term)
    );
  });

  // TODO(API thật): thay bằng gọi userApi.toggleStatus(id) khi Backend có endpoint
  const handleToggleStatus = () => {
    if (!toggleTarget) return;
    setUsers((prev) =>
      prev.map((u) => (u.id === toggleTarget.id ? { ...u, isActive: !u.isActive } : u))
    );
    setToggleTarget(null);
  };

  // TODO(API thật): thay bằng gọi userApi.delete(id) khi Backend có endpoint
  const handleDelete = () => {
    if (!deleteTarget) return;
    setUsers((prev) => prev.filter((u) => u.id !== deleteTarget.id));
    setDeleteTarget(null);
  };

  return (
    <div className="space-y-6">
      {/* Banner cảnh báo dữ liệu mẫu — xóa khi đã nối API thật */}
      <div className="bg-amber-500/10 border border-amber-500/20 text-amber-400 text-sm px-4 py-2.5 rounded-xl">
        ⚠️ Trang đang hiển thị dữ liệu mẫu.
      </div>

      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white">Quản lý người dùng</h1>
          <p className="text-slate-400 mt-1">Quản lý tài khoản, phân quyền và trạng thái hoạt động.</p>
        </div>
        <motion.button
          whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}
          className="bg-purple-600 hover:bg-purple-700 text-white px-6 py-3 rounded-xl flex items-center gap-2 font-bold shadow-lg shadow-purple-600/30 transition-all"
        >
          <UserPlus size={20} /> Thêm thành viên
        </motion.button>
      </div>

      <div className="relative max-w-md">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Tìm email, tên đăng nhập hoặc tên hiển thị..."
          className="w-full bg-slate-900 border border-slate-800 text-white rounded-xl py-3 pl-10 pr-4 focus:ring-2 focus:ring-purple-500 outline-none transition-all"
        />
      </div>

      {filteredUsers.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-slate-500 bg-slate-900 border border-slate-800 rounded-2xl">
          <ShieldCheck size={40} className="mb-3 opacity-50" />
          <p>Không tìm thấy người dùng phù hợp.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {filteredUsers.map((u, i) => (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              key={u.id}
              className="bg-slate-900 border border-slate-800 p-5 rounded-2xl flex items-center gap-4 hover:border-purple-500/50 transition-all group"
            >
              <div className="w-16 h-16 rounded-full bg-linear-to-br from-slate-800 to-slate-700 flex items-center justify-center border-2 border-slate-800 group-hover:border-purple-500/50 transition-all overflow-hidden shrink-0">
                {u.profile?.avatarUrl ? (
                  <img src={u.profile.avatarUrl} alt={u.username} className="w-full h-full object-cover" />
                ) : u.role === 1 ? (
                  <ShieldCheck className="text-purple-400" />
                ) : (
                  <Shield className="text-slate-500" />
                )}
              </div>

              <div className="flex-1 min-w-0">
                <h3 className="text-white font-bold truncate">{u.profile?.displayName || u.username}</h3>
                <div className="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-3 mt-1 text-slate-500 text-sm">
                  <span className="flex items-center gap-1 truncate"><Mail size={14} className="shrink-0" /> {u.email}</span>
                  <span className="flex items-center gap-1 shrink-0"><Calendar size={14} /> {formatDate(u.createdAt)}</span>
                </div>
              </div>

              <div className="flex flex-col items-end gap-2 shrink-0">
                <span
                  className={`text-[10px] px-2 py-1 rounded-md font-bold border uppercase tracking-tighter ${
                    u.role === 1
                      ? 'bg-purple-500/10 text-purple-400 border-purple-500/20'
                      : 'bg-slate-800 text-slate-400 border-slate-700'
                  }`}
                >
                  {ROLE_LABEL[u.role]}
                </span>

                <div className="flex items-center gap-1">
                  <button
                    onClick={() => setToggleTarget(u)}
                    title={u.isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản'}
                    className={`p-1.5 rounded-lg transition-all ${
                      u.isActive
                        ? 'hover:bg-amber-500/10 hover:text-amber-400 text-slate-500'
                        : 'hover:bg-green-500/10 hover:text-green-400 text-slate-500'
                    }`}
                  >
                    {u.isActive ? <Ban size={16} /> : <CheckCircle2 size={16} />}
                  </button>
                  <button
                    onClick={() => setDeleteTarget(u)}
                    title="Xóa tài khoản"
                    className="p-1.5 hover:bg-red-500/10 hover:text-red-400 text-slate-500 rounded-lg transition-all"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>

                <div className="flex items-center gap-1.5">
                  <div className={`w-2 h-2 rounded-full ${u.isActive ? 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]' : 'bg-slate-600'}`}></div>
                  <span className="text-[10px] text-slate-500">{u.isActive ? 'Hoạt động' : 'Đã khóa'}</span>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      )}

      <ConfirmDialog
        open={Boolean(toggleTarget)}
        title={toggleTarget?.isActive ? 'Khóa tài khoản?' : 'Mở khóa tài khoản?'}
        description={
          toggleTarget
            ? toggleTarget.isActive
              ? `Tài khoản "${toggleTarget.username}" sẽ không thể đăng nhập cho đến khi được mở khóa lại.`
              : `Tài khoản "${toggleTarget.username}" sẽ có thể đăng nhập trở lại.`
            : ''
        }
        confirmLabel={toggleTarget?.isActive ? 'Khóa tài khoản' : 'Mở khóa'}
        onConfirm={handleToggleStatus}
        onCancel={() => setToggleTarget(null)}
      />

      <ConfirmDialog
        open={Boolean(deleteTarget)}
        title="Xóa tài khoản?"
        description={deleteTarget ? `Bạn có chắc muốn xóa vĩnh viễn tài khoản "${deleteTarget.username}"? Hành động này không thể hoàn tác.` : ''}
        confirmLabel="Xóa tài khoản"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  );
};

export default Users;