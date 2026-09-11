import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  CreditCard,
  CheckCircle2,
  Clock,
  XCircle,
  AlertCircle,
  RefreshCw,
  Search,
  QrCode,
  ShieldCheck,
  Check,
  Copy,
  ExternalLink,
  Loader2,
  Sparkles,
} from 'lucide-react';
import paymentApi from '../api/paymentApi';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';

// Danh sach cac goi VIP CineStream mac dinh
const PLANS = [
  {
    id: '1M',
    name: 'Gói VIP 1 Tháng',
    price: 50000,
    days: 30,
    discount: null,
    highlight: false,
    description: 'Trải nghiệm không giới hạn phim chất lượng Full HD, không quảng cáo trong 30 ngày.',
  },
  {
    id: '3M',
    name: 'Gói VIP 3 Tháng',
    price: 135000,
    days: 90,
    discount: 'Tiết kiệm 10%',
    highlight: true,
    description: 'Lựa chọn phổ biến nhất. Xem phim mượt mà chuẩn 4K, hỗ trợ đa thiết bị trong 90 ngày.',
  },
  {
    id: '1Y',
    name: 'Gói VIP 1 Năm',
    price: 480000,
    days: 365,
    discount: 'Tiết kiệm 20%',
    highlight: false,
    description: 'Gói ưu đãi cao nhất cho tín đồ điện ảnh CineStream. Tiết kiệm tối đa chi phí hàng tháng.',
  },
];

// Cau hinh mau sac va nhan hien thi trang thai giao dich
const STATUS_CONFIG = {
  0: { label: 'Chờ thanh toán', bg: 'bg-amber-500/10', text: 'text-amber-400', border: 'border-amber-500/20' },
  1: { label: 'Thành công', bg: 'bg-emerald-500/10', text: 'text-emerald-400', border: 'border-emerald-500/20' },
  2: { label: 'Thất bại', bg: 'bg-red-500/10', text: 'text-red-400', border: 'border-red-500/20' },
  3: { label: 'Đã hủy', bg: 'bg-slate-500/10', text: 'text-slate-400', border: 'border-slate-500/20' },
  Pending: { label: 'Chờ thanh toán', bg: 'bg-amber-500/10', text: 'text-amber-400', border: 'border-amber-500/20' },
  Success: { label: 'Thành công', bg: 'bg-emerald-500/10', text: 'text-emerald-400', border: 'border-emerald-500/20' },
  Failed: { label: 'Thất bại', bg: 'bg-red-500/10', text: 'text-red-400', border: 'border-red-500/20' },
  Cancelled: { label: 'Đã hủy', bg: 'bg-slate-500/10', text: 'text-slate-400', border: 'border-slate-500/20' },
};

// Ham hien thi ten goi VIP tu so ngay su dung hoac ma goi
const getPlanBadge = (tx) => {
  if (tx.planType) return tx.planType;
  if (tx.planDurationDays === 30) return 'Gói 1 Tháng';
  if (tx.planDurationDays === 90) return 'Gói 3 Tháng';
  if (tx.planDurationDays === 365) return 'Gói 1 Năm';
  return `${tx.planDurationDays || 30} ngày`;
};

// Dinh dang tien te VND
const formatCurrency = (amount) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
};

// Dinh dang thoi gian theo chuan Viet Nam
const formatDate = (dateStr) => {
  if (!dateStr) return '—';
  const date = new Date(dateStr);
  return `${date.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })} ${date.toLocaleDateString('vi-VN')}`;
};

const Subscriptions = () => {
  const [transactions, setTransactions] = useState([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize] = useState(10);
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  // State phuc vu mo phong giao dich thanh cong
  const [simulateTarget, setSimulateTarget] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [actionNotice, setActionNotice] = useState(null);

  // State phuc vu modal hien thi VietQR
  const [qrModalData, setQrModalData] = useState(null);
  const [creatingPlan, setCreatingPlan] = useState(null);
  const [copiedField, setCopiedField] = useState('');
  const [pollingStatus, setPollingStatus] = useState(null);

  // Tai danh sach tat ca giao dich tu Backend
  const fetchTransactions = useCallback(async () => {
    setLoading(true);
    setErrorMsg('');
    try {
      const res = await paymentApi.getAdminAllTransactions({ page, pageSize });
      // Cau truc tra ve tu Controller: { success: true, data: items, total: totalCount, page, pageSize }
      const items = res?.data || [];
      setTransactions(Array.isArray(items) ? items : []);
      setTotalCount(res?.total || 0);
    } catch (err) {
      setErrorMsg(err.response?.data?.message || err.message || 'Không thể tải danh sách giao dịch.');
      setTransactions([]);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize]);

  useEffect(() => {
    fetchTransactions();
  }, [fetchTransactions]);

  // Xu ly sao chep noi dung vao clipboard
  const handleCopy = (text, fieldName) => {
    if (!text) return;
    navigator.clipboard.writeText(text);
    setCopiedField(fieldName);
    setTimeout(() => setCopiedField(''), 2000);
  };

  // Tao don thanh toan thu nghiem truc tiep tu WebAdmin
  const handleCreateTestPayment = async (planType) => {
    setCreatingPlan(planType);
    setActionNotice(null);
    try {
      const res = await paymentApi.createPayment({ planType });
      const data = res?.data;
      if (data) {
        setQrModalData({
          orderCode: data.orderCode,
          qrCodeUrl: data.qrCodeUrl,
          amount: data.amount,
          planType: data.planType,
          accountNo: data.accountNo || '0385941522',
          accountName: data.accountName || 'NGUYEN KHAC DUC ANH',
          bankName: data.bankName || 'MBBank',
        });
        setPollingStatus('Pending');
        fetchTransactions();
      }
    } catch (err) {
      const msg = err.response?.data?.message || err.message || 'Không thể khởi tạo đơn thanh toán.';
      setActionNotice({ type: 'error', text: msg });
    } finally {
      setCreatingPlan(null);
    }
  };

  // Kiem tra trang thai don hang khi dang xem VietQR
  const handleCheckQrStatus = async () => {
    if (!qrModalData?.orderCode) return;
    try {
      const res = await paymentApi.getPaymentStatus(qrModalData.orderCode);
      const statusData = res?.data;
      if (statusData) {
        setPollingStatus(statusData.status);
        if (statusData.isPaid) {
          setActionNotice({ type: 'success', text: `Đơn ${qrModalData.orderCode} đã thanh toán thành công!` });
          fetchTransactions();
        }
      }
    } catch (err) {
      console.error('Loi kiem tra trang thai don:', err);
    }
  };

  // Thuc hien mo phong thanh toan thanh cong
  const handleConfirmSimulate = async () => {
    if (!simulateTarget) return;
    setActionLoading(true);
    try {
      const res = await paymentApi.simulatePayment(simulateTarget.orderCode);
      setActionNotice({
        type: 'success',
        text: res?.message || `Mô phỏng thanh toán đơn ${simulateTarget.orderCode} thành công! VIP đã được kích hoạt.`,
      });
      setSimulateTarget(null);
      await fetchTransactions();

      // Neu modal QR dang mo trung don hang vua mo phong thi dong bo luon
      if (qrModalData?.orderCode === simulateTarget.orderCode) {
        setPollingStatus('Success');
      }
    } catch (err) {
      const msg = err.response?.data?.message || err.message || 'Mô phỏng thanh toán thất bại.';
      setActionNotice({ type: 'error', text: msg });
    } finally {
      setActionLoading(false);
    }
  };

  // Loc danh sach giao dich theo tim kiem va trang thai
  const filteredTransactions = transactions.filter((tx) => {
    const matchSearch =
      !search.trim() ||
      tx.orderCode?.toLowerCase().includes(search.toLowerCase()) ||
      tx.userEmail?.toLowerCase().includes(search.toLowerCase()) ||
      (tx.gatewayTransactionId && tx.gatewayTransactionId.toLowerCase().includes(search.toLowerCase())) ||
      (tx.transactionReference && tx.transactionReference.toLowerCase().includes(search.toLowerCase()));

    const txStatusStr = String(tx.status || '').toLowerCase();
    const filterStr = statusFilter.toLowerCase();
    const matchStatus =
      statusFilter === 'all' ||
      txStatusStr === filterStr ||
      (filterStr === 'pending' && (txStatusStr === '0' || txStatusStr === 'pending')) ||
      (filterStr === 'success' && (txStatusStr === '1' || txStatusStr === 'success')) ||
      (filterStr === 'failed' && (txStatusStr === '2' || txStatusStr === 'failed')) ||
      (filterStr === 'cancelled' && (txStatusStr === '3' || txStatusStr === 'cancelled'));

    return matchSearch && matchStatus;
  });

  const totalPages = Math.ceil(totalCount / pageSize) || 1;

  return (
    <div className="space-y-8">
      {/* Header trang */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white tracking-tight">Gói dịch vụ & Giao dịch thanh toán</h1>
          <p className="text-slate-400 mt-1">
            Quản lý bảng giá các gói VIP, lịch sử giao dịch nạp tiền VietQR SePay và kích hoạt mô phỏng bảo vệ đồ án.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={fetchTransactions}
            disabled={loading}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-sm font-medium border border-slate-700 transition-colors"
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>Làm mới</span>
          </button>
        </div>
      </div>

      {/* Thong bao trang thai thao tac */}
      <AnimatePresence>
        {actionNotice && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className={`p-4 rounded-xl border flex items-center justify-between ${
              actionNotice.type === 'success'
                ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-300'
                : 'bg-red-500/10 border-red-500/30 text-red-300'
            }`}
          >
            <div className="flex items-center gap-3">
              {actionNotice.type === 'success' ? <CheckCircle2 size={20} /> : <AlertCircle size={20} />}
              <span className="text-sm font-medium">{actionNotice.text}</span>
            </div>
            <button
              type="button"
              onClick={() => setActionNotice(null)}
              className="text-slate-400 hover:text-white transition-colors"
            >
              <XCircle size={18} />
            </button>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Thong tin cong thanh toan VietQR SePay */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-900 to-indigo-950/40 border border-slate-800 rounded-2xl p-6">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6">
          <div className="space-y-2 max-w-2xl">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-semibold uppercase tracking-wider">
              <ShieldCheck size={14} />
              <span>Cổng thanh toán tự động VietQR SePay</span>
            </div>
            <h3 className="text-xl font-bold text-white">Tài khoản nhận tiền hệ thống CineStream</h3>
            <p className="text-slate-400 text-sm leading-relaxed">
              Hệ thống tích hợp SePay Webhook tự động khớp mã đơn hàng trong nội dung chuyển khoản để nâng cấp gói VIP
              ngay lập tức trong vòng 3 đến 5 giây sau khi ngân hàng ghi có.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 bg-slate-800/60 border border-slate-700/60 rounded-xl p-4">
            <div>
              <span className="text-xs text-slate-400 block">Ngân hàng</span>
              <span className="text-sm font-bold text-white">MBBank (Quân Đội)</span>
            </div>
            <div>
              <span className="text-xs text-slate-400 block">Số tài khoản</span>
              <span className="text-sm font-bold text-amber-400 font-mono tracking-wider">0385941522</span>
            </div>
            <div>
              <span className="text-xs text-slate-400 block">Chủ tài khoản</span>
              <span className="text-sm font-bold text-white">NGUYEN KHAC DUC ANH</span>
            </div>
          </div>
        </div>
      </div>

      {/* Bang gia cac goi dich vu VIP */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-xl font-bold text-white">Các gói đăng ký VIP</h2>
            <p className="text-slate-400 text-sm">Bảng giá niêm yết áp dụng cho người dùng khi gia hạn tài khoản.</p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {PLANS.map((plan) => (
            <div
              key={plan.id}
              className={`relative bg-slate-900 rounded-2xl border p-6 flex flex-col justify-between transition-all ${
                plan.highlight
                  ? 'border-amber-500/50 shadow-xl shadow-amber-500/5 ring-1 ring-amber-500/20'
                  : 'border-slate-800 hover:border-slate-700'
              }`}
            >
              {plan.discount && (
                <div className="absolute -top-3 right-4 px-3 py-0.5 rounded-full bg-amber-500 text-slate-950 text-xs font-bold shadow-md">
                  {plan.discount}
                </div>
              )}

              <div>
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-bold text-white">{plan.name}</h3>
                  <span className="text-xs text-slate-400 bg-slate-800 px-2.5 py-1 rounded-lg">
                    {plan.days} ngày sử dụng
                  </span>
                </div>

                <div className="mt-4 mb-3">
                  <span className="text-3xl font-extrabold text-white">{formatCurrency(plan.price)}</span>
                </div>

                <p className="text-slate-400 text-xs leading-relaxed min-h-[36px]">{plan.description}</p>
              </div>

              <div className="mt-6 pt-4 border-t border-slate-800/80">
                <button
                  type="button"
                  onClick={() => handleCreateTestPayment(plan.id)}
                  disabled={creatingPlan === plan.id}
                  className={`w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-sm font-semibold transition-all ${
                    plan.highlight
                      ? 'bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold shadow-lg shadow-amber-500/10'
                      : 'bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700'
                  }`}
                >
                  {creatingPlan === plan.id ? (
                    <>
                      <Loader2 size={16} className="animate-spin" />
                      <span>Đang tạo VietQR...</span>
                    </>
                  ) : (
                    <>
                      <QrCode size={16} />
                      <span>Thử tạo đơn VietQR</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Bang quan ly lich su giao dich */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
        {/* Thanh tim kiem va bo loc */}
        <div className="p-5 border-b border-slate-800 flex flex-col sm:flex-row gap-4 items-center justify-between">
          <div className="relative w-full sm:w-80">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Tìm theo mã đơn, email..."
              className="w-full pl-10 pr-4 py-2 bg-slate-800/70 border border-slate-700 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:border-amber-500 transition-colors"
            />
          </div>

          <div className="flex items-center gap-3 w-full sm:w-auto">
            <span className="text-xs text-slate-400 whitespace-nowrap">Trạng thái:</span>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-3 py-2 bg-slate-800/70 border border-slate-700 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500 transition-colors"
            >
              <option value="all">Tất cả trạng thái</option>
              <option value="0">Chờ thanh toán (Pending)</option>
              <option value="1">Thành công (Success)</option>
              <option value="2">Thất bại (Failed)</option>
              <option value="3">Đã hủy (Cancelled)</option>
            </select>
          </div>
        </div>

        {/* Bang du lieu */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-800 bg-slate-950/40 text-xs uppercase font-semibold text-slate-400 tracking-wider">
                <th className="py-3.5 px-4">Mã đơn hàng</th>
                <th className="py-3.5 px-4">Người dùng</th>
                <th className="py-3.5 px-4">Gói VIP</th>
                <th className="py-3.5 px-4">Số tiền</th>
                <th className="py-3.5 px-4">Mã GD SePay</th>
                <th className="py-3.5 px-4">Trạng thái</th>
                <th className="py-3.5 px-4">Ngày tạo</th>
                <th className="py-3.5 px-4 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60 text-sm">
              {loading ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-400">
                    <div className="flex flex-col items-center justify-center gap-3">
                      <Loader2 size={28} className="animate-spin text-amber-500" />
                      <span>Đang tải danh sách giao dịch...</span>
                    </div>
                  </td>
                </tr>
              ) : filteredTransactions.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-400">
                    <CreditCard size={36} className="mx-auto text-slate-600 mb-3" />
                    <span>Không tìm thấy giao dịch nào phù hợp.</span>
                  </td>
                </tr>
              ) : (
                filteredTransactions.map((tx) => {
                  const statusInfo = STATUS_CONFIG[tx.status] || STATUS_CONFIG[0];
                  return (
                    <tr key={tx.id} className="hover:bg-slate-800/40 transition-colors">
                      {/* Ma don hang */}
                      <td className="py-3.5 px-4 font-mono font-medium text-amber-400">
                        <div className="flex items-center gap-1.5">
                          <span>{tx.orderCode}</span>
                          <button
                            type="button"
                            onClick={() => handleCopy(tx.orderCode, `code_${tx.id}`)}
                            title="Sao chép mã đơn"
                            className="text-slate-500 hover:text-slate-300"
                          >
                            {copiedField === `code_${tx.id}` ? <Check size={14} /> : <Copy size={14} />}
                          </button>
                        </div>
                      </td>

                      {/* Nguoi dung */}
                      <td className="py-3.5 px-4">
                        <span className="text-white font-medium block">{tx.userEmail || `User #${tx.userId}`}</span>
                      </td>

                      {/* Goi VIP */}
                      <td className="py-3.5 px-4">
                        <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-indigo-500/10 text-indigo-300 border border-indigo-500/20">
                          {getPlanBadge(tx)}
                        </span>
                      </td>

                      {/* So tien */}
                      <td className="py-3.5 px-4 font-semibold text-white">
                        {formatCurrency(tx.amount)}
                      </td>

                      {/* Ma GD SePay */}
                      <td className="py-3.5 px-4 font-mono text-xs text-slate-400">
                        {tx.gatewayTransactionId || tx.transactionReference || '—'}
                      </td>

                      {/* Trang thai */}
                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${statusInfo.bg} ${statusInfo.text} ${statusInfo.border}`}
                        >
                          {(tx.status === 1 || tx.status === 'Success') && <CheckCircle2 size={12} />}
                          {(tx.status === 0 || tx.status === 'Pending') && <Clock size={12} />}
                          {(tx.status === 2 || tx.status === 'Failed') && <XCircle size={12} />}
                          <span>{statusInfo.label}</span>
                        </span>
                      </td>

                      {/* Ngay tao */}
                      <td className="py-3.5 px-4 text-xs text-slate-400 whitespace-nowrap">
                        {formatDate(tx.createdAt)}
                      </td>

                      {/* Thao tac */}
                      <td className="py-3.5 px-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          {/* Nut xem QR Code */}
                          {tx.qrCodeUrl && (
                            <button
                              type="button"
                              onClick={() => {
                                setQrModalData({
                                  orderCode: tx.orderCode,
                                  qrCodeUrl: tx.qrCodeUrl,
                                  amount: tx.amount,
                                  planType: getPlanBadge(tx),
                                  accountNo: '0385941522',
                                  accountName: 'NGUYEN KHAC DUC ANH',
                                  bankName: 'MBBank',
                                });
                                setPollingStatus(tx.status === 1 || tx.status === 'Success' ? 'Success' : 'Pending');
                              }}
                              className="px-2.5 py-1 rounded-lg text-xs font-medium bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-700 transition-colors flex items-center gap-1"
                            >
                              <QrCode size={13} />
                              <span>Xem QR</span>
                            </button>
                          )}

                          {/* Nut mo phong thanh toan (neu dang pending) */}
                          {(tx.status === 0 || tx.status === 'Pending') && (
                            <button
                              type="button"
                              onClick={() => setSimulateTarget(tx)}
                              className="px-2.5 py-1 rounded-lg text-xs font-semibold bg-amber-500/10 hover:bg-amber-500/20 text-amber-300 border border-amber-500/30 transition-colors flex items-center gap-1"
                              title="Duyệt tiền giả lập để kích hoạt VIP phục vụ bảo vệ đồ án"
                            >
                              <Sparkles size={13} />
                              <span>Mô phỏng</span>
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Phan trang */}
        {totalPages > 1 && (
          <div className="p-4 border-t border-slate-800 flex items-center justify-between text-xs text-slate-400">
            <span>
              Hiển thị {filteredTransactions.length} trên tổng số {totalCount} giao dịch
            </span>
            <div className="flex gap-2">
              <button
                type="button"
                disabled={page <= 1}
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 disabled:opacity-50 disabled:cursor-not-allowed text-white transition-colors"
              >
                Trang trước
              </button>
              <span className="px-3 py-1.5 bg-slate-800/40 rounded-lg text-white font-medium">
                {page} / {totalPages}
              </span>
              <button
                type="button"
                disabled={page >= totalPages}
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 disabled:opacity-50 disabled:cursor-not-allowed text-white transition-colors"
              >
                Trang sau
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Modal hien thi thong tin thanh toan VietQR */}
      <Modal
        open={Boolean(qrModalData)}
        title={`Đơn thanh toán ${qrModalData?.orderCode || ''}`}
        onClose={() => setQrModalData(null)}
        maxWidth="max-w-md"
      >
        {qrModalData && (
          <div className="space-y-5 text-center">
            {/* Anh QR VietQR dong */}
            <div className="bg-white p-4 rounded-2xl inline-block shadow-lg mx-auto">
              <img
                src={qrModalData.qrCodeUrl}
                alt={`VietQR ${qrModalData.orderCode}`}
                className="w-56 h-56 object-contain rounded-lg"
              />
            </div>

            {/* Trang thai don trong Modal */}
            <div className="flex items-center justify-center gap-2">
              {pollingStatus === 'Success' ? (
                <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                  <CheckCircle2 size={14} />
                  <span>Đã thanh toán thành công</span>
                </span>
              ) : (
                <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/20">
                  <Clock size={14} />
                  <span>Chờ nhận tiền qua SePay Webhook</span>
                </span>
              )}
            </div>

            {/* Chi tiet chuyen khoan */}
            <div className="bg-slate-800/80 border border-slate-700/60 rounded-xl p-4 text-left space-y-2.5 text-xs">
              <div className="flex justify-between items-center">
                <span className="text-slate-400">Ngân hàng thụ hưởng:</span>
                <span className="text-white font-semibold">{qrModalData.bankName}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-slate-400">Số tài khoản:</span>
                <div className="flex items-center gap-1.5">
                  <span className="text-amber-400 font-mono font-bold">{qrModalData.accountNo}</span>
                  <button
                    type="button"
                    onClick={() => handleCopy(qrModalData.accountNo, 'accNo')}
                    className="text-slate-500 hover:text-slate-300"
                  >
                    {copiedField === 'accNo' ? <Check size={13} /> : <Copy size={13} />}
                  </button>
                </div>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-slate-400">Chủ tài khoản:</span>
                <span className="text-white font-semibold">{qrModalData.accountName}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-slate-400">Số tiền:</span>
                <span className="text-emerald-400 font-bold text-sm">{formatCurrency(qrModalData.amount)}</span>
              </div>
              <div className="flex justify-between items-center pt-2 border-t border-slate-700">
                <span className="text-slate-400 font-medium">Nội dung chuyển:</span>
                <div className="flex items-center gap-1.5">
                  <span className="text-white font-mono font-bold bg-slate-900 px-2 py-0.5 rounded border border-slate-700">
                    {qrModalData.orderCode}
                  </span>
                  <button
                    type="button"
                    onClick={() => handleCopy(qrModalData.orderCode, 'qrCode')}
                    className="text-slate-500 hover:text-slate-300"
                  >
                    {copiedField === 'qrCode' ? <Check size={13} /> : <Copy size={13} />}
                  </button>
                </div>
              </div>
            </div>

            {/* Nut hanh dong trong Modal */}
            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={handleCheckQrStatus}
                className="flex-1 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold border border-slate-700 transition-colors flex items-center justify-center gap-1.5"
              >
                <RefreshCw size={14} />
                <span>Kiểm tra trạng thái</span>
              </button>

              {pollingStatus !== 'Success' && (
                <button
                  type="button"
                  onClick={() => {
                    const tx = transactions.find((t) => t.orderCode === qrModalData.orderCode);
                    setSimulateTarget(tx || { orderCode: qrModalData.orderCode });
                  }}
                  className="flex-1 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-bold transition-colors flex items-center justify-center gap-1.5"
                >
                  <Sparkles size={14} />
                  <span>Mô phỏng thanh toán</span>
                </button>
              )}
            </div>
          </div>
        )}
      </Modal>

      {/* Hop thoai xac nhan mo phong thanh toan */}
      <ConfirmDialog
        open={Boolean(simulateTarget)}
        title="Xác nhận mô phỏng thanh toán"
        description={`Bạn có chắc muốn mô phỏng nhận tiền thành công cho đơn hàng ${simulateTarget?.orderCode}? Hệ thống sẽ kích hoạt trạng thái VIP cho tài khoản mà không cần chờ biến động số dư thực tế từ ngân hàng.`}
        confirmLabel="Mô phỏng ngay"
        loading={actionLoading}
        onConfirm={handleConfirmSimulate}
        onCancel={() => setSimulateTarget(null)}
      />
    </div>
  );
};

export default Subscriptions;
