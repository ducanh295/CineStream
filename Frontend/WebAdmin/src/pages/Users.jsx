import { useState, useEffect, useCallback } from 'react';
import { motion } from 'framer-motion';
import { ShieldCheck, Shield, Mail, Calendar, Search, Ban, CheckCircle2, Trash2, Loader2, RefreshCw } from 'lucide-react';
import userApi from '../api/userApi';
import ConfirmDialog from '../components/ConfirmDialog';

const ROLE_LABEL = { 0: 'Người dùng', 1: 'Quản trị viên' };

const formatDate = (isoString) => (isoString ? new Date(isoString).toLocaleDateString('vi-VN') : '—');

const Users = () => {
  const [users, setUsers] = useState([]);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');
  const [toggleTarget, setToggleTarget] = useState(null);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [lockReason, setLockReason] = useState('Vi phạm quy định sử dụng hệ thống');
  const [actionLoading, setActionLoading] = useState(false);

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    setErrorMsg('');
    try {
      const result = await userApi.getAllUsers({ search: search.trim() || undefined, page, pageSize: 12 });
      const paged = result?.data;
      setUsers(Array.isArray(paged) ? paged : paged?.items || []);
      setTotalPages(paged?.totalPages || 1);
      setTotalCount(paged?.totalCount || 0);
    } catch (err) {
      setErrorMsg(err.message || 'Không thể tải danh sách người dùng.');
      setUsers([]);
    } finally {
      setLoading(false);
    }
  }, [page, search]);

  useEffect(() => {
    const timer = setTimeout(fetchUsers, 350);
    return () => clearTimeout(timer);
  }, [fetchUsers]);

  const handleSearch = (event) => {
    setSearch(event.target.value);
    setPage(1);
  };

  const handleToggleStatus = async () => {
    if (!toggleTarget) return;
    setActionLoading(true);
    try {
      if (toggleTarget.isLocked) await userApi.unlockUser(toggleTarget.id);
      else {
        if (!lockReason.trim()) return;
        await userApi.lockUser(toggleTarget.id, lockReason.trim());
      }
      setToggleTarget(null);
      await fetchUsers();
    } catch (err) {
      setErrorMsg(err.message || 'Không thể cập nhật trạng thái tài khoản.');
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setActionLoading(true);
    try {
      await userApi.deleteUser(deleteTarget.id);
      setDeleteTarget(null);
      if (users.length === 1 && page > 1) setPage((current) => current - 1);
      else await fetchUsers();
    } catch (err) {
      setErrorMsg(err.message || 'Xóa tài khoản thất bại.');
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white">Quản lý người dùng</h1>
          <p className="text-slate-400 mt-1">{totalCount} tài khoản từ dữ liệu thật của hệ thống.</p>
        </div>
        <button type="button" disabled title="Backend chưa có API tạo tài khoản từ trang quản trị" className="bg-slate-800 text-slate-500 px-5 py-3 rounded-xl font-bold cursor-not-allowed">
          Thêm thành viên (chưa hỗ trợ)
        </button>
      </div>

      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
          <input type="text" value={search} onChange={handleSearch} placeholder="Tìm email, tên đăng nhập hoặc tên hiển thị..." className="w-full bg-slate-900 border border-slate-800 text-white rounded-xl py-3 pl-10 pr-4 focus:ring-2 focus:ring-purple-500 outline-none transition-all" />
        </div>
        <button type="button" onClick={fetchUsers} disabled={loading} className="bg-slate-900 border border-slate-800 text-slate-300 px-4 py-3 rounded-xl flex items-center justify-center gap-2 hover:bg-slate-800 disabled:opacity-50">
          <RefreshCw size={18} className={loading ? 'animate-spin' : ''} /> Làm mới
        </button>
      </div>

      {errorMsg && <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-sm p-3 rounded-xl">{errorMsg}</div>}

      {loading && users.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-slate-500 bg-slate-900 border border-slate-800 rounded-2xl"><Loader2 className="animate-spin mb-3" size={32} /><p>Đang tải danh sách người dùng...</p></div>
      ) : users.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-slate-500 bg-slate-900 border border-slate-800 rounded-2xl"><ShieldCheck size={40} className="mb-3 opacity-50" /><p>Không tìm thấy người dùng phù hợp.</p></div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {users.map((user, index) => (
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: index * 0.05 }} key={user.id} className="bg-slate-900 border border-slate-800 p-5 rounded-2xl flex items-center gap-4 hover:border-purple-500/50 transition-all group">
              <div className="w-16 h-16 rounded-full bg-linear-to-br from-slate-800 to-slate-700 flex items-center justify-center border-2 border-slate-800 group-hover:border-purple-500/50 transition-all overflow-hidden shrink-0">
                {user.profile?.avatarUrl ? <img src={user.profile.avatarUrl} alt={user.username} className="w-full h-full object-cover" /> : user.role === 1 ? <ShieldCheck className="text-purple-400" /> : <Shield className="text-slate-500" />}
              </div>
              <div className="flex-1 min-w-0">
                <h3 className="text-white font-bold truncate">{user.profile?.displayName || user.username}</h3>
                <div className="flex flex-col gap-1 mt-1 text-slate-500 text-sm"><span className="flex items-center gap-1 truncate"><Mail size={14} className="shrink-0" /> {user.email}</span><span className="flex items-center gap-1"><Calendar size={14} /> {formatDate(user.createdAt)}</span></div>
              </div>
              <div className="flex flex-col items-end gap-2 shrink-0">
                <span className={`text-[10px] px-2 py-1 rounded-md font-bold border uppercase tracking-tighter ${user.role === 1 ? 'bg-purple-500/10 text-purple-400 border-purple-500/20' : 'bg-slate-800 text-slate-400 border-slate-700'}`}>{ROLE_LABEL[user.role] || 'Không xác định'}</span>
                <div className="flex items-center gap-1">
                  <button type="button" onClick={() => { setLockReason('Vi phạm quy định sử dụng hệ thống'); setToggleTarget(user); }} title={user.isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản'} className={`p-1.5 rounded-lg transition-all ${user.isLocked ? 'hover:bg-green-500/10 hover:text-green-400 text-slate-500' : 'hover:bg-amber-500/10 hover:text-amber-400 text-slate-500'}`}>{user.isLocked ? <CheckCircle2 size={16} /> : <Ban size={16} />}</button>
                  <button type="button" onClick={() => setDeleteTarget(user)} title="Xóa tài khoản" className="p-1.5 hover:bg-red-500/10 hover:text-red-400 text-slate-500 rounded-lg transition-all"><Trash2 size={16} /></button>
                </div>
                <div className="flex items-center gap-1.5"><div className={`w-2 h-2 rounded-full ${user.isLocked ? 'bg-slate-600' : 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]'}`} /><span className="text-[10px] text-slate-500">{user.isLocked ? 'Đã khóa' : 'Hoạt động'}</span></div>
              </div>
            </motion.div>
          ))}
        </div>
      )}

      {totalPages > 1 && <div className="flex items-center justify-between bg-slate-900 border border-slate-800 rounded-xl px-4 py-3 text-sm"><span className="text-slate-500">Trang {page} / {totalPages}</span><div className="flex gap-2"><button type="button" disabled={page === 1 || loading} onClick={() => setPage((current) => current - 1)} className="px-3 py-1.5 rounded-lg bg-slate-800 text-slate-300 disabled:opacity-40">Trước</button><button type="button" disabled={page === totalPages || loading} onClick={() => setPage((current) => current + 1)} className="px-3 py-1.5 rounded-lg bg-slate-800 text-slate-300 disabled:opacity-40">Sau</button></div></div>}

      <ConfirmDialog open={Boolean(toggleTarget)} title={toggleTarget?.isLocked ? 'Mở khóa tài khoản?' : 'Khóa tài khoản?'} description={toggleTarget ? `Tài khoản "${toggleTarget.username}" sẽ ${toggleTarget.isLocked ? 'được phép đăng nhập trở lại' : 'không thể đăng nhập cho đến khi được mở khóa'}.` : ''} confirmLabel={toggleTarget?.isLocked ? 'Mở khóa' : 'Khóa tài khoản'} loading={actionLoading} onConfirm={handleToggleStatus} onCancel={() => setToggleTarget(null)} />
      <ConfirmDialog open={Boolean(deleteTarget)} title="Xóa tài khoản?" description={deleteTarget ? `Bạn có chắc muốn xóa tài khoản "${deleteTarget.username}"?` : ''} confirmLabel="Xóa tài khoản" loading={actionLoading} onConfirm={handleDelete} onCancel={() => setDeleteTarget(null)} />
    </div>
  );
};

export default Users;
