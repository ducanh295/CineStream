 
import { useState, useEffect, useCallback } from 'react';
 
import { motion } from 'framer-motion';
 
import { ShieldCheck, Shield, Mail, Calendar, Search, Ban, CheckCircle2, Trash2, Loader2, RefreshCw, Crown, Clock } from 'lucide-react';
 
import userApi from '../api/userApi';
 
import ConfirmDialog from '../components/ConfirmDialog';
 
import Modal from '../components/Modal';

// Định nghĩa nhãn hiển thị cho các vai trò người dùng dựa trên giá trị số nguyên. 
const ROLE_LABEL = { 0: 'Người dùng', 1: 'Quản trị viên' };

// Hàm formatDate nhận vào một chuỗi ISO và trả về ngày tháng theo định dạng 'vi-VN' hoặc '—' nếu chuỗi rỗng. 
const formatDate = (isoString) => (isoString ? new Date(isoString).toLocaleDateString('vi-VN') : '—');

// hàm getPremiumStatus nhận vào một đối tượng user và trả về trạng thái Premium của người dùng đó, bao gồm nhãn hiển thị, màu sắc và trạng thái hoạt động. 
const getPremiumStatus = (user) => {
   
  if (!user.isPremium) {
     
    return { label: 'Gói thường', color: 'bg-slate-800 text-slate-400 border-slate-700', active: false };
  }
  // Nếu người dùng có Premium nhưng không có ngày hết hạn, trả về trạng thái VIP vĩnh viễn. 
  if (!user.premiumExpiresAt) {
     
    return { label: 'VIP Vĩnh viễn', color: 'bg-amber-500/20 text-amber-300 border-amber-500/40 shadow-sm shadow-amber-500/10', active: true };
  }
  // Nếu người dùng có Premium và có ngày hết hạn, kiểm tra xem ngày hết hạn đã qua hay chưa để xác định trạng thái VIP hết hạn hay còn hiệu lực. 
  const isExpired = new Date(user.premiumExpiresAt) <= new Date();
   
  if (isExpired) {
     
    return { label: 'VIP Hết hạn', color: 'bg-red-500/10 text-red-400 border-red-500/20', active: false };
  }
   
  return { label: 'VIP Premium', color: 'bg-amber-500/20 text-amber-300 border-amber-500/40 shadow-sm shadow-amber-500/10', active: true };
};

// Định nghĩa các tùy chọn thời gian cho gói Premium, bao gồm nhãn hiển thị và số ngày tương ứng. 
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

  // hàm fetchUsers được sử dụng để lấy danh sách người dùng từ API dựa trên các tham số tìm kiếm và phân trang, đồng thời cập nhật trạng thái giao diện người dùng. 
  const fetchUsers = useCallback(async () => {
     
    setLoading(true);
     
    setErrorMsg('');
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Gọi API để lấy danh sách người dùng với các tham số tìm kiếm và phân trang 
      const result = await userApi.getAllUsers({ search: search.trim() || undefined, page, pageSize: 12 });
      // khởi tạo biến paged để lưu trữ dữ liệu người dùng từ kết quả trả về, có thể là một mảng hoặc một đối tượng chứa các thuộc tính items, totalPages và totalCount.
      const paged = result?.data;
      // Cập nhật danh sách người dùng, tổng số trang và tổng số lượng người dùng dựa trên dữ liệu trả về từ API. Nếu dữ liệu trả về không hợp lệ, đặt danh sách người dùng thành mảng rỗng
      setUsers(Array.isArray(paged) ? paged : paged?.items || []);
      //đặt tổng số trang là 1 và tổng số lượng người dùng là 0.
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
    // Tạobộ hẹn giờ để trì hoãn việc gọi fetchUsers nhằm tránh việc gọi API quá nhiều lần khi người dùng nhập liệu tìm kiếm , 350 ms là thời gian chờ trước khi thực hiện tìm kiếm sau khi người dùng ngừng nhập liệu.
    const timer = setTimeout(fetchUsers, 350);
    // Khi component bị hủy hoặc search/page thay đổi, xóa bộ hẹn giờ để tránh rò rỉ bộ nhớ và gọi API không cần thiết. 
    return () => clearTimeout(timer);
  }, [fetchUsers]);

  // hàm handleSearch được sử dụng để cập nhật giá trị tìm kiếm và đặt lại trang hiện tại về 1 khi người dùng nhập liệu vào ô tìm kiếm. 
  const handleSearch = (event) => {
     
    setSearch(event.target.value);
     
    setPage(1);
  };

  // hàm handleToggleStatus được sử dụng để thay đổi trạng thái khóa/mở khóa của một người dùng cụ thể bằng cách gọi API và cập nhật danh sách người dùng sau khi thực hiện thành công. 
  const handleToggleStatus = async () => {
     
    if (!toggleTarget) return;
     
    setActionLoading(true);
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // nếu toggleTarget.isLocked là true, gọi API để mở khóa người dùng
      if (toggleTarget.isLocked) await userApi.unlockUser(toggleTarget.id);
      else {
         
        if (!lockReason.trim()) return;
        // Gọi API để khóa người dùng với lý do được cung cấp. 
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
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Gọi API để xóa người dùng dựa trên ID của deleteTarget. 
      await userApi.deleteUser(deleteTarget.id);
       
      setDeleteTarget(null);
      // nếu danh sách người dùng chỉ còn 1 người và trang hiện tại lớn hơn 1, giảm trang hiện tại đi 1 để tránh hiển thị trang trống sau khi xóa. 
      if (users.length === 1 && page > 1) setPage((current) => current - 1);
       
      else await fetchUsers();
    } catch (err) {
       
      setErrorMsg(err.message || 'Xóa tài khoản thất bại.');
    } finally {
       
      setActionLoading(false);
    }
  };

  // hàm openPremiumModal được sử dụng để mở Modal quản lý gói Premium cho một người dùng cụ thể
  const openPremiumModal = (user) => {
    // Cập nhật trạng thái premiumTarget với người dùng được chọn
    setPremiumTarget(user);
    // Cập nhật trạng thái premiumForm với các giá trị mặc định, bao gồm isPremium là true, durationDays là 30 và reason là chuỗi rỗng. 
    setPremiumForm({
      isPremium: true,
      durationDays: 30,
      reason: '',
    });
  };

  // hàm handleSavePremium được sử dụng để lưu thông tin gói Premium cho người dùng được chọn bằng cách gọi API và cập nhật danh sách người dùng sau khi thực hiện thành công. 
  const handleSavePremium = async (e) => {
     
    e.preventDefault();
     
    if (!premiumTarget) return;
     
    setPremiumLoading(true);
     
    setErrorMsg('');
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Gọi API để cập nhật thông tin gói Premium cho người dùng dựa trên ID của premiumTarget và các giá trị từ premiumForm. 
      await userApi.setPremium(premiumTarget.id, {
        isPremium: premiumForm.isPremium,
        // Nếu isPremium là true và durationDays là 0, đặt durationDays thành null để biểu thị gói Premium vĩnh viễn. Nếu isPremium là false, đặt durationDays thành null để biểu thị việc thu hồi gói Premium.
        durationDays: premiumForm.isPremium ? (premiumForm.durationDays === 0 ? null : premiumForm.durationDays) : null,
        // Nếu lý do được cung cấp là chuỗi rỗng, đặt reason thành undefined để biểu thị không có lý do cụ thể. Nếu có lý do, sử dụng giá trị đã cắt bỏ khoảng trắng.
        reason: premiumForm.reason.trim() || undefined,
      });

      // Cập nhật thông báo thành công dựa trên trạng thái isPremium của premiumForm và tên người dùng của premiumTarget. 
      setSuccessMsg(
        premiumForm.isPremium
          ? `Đã cập nhật gói Premium cho tài khoản "${premiumTarget.username}" thành công!`
          : `Đã thu hồi gói Premium của tài khoản "${premiumTarget.username}" thành công!`
      );
       
      setPremiumTarget(null);
       
      await fetchUsers();
      // Đặt bộ hẹn giờ để xóa thông báo thành công sau 4 giây. 
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
    // Lấy số ngày từ premiumForm, nếu không có giá trị, mặc định là 30 ngày. 
    const days = premiumForm.durationDays || 30;
     
    let baseDate = new Date();
    // Nếu người dùng đã có Premium và có ngày hết hạn
    if (premiumTarget?.isPremium && premiumTarget?.premiumExpiresAt) {
      // Chuyển đổi chuỗi ngày hết hạn hiện tại của người dùng thành đối tượng Date để so sánh với ngày hiện tại. 
      const existingDate = new Date(premiumTarget.premiumExpiresAt);
      // Nếu ngày hết hạn hiện tại của người dùng lớn hơn ngày hiện tại
      if (existingDate > baseDate) {
        // Cập nhật baseDate thành ngày hết hạn hiện tại của người dùng để tính toán ngày hết hạn dự kiến mới. 
        baseDate = existingDate;
      }
    }
    // Tính toán ngày hết hạn dự kiến bằng cách cộng số ngày từ premiumForm vào baseDate
    const targetDate = new Date(baseDate.getTime() + days * 24 * 60 * 60 * 1000);//(24 giờ * 60 phút * 60 giây * 1000 milliseconds).
     
    return targetDate.toLocaleDateString('vi-VN');
  };

   
  return (
    <div className="space-y-6">
       
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
         
        <div>
           
          <h1 className="text-3xl font-bold text-white">Quản lý người dùng</h1>
           
          <p className="text-slate-400 mt-1">{totalCount} tài khoản từ dữ liệu thật của hệ thống.</p>
        </div>
        {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
        <button type="button" disabled title="Backend chưa có API tạo tài khoản từ trang quản trị" className="bg-slate-800 text-slate-500 px-5 py-3 rounded-xl font-bold cursor-not-allowed">
          Thêm thành viên (chưa hỗ trợ)
        </button>
      </div>

       
      <div className="flex flex-col sm:flex-row gap-3">
         
        <div className="relative flex-1">
          {/* Hiển thị phần tử giao diện Search và nội dung con của nó. */}
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
          {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
          <input type="text" value={search} onChange={handleSearch} placeholder="Tìm email, tên đăng nhập hoặc tên hiển thị..." className="w-full bg-slate-900 border border-slate-800 text-white rounded-xl py-3 pl-10 pr-4 focus:ring-2 focus:ring-purple-500 outline-none transition-all" />
        </div>
        {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
        <button type="button" onClick={fetchUsers} disabled={loading} className="bg-slate-900 border border-slate-800 text-slate-300 px-4 py-3 rounded-xl flex items-center justify-center gap-2 hover:bg-slate-800 disabled:opacity-50">
          {/* Hiển thị phần tử giao diện RefreshCw và nội dung con của nó. */}
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
                    {/* Hiển thị phần tử giao diện h3 và nội dung con của nó. */}
                    <h3 className="text-white font-bold truncate">{user.profile?.displayName || user.username}</h3>
                    {pStatus.active && (
                      <span className="shrink-0 p-1 rounded-full bg-amber-500/10 text-amber-400 border border-amber-500/20" title="Thành viên VIP Premium">
                        {/* Hiển thị phần tử giao diện Crown và nội dung con của nó. */}
                        <Crown size={12} />
                      </span>
                    )}
                  </div>
                   
                  <div className="flex flex-col gap-1 mt-1 text-slate-500 text-sm">
                    {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                    <span className="flex items-center gap-1 truncate"><Mail size={14} className="shrink-0" /> {user.email}</span>
                    {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                    <span className="flex items-center gap-1"><Calendar size={14} /> Tạo ngày: {formatDate(user.createdAt)}</span>
                  </div>
                </div>
                 
                <div className="flex flex-col items-end gap-2 shrink-0">
                   
                  <div className="flex flex-col items-end gap-1">
                    {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                    <span className={`text-[10px] px-2 py-0.5 rounded-md font-bold border uppercase tracking-tighter ${user.role === 1 ? 'bg-purple-500/10 text-purple-400 border-purple-500/20' : 'bg-slate-800 text-slate-400 border-slate-700'}`}>{ROLE_LABEL[user.role] || 'Không xác định'}</span>
                    {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                    <span className={`text-[10px] px-2 py-0.5 rounded-md font-bold border tracking-tight flex items-center gap-1 ${pStatus.color}`}>
                      {pStatus.label}
                    </span>
                    {user.isPremium && user.premiumExpiresAt && (
                      <span className="text-[10px] text-slate-400 flex items-center gap-1 font-mono">
                        {/* Hiển thị phần tử giao diện Clock và nội dung con của nó. */}
                        <Clock size={10} /> {new Date(user.premiumExpiresAt).toLocaleDateString('vi-VN')}
                      </span>
                    )}
                  </div>
                   
                  <div className="flex items-center gap-1.5">
                    {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
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
                      {/* Hiển thị phần tử giao diện Crown và nội dung con của nó. */}
                      <Crown size={16} />
                    </button>
                    {/* Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan. */}
                    {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
                    <button type="button" onClick={() => { setLockReason('Vi phạm quy định sử dụng hệ thống'); setToggleTarget(user); }} title={user.isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản'} className={`p-1.5 rounded-lg transition-all ${user.isLocked ? 'hover:bg-green-500/10 hover:text-green-400 text-slate-500' : 'hover:bg-amber-500/10 hover:text-amber-400 text-slate-500'}`}>{user.isLocked ? <CheckCircle2 size={16} /> : <Ban size={16} />}</button>
                    {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
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

      {/* Hiển thị phần tử giao diện ConfirmDialog và nội dung con của nó. */}
      <ConfirmDialog open={Boolean(toggleTarget)} title={toggleTarget?.isLocked ? 'Mở khóa tài khoản?' : 'Khóa tài khoản?'} description={toggleTarget ? `Tài khoản "${toggleTarget.username}" sẽ ${toggleTarget.isLocked ? 'được phép đăng nhập trở lại' : 'không thể đăng nhập cho đến khi được mở khóa'}.` : ''} confirmLabel={toggleTarget?.isLocked ? 'Mở khóa' : 'Khóa tài khoản'} loading={actionLoading} onConfirm={handleToggleStatus} onCancel={() => setToggleTarget(null)} />
      {/* Hiển thị phần tử giao diện ConfirmDialog và nội dung con của nó. */}
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
                {/* Hiển thị phần tử giao diện Crown và nội dung con của nó. */}
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
              {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Trạng thái đặc quyền</label>
               
              <div className="grid grid-cols-2 gap-3">
                {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
                <button
                  type="button"
                  onClick={() => setPremiumForm({ ...premiumForm, isPremium: true })}
                  className={`p-3 rounded-xl border text-sm font-bold flex items-center justify-center gap-2 transition-all ${
                    premiumForm.isPremium
                      ? 'bg-amber-500/20 border-amber-500/50 text-amber-300 shadow-md shadow-amber-500/10'
                      : 'bg-slate-800/60 border-slate-700 text-slate-400 hover:text-white'
                  }`}
                >
                  {/* Hiển thị phần tử giao diện Crown và nội dung con của nó. */}
                  <Crown size={16} /> Bật / Gia hạn VIP
                </button>
                {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
                <button
                  type="button"
                  onClick={() => setPremiumForm({ ...premiumForm, isPremium: false })}
                  className={`p-3 rounded-xl border text-sm font-bold flex items-center justify-center gap-2 transition-all ${
                    !premiumForm.isPremium
                      ? 'bg-red-500/20 border-red-500/50 text-red-300 shadow-md shadow-red-500/10'
                      : 'bg-slate-800/60 border-slate-700 text-slate-400 hover:text-white'
                  }`}
                >
                  {/* Hiển thị phần tử giao diện Ban và nội dung con của nó. */}
                  <Ban size={16} /> Tắt / Thu hồi VIP
                </button>
              </div>
            </div>

            {/* Các tùy chọn thời hạn khi Bật Premium */}
            {premiumForm.isPremium && (
              <div className="space-y-3 pt-2">
                {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
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
                      {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                      <span>{preset.label}</span>
                      {premiumForm.durationDays === preset.days && <CheckCircle2 size={14} />}
                    </button>
                  ))}
                </div>

                {/* Khối xem trước ngày hết hạn mới */}
                <div className="p-3.5 rounded-xl bg-blue-950/30 border border-blue-800/50 text-xs text-blue-300 flex items-center justify-between">
                  {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                  <span>Thời điểm hết hạn dự tính:</span>
                  {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                  <span className="font-bold text-white font-mono">{calculateEstimatedExpiry()}</span>
                </div>
              </div>
            )}

            {/* Ghi chú lý do */}
            <div className="space-y-1">
              {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Ghi chú của Quản trị viên (Tùy chọn)</label>
              {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
              <input
                type="text"
                placeholder="Ví dụ: Kích hoạt tài khoản VIP thử nghiệm, chuyển khoản quầy..."
                value={premiumForm.reason}
                onChange={(e) => setPremiumForm({ ...premiumForm, reason: e.target.value })}
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-2.5 px-3.5 outline-none focus:ring-2 focus:ring-purple-500 text-sm"
              />
            </div>

             
            <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
              {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
              <button
                type="button"
                onClick={() => setPremiumTarget(null)}
                disabled={premiumLoading}
                className="px-4 py-2.5 rounded-xl bg-slate-800 text-slate-300 hover:bg-slate-700 text-sm font-semibold transition-colors"
              >
                Hủy bỏ
              </button>
              {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
              <button
                type="submit"
                disabled={premiumLoading}
                className="px-5 py-2.5 rounded-xl bg-purple-600 hover:bg-purple-500 text-white text-sm font-bold shadow-lg shadow-purple-600/20 transition-all flex items-center gap-2 disabled:opacity-50"
              >
                {premiumLoading && <Loader2 size={16} className="animate-spin" />}
                {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                <span>Lưu thay đổi</span>
              </button>
            </div>
          </form>
        )}
      </Modal>
    </div>
  );
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default Users;
