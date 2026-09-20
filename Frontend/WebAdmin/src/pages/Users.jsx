import { useState, useEffect, useCallback } from 'react';
import { motion } from 'framer-motion';
import { ShieldCheck, Shield, Mail, Calendar, Search, Ban, CheckCircle2, Trash2, Loader2, RefreshCw, Crown, Clock } from 'lucide-react';
import userApi from '../api/userApi';
import ConfirmDialog from '../components/ConfirmDialog';
import Modal from '../components/Modal';

const ROLE_LABEL = { 0: 'Người dùng', 1: 'Quản trị viên' };

const formatDate = (isoString) => (isoString ? new Date(isoString).toLocaleDateString('vi-VN') : '—');

const getPremiumStatus = (user) => {
  if (!user.isPremium) {
    return { label: 'Gói thường', color: 'bg-slate-800 text-slate-400 border-slate-700', active: false };
  }
  if (!user.premiumExpiresAt) {
    return { label: 'VIP Vĩnh viễn', color: 'bg-amber-500/20 text-amber-300 border-amber-500/40 shadow-sm shadow-amber-500/10', active: true };
  }
  const isExpired = new Date(user.premiumExpiresAt) <= new Date();
  if (isExpired) {
    return { label: 'VIP Hết hạn', color: 'bg-red-500/10 text-red-400 border-red-500/20', active: false };
  }
  return { label: 'VIP Premium', color: 'bg-amber-500/20 text-amber-300 border-amber-500/40 shadow-sm shadow-amber-500/10', active: true };
};

const DURATION_PRESETS = [
  { label: '+7 ngày (Dùng thử)', days: 7 },
  { label: '+30 ngày (1 Tháng)', days: 30 },
  { label: '+90 ngày (3 Tháng)', days: 90 },
  { label: '+365 ngày (1 Năm)', days: 365 },
  { label: 'Vĩnh viễn (Lifetime)', days: 0 },
];

const Users = () => {
  const [users, setUsers] = useState([]);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');
  const [successMsg, setSuccessMsg] = useState('');
  const [toggleTarget, setToggleTarget] = useState(null);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [lockReason, setLockReason] = useState('Vi phạm quy định sử dụng hệ thống');
  const [actionLoading, setActionLoading] = useState(false);

  // State quản lý Modal Bật/Tắt Premium thủ công
  const [premiumTarget, setPremiumTarget] = useState(null);
  const [premiumForm, setPremiumForm] = useState({ isPremium: true, durationDays: 30, reason: '' });
  const [premiumLoading, setPremiumLoading] = useState(false);

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

  const openPremiumModal = (user) => {
    setPremiumTarget(user);
    setPremiumForm({
      isPremium: true,
      durationDays: 30,
      reason: '',
    });
  };

  const handleSavePremium = async (e) => {
    e.preventDefault();
    if (!premiumTarget) return;
    setPremiumLoading(true);
    setErrorMsg('');
    try {
      await userApi.setPremium(premiumTarget.id, {
        isPremium: premiumForm.isPremium,
        durationDays: premiumForm.isPremium ? (premiumForm.durationDays === 0 ? null : premiumForm.durationDays) : null,
        reason: premiumForm.reason.trim() || undefined,
      });

      setSuccessMsg(
        premiumForm.isPremium
          ? `Đã cập nhật gói Premium cho tài khoản "${premiumTarget.username}" thành công!`
          : `Đã thu hồi gói Premium của tài khoản "${premiumTarget.username}" thành công!`
      );
      setPremiumTarget(null);
      await fetchUsers();
      setTimeout(() => setSuccessMsg(''), 4000);
    } catch (err) {
      setErrorMsg(err.message || 'Cập nhật gói Premium thất bại.');
    } finally {
      setPremiumLoading(false);
    }
  };

  // Tính toán thời gian hết hạn dự tính để hiển thị xem trước
  const calculateEstimatedExpiry = () => {
    if (!premiumForm.isPremium) return 'Tài khoản thường (Không có Premium)';
    if (premiumForm.durationDays === 0) return 'Vĩnh viễn (Không thời hạn)';
    const days = premiumForm.durationDays || 30;
    let baseDate = new Date();
    if (premiumTarget?.isPremium && premiumTarget?.premiumExpiresAt) {
      const existingDate = new Date(premiumTarget.premiumExpiresAt);
      if (existingDate > baseDate) {
        baseDate = existingDate;
      }
    }
    const targetDate = new Date(baseDate.getTime() + days * 24 * 60 * 60 * 1000);
    return targetDate.toLocaleDateString('vi-VN');
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
      {successMsg && <div className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-sm p-3 rounded-xl">{successMsg}</div>}

      {loading && users.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-slate-500 bg-slate-900 border border-slate-800 rounded-2xl"><Loader2 className="animate-spin mb-3" size={32} /><p>Đang tải danh sách người dùng...</p></div>
      ) : users.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-slate-500 bg-slate-900 border border-slate-800 rounded-2xl"><ShieldCheck size={40} className="mb-3 opacity-50" /><p>Không tìm thấy người dùng phù hợp.</p></div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {users.map((user, index) => {
            const pStatus = getPremiumStatus(user);
            return (
              <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: index * 0.05 }} key={user.id} className="bg-slate-900 border border-slate-800 p-5 rounded-2xl flex items-center gap-4 hover:border-purple-500/50 transition-all group">
                <div className="w-16 h-16 rounded-full bg-linear-to-br from-slate-800 to-slate-700 flex items-center justify-center border-2 border-slate-800 group-hover:border-purple-500/50 transition-all overflow-hidden shrink-0">
                  {user.profile?.avatarUrl ? <img src={user.profile.avatarUrl} alt={user.username} className="w-full h-full object-cover" /> : user.role === 1 ? <ShieldCheck className="text-purple-400" /> : <Shield className="text-slate-500" />}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="text-white font-bold truncate">{user.profile?.displayName || user.username}</h3>
                    {pStatus.active && (
                      <span className="shrink-0 p-1 rounded-full bg-amber-500/10 text-amber-400 border border-amber-500/20" title="Thành viên VIP Premium">
                        <Crown size={12} />
                      </span>
                    )}
                  </div>
                  <div className="flex flex-col gap-1 mt-1 text-slate-500 text-sm">
                    <span className="flex items-center gap-1 truncate"><Mail size={14} className="shrink-0" /> {user.email}</span>
                    <span className="flex items-center gap-1"><Calendar size={14} /> Tạo ngày: {formatDate(user.createdAt)}</span>
                  </div>
                </div>
                <div className="flex flex-col items-end gap-2 shrink-0">
                  <div className="flex flex-col items-end gap-1">
                    <span className={`text-[10px] px-2 py-0.5 rounded-md font-bold border uppercase tracking-tighter ${user.role === 1 ? 'bg-purple-500/10 text-purple-400 border-purple-500/20' : 'bg-slate-800 text-slate-400 border-slate-700'}`}>{ROLE_LABEL[user.role] || 'Không xác định'}</span>
                    <span className={`text-[10px] px-2 py-0.5 rounded-md font-bold border tracking-tight flex items-center gap-1 ${pStatus.color}`}>
                      {pStatus.label}
                    </span>
                    {user.isPremium && user.premiumExpiresAt && (
                      <span className="text-[10px] text-slate-400 flex items-center gap-1 font-mono">
                        <Clock size={10} /> {new Date(user.premiumExpiresAt).toLocaleDateString('vi-VN')}
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      onClick={() => openPremiumModal(user)}
                      title="Quản lý gói Premium cho người dùng"
                      className={`p-1.5 rounded-lg transition-all ${
                        pStatus.active
                          ? 'bg-amber-500/15 text-amber-300 hover:bg-amber-500/25 border border-amber-500/30'
                          : 'text-slate-400 hover:bg-amber-500/10 hover:text-amber-300 border border-transparent hover:border-amber-500/20'
                      }`}
                    >
                      <Crown size={16} />
                    </button>
                    <button type="button" onClick={() => { setLockReason('Vi phạm quy định sử dụng hệ thống'); setToggleTarget(user); }} title={user.isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản'} className={`p-1.5 rounded-lg transition-all ${user.isLocked ? 'hover:bg-green-500/10 hover:text-green-400 text-slate-500' : 'hover:bg-amber-500/10 hover:text-amber-400 text-slate-500'}`}>{user.isLocked ? <CheckCircle2 size={16} /> : <Ban size={16} />}</button>
                    <button type="button" onClick={() => setDeleteTarget(user)} title="Xóa tài khoản" className="p-1.5 hover:bg-red-500/10 hover:text-red-400 text-slate-500 rounded-lg transition-all"><Trash2 size={16} /></button>
                  </div>
                  <div className="flex items-center gap-1.5"><div className={`w-2 h-2 rounded-full ${user.isLocked ? 'bg-slate-600' : 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]'}`} /><span className="text-[10px] text-slate-500">{user.isLocked ? 'Đã khóa' : 'Hoạt động'}</span></div>
                </div>
              </motion.div>
            );
          })}
        </div>
      )}

      {totalPages > 1 && <div className="flex items-center justify-between bg-slate-900 border border-slate-800 rounded-xl px-4 py-3 text-sm"><span className="text-slate-500">Trang {page} / {totalPages}</span><div className="flex gap-2"><button type="button" disabled={page === 1 || loading} onClick={() => setPage((current) => current - 1)} className="px-3 py-1.5 rounded-lg bg-slate-800 text-slate-300 disabled:opacity-40">Trước</button><button type="button" disabled={page === totalPages || loading} onClick={() => setPage((current) => current + 1)} className="px-3 py-1.5 rounded-lg bg-slate-800 text-slate-300 disabled:opacity-40">Sau</button></div></div>}

      <ConfirmDialog open={Boolean(toggleTarget)} title={toggleTarget?.isLocked ? 'Mở khóa tài khoản?' : 'Khóa tài khoản?'} description={toggleTarget ? `Tài khoản "${toggleTarget.username}" sẽ ${toggleTarget.isLocked ? 'được phép đăng nhập trở lại' : 'không thể đăng nhập cho đến khi được mở khóa'}.` : ''} confirmLabel={toggleTarget?.isLocked ? 'Mở khóa' : 'Khóa tài khoản'} loading={actionLoading} onConfirm={handleToggleStatus} onCancel={() => setToggleTarget(null)} />
      <ConfirmDialog open={Boolean(deleteTarget)} title="Xóa tài khoản?" description={deleteTarget ? `Bạn có chắc muốn xóa tài khoản "${deleteTarget.username}"?` : ''} confirmLabel="Xóa tài khoản" loading={actionLoading} onConfirm={handleDelete} onCancel={() => setDeleteTarget(null)} />

      {/* Modal Quản lý Gói Premium Thủ công */}
      <Modal
        open={Boolean(premiumTarget)}
        title="Quản lý Gói Premium"
        onClose={() => setPremiumTarget(null)}
      >
        {premiumTarget && (
          <form onSubmit={handleSavePremium} className="space-y-5">
            <div className="p-4 rounded-xl bg-slate-800/40 border border-slate-700/60 flex items-center gap-3">
              <div className="w-12 h-12 rounded-full bg-slate-700 flex items-center justify-center shrink-0 border border-slate-600">
                <Crown size={22} className="text-amber-400" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-bold text-white truncate">{premiumTarget.profile?.displayName || premiumTarget.username}</p>
                <p className="text-xs text-slate-400 truncate">{premiumTarget.email}</p>
                <p className="text-xs text-amber-400/90 mt-1">
                  Trạng thái hiện tại: <strong>{getPremiumStatus(premiumTarget).label}</strong>
                  {premiumTarget.isPremium && premiumTarget.premiumExpiresAt && ` (Đến ${formatDate(premiumTarget.premiumExpiresAt)})`}
                </p>
              </div>
            </div>

            {/* Chuyển đổi Bật / Tắt Premium */}
            <div className="space-y-2">
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Trạng thái đặc quyền</label>
              <div className="grid grid-cols-2 gap-3">
                <button
                  type="button"
                  onClick={() => setPremiumForm({ ...premiumForm, isPremium: true })}
                  className={`p-3 rounded-xl border text-sm font-bold flex items-center justify-center gap-2 transition-all ${
                    premiumForm.isPremium
                      ? 'bg-amber-500/20 border-amber-500/50 text-amber-300 shadow-md shadow-amber-500/10'
                      : 'bg-slate-800/60 border-slate-700 text-slate-400 hover:text-white'
                  }`}
                >
                  <Crown size={16} /> Bật / Gia hạn VIP
                </button>
                <button
                  type="button"
                  onClick={() => setPremiumForm({ ...premiumForm, isPremium: false })}
                  className={`p-3 rounded-xl border text-sm font-bold flex items-center justify-center gap-2 transition-all ${
                    !premiumForm.isPremium
                      ? 'bg-red-500/20 border-red-500/50 text-red-300 shadow-md shadow-red-500/10'
                      : 'bg-slate-800/60 border-slate-700 text-slate-400 hover:text-white'
                  }`}
                >
                  <Ban size={16} /> Tắt / Thu hồi VIP
                </button>
              </div>
            </div>

            {/* Các tùy chọn thời hạn khi Bật Premium */}
            {premiumForm.isPremium && (
              <div className="space-y-3 pt-2">
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Chọn thời hạn cấp / gia hạn</label>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {DURATION_PRESETS.map((preset) => (
                    <button
                      key={preset.days}
                      type="button"
                      onClick={() => setPremiumForm({ ...premiumForm, durationDays: preset.days })}
                      className={`px-3 py-2.5 rounded-xl border text-xs font-semibold text-left flex items-center justify-between transition-all ${
                        premiumForm.durationDays === preset.days
                          ? 'bg-blue-600 border-blue-500 text-white shadow-md shadow-blue-600/20'
                          : 'bg-slate-800/50 border-slate-700/80 text-slate-300 hover:border-slate-600'
                      }`}
                    >
                      <span>{preset.label}</span>
                      {premiumForm.durationDays === preset.days && <CheckCircle2 size={14} />}
                    </button>
                  ))}
                </div>

                {/* Khối xem trước ngày hết hạn mới */}
                <div className="p-3.5 rounded-xl bg-blue-950/30 border border-blue-800/50 text-xs text-blue-300 flex items-center justify-between">
                  <span>Thời điểm hết hạn dự tính:</span>
                  <span className="font-bold text-white font-mono">{calculateEstimatedExpiry()}</span>
                </div>
              </div>
            )}

            {/* Ghi chú lý do */}
            <div className="space-y-1">
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Ghi chú của Quản trị viên (Tùy chọn)</label>
              <input
                type="text"
                placeholder="Ví dụ: Kích hoạt tài khoản VIP thử nghiệm, chuyển khoản quầy..."
                value={premiumForm.reason}
                onChange={(e) => setPremiumForm({ ...premiumForm, reason: e.target.value })}
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-2.5 px-3.5 outline-none focus:ring-2 focus:ring-purple-500 text-sm"
              />
            </div>

            <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
              <button
                type="button"
                onClick={() => setPremiumTarget(null)}
                disabled={premiumLoading}
                className="px-4 py-2.5 rounded-xl bg-slate-800 text-slate-300 hover:bg-slate-700 text-sm font-semibold transition-colors"
              >
                Hủy bỏ
              </button>
              <button
                type="submit"
                disabled={premiumLoading}
                className="px-5 py-2.5 rounded-xl bg-purple-600 hover:bg-purple-500 text-white text-sm font-bold shadow-lg shadow-purple-600/20 transition-all flex items-center gap-2 disabled:opacity-50"
              >
                {premiumLoading && <Loader2 size={16} className="animate-spin" />}
                <span>Lưu thay đổi</span>
              </button>
            </div>
          </form>
        )}
      </Modal>
    </div>
  );
};

export default Users;
