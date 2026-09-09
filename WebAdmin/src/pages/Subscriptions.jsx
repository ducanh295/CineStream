import { useState } from 'react';
import { motion } from 'framer-motion';
import { CreditCard, Plus, Edit2, Trash2, DollarSign, Users2, Package } from 'lucide-react';
import ConfirmDialog from '../components/ConfirmDialog';

// ⚠️ DỮ LIỆU MẪU (MOCK) tạm thời cho Model/Controller của Gói dịch vụ & Thanh toán.
// Cấu trúc dưới là dữ liệu mẫu cho đến khi thiết kế API thật.
const MOCK_PLANS = [
  { id: 1, name: 'Gói Cơ Bản', price: 59000, durationDays: 30, maxDevices: 1, quality: 'HD 720p', subscriberCount: 5200, color: 'blue' },
  { id: 2, name: 'Gói Tiêu Chuẩn', price: 99000, durationDays: 30, maxDevices: 2, quality: 'Full HD 1080p', subscriberCount: 8300, color: 'purple' },
  { id: 3, name: 'Gói Cao Cấp', price: 149000, durationDays: 30, maxDevices: 4, quality: '4K Ultra HD', subscriberCount: 3400, color: 'orange' },
];

const MOCK_TRANSACTIONS = [
  { id: 1, username: 'minhanh92', planName: 'Gói Tiêu Chuẩn', amount: 99000, status: 'success', createdAt: '2024-09-01T10:30:00Z' },
  { id: 2, username: 'user', planName: 'Gói Cơ Bản', amount: 59000, status: 'success', createdAt: '2024-09-03T14:15:00Z' },
  { id: 3, username: 'khanhly88', planName: 'Gói Cao Cấp', amount: 149000, status: 'pending', createdAt: '2024-09-05T09:00:00Z' },
  { id: 4, username: 'ducanh01', planName: 'Gói Tiêu Chuẩn', amount: 99000, status: 'failed', createdAt: '2024-09-06T16:45:00Z' },
];

const STATUS_CONFIG = {
  success: { label: 'Thành công', className: 'bg-green-500/10 text-green-400 border-green-500/20' },
  pending: { label: 'Đang xử lý', className: 'bg-amber-500/10 text-amber-400 border-amber-500/20' },
  failed: { label: 'Thất bại', className: 'bg-red-500/10 text-red-400 border-red-500/20' },
};

const COLOR_MAP = {
  blue: { bg: 'bg-blue-500/10', border: 'border-blue-500/20', text: 'text-blue-400', badge: 'bg-blue-600' },
  purple: { bg: 'bg-purple-500/10', border: 'border-purple-500/20', text: 'text-purple-400', badge: 'bg-purple-600' },
  orange: { bg: 'bg-orange-500/10', border: 'border-orange-500/20', text: 'text-orange-400', badge: 'bg-orange-600' },
};

const formatCurrency = (amount) => `${amount.toLocaleString('vi-VN')}đ`;
const formatDate = (isoString) => new Date(isoString).toLocaleString('vi-VN');

const Subscriptions = () => {
  const [plans, setPlans] = useState(MOCK_PLANS);
  const [transactions] = useState(MOCK_TRANSACTIONS);
  const [deleteTarget, setDeleteTarget] = useState(null);

  const totalRevenue = transactions
    .filter((t) => t.status === 'success')
    .reduce((sum, t) => sum + t.amount, 0);
  const totalSubscribers = plans.reduce((sum, p) => sum + p.subscriberCount, 0);

  // TODO(API thật): thay bằng gọi paymentApi.deletePlan(id) khi Backend có endpoint
  const handleDelete = () => {
    if (!deleteTarget) return;
    setPlans((prev) => prev.filter((p) => p.id !== deleteTarget.id));
    setDeleteTarget(null);
  };

  return (
    <div className="space-y-8">
      <div className="bg-amber-500/10 border border-amber-500/20 text-amber-400 text-sm px-4 py-2.5 rounded-xl">
        ⚠️ Trang đang hiển thị dữ liệu mẫu.
      </div>

      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white">Gói dịch vụ & Thanh toán</h1>
          <p className="text-slate-400 mt-1">Quản lý các gói đăng ký và lịch sử giao dịch của người dùng.</p>
        </div>
        <motion.button
          whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}
          className="bg-green-600 hover:bg-green-700 text-white px-6 py-3 rounded-xl flex items-center gap-2 font-bold shadow-lg shadow-green-600/30 transition-all"
        >
          <Plus size={20} /> Thêm gói dịch vụ
        </motion.button>
      </div>

      {/* Thống kê nhanh */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
          <div className="flex items-center gap-4">
            <div className="p-4 rounded-xl bg-green-500/10">
              <DollarSign className="text-green-400" size={28} />
            </div>
            <div>
              <p className="text-slate-400 text-sm font-medium">Tổng doanh thu</p>
              <h3 className="text-2xl font-bold text-white mt-1">{formatCurrency(totalRevenue)}</h3>
            </div>
          </div>
        </div>
        <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
          <div className="flex items-center gap-4">
            <div className="p-4 rounded-xl bg-blue-500/10">
              <Users2 className="text-blue-400" size={28} />
            </div>
            <div>
              <p className="text-slate-400 text-sm font-medium">Tổng người đăng ký</p>
              <h3 className="text-2xl font-bold text-white mt-1">{totalSubscribers.toLocaleString('vi-VN')}</h3>
            </div>
          </div>
        </div>
        <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
          <div className="flex items-center gap-4">
            <div className="p-4 rounded-xl bg-purple-500/10">
              <Package className="text-purple-400" size={28} />
            </div>
            <div>
              <p className="text-slate-400 text-sm font-medium">Số gói đang bán</p>
              <h3 className="text-2xl font-bold text-white mt-1">{plans.length}</h3>
            </div>
          </div>
        </div>
      </div>

      {/* Danh sách các gói dịch vụ */}
      <div>
        <h2 className="text-xl font-bold text-white mb-4">Các gói dịch vụ</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {plans.map((plan, i) => {
            const colors = COLOR_MAP[plan.color] || COLOR_MAP.blue;
            return (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.1 }}
                key={plan.id}
                className={`bg-slate-900 border ${colors.border} rounded-2xl p-6 relative overflow-hidden group hover:scale-[1.02] transition-transform`}
              >
                <div className={`absolute top-0 right-0 w-32 h-32 blur-3xl opacity-20 rounded-full -mr-10 -mt-10 ${colors.badge}`}></div>

                <div className="relative z-10">
                  <div className="flex items-center justify-between mb-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-bold ${colors.bg} ${colors.text} border ${colors.border}`}>
                      {plan.quality}
                    </span>
                    <div className="flex items-center gap-1">
                      <button className="p-1.5 hover:bg-slate-800 rounded-lg text-slate-500 hover:text-blue-400 transition-all">
                        <Edit2 size={15} />
                      </button>
                      <button
                        onClick={() => setDeleteTarget(plan)}
                        className="p-1.5 hover:bg-slate-800 rounded-lg text-slate-500 hover:text-red-400 transition-all"
                      >
                        <Trash2 size={15} />
                      </button>
                    </div>
                  </div>

                  <h3 className="text-lg font-bold text-white">{plan.name}</h3>
                  <div className="mt-2 flex items-baseline gap-1">
                    <span className="text-3xl font-extrabold text-white">{formatCurrency(plan.price)}</span>
                    <span className="text-slate-500 text-sm">/{plan.durationDays} ngày</span>
                  </div>

                  <div className="mt-4 space-y-2 text-sm text-slate-400">
                    <p>• Tối đa {plan.maxDevices} thiết bị cùng lúc</p>
                    <p>• Chất lượng {plan.quality}</p>
                  </div>

                  <div className="mt-5 pt-4 border-t border-slate-800 flex items-center justify-between">
                    <span className="text-slate-500 text-xs">Người đăng ký</span>
                    <span className="text-white font-bold text-sm">{plan.subscriberCount.toLocaleString('vi-VN')}</span>
                  </div>
                </div>
              </motion.div>
            );
          })}
        </div>
      </div>

      {/* Lịch sử giao dịch */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        <div className="p-6 border-b border-slate-800 flex items-center gap-3">
          <CreditCard className="text-slate-400" size={20} />
          <h2 className="text-xl font-bold text-white">Lịch sử giao dịch gần đây</h2>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead className="bg-slate-800/50 text-slate-400 uppercase text-xs font-bold tracking-wider">
              <tr>
                <th className="px-6 py-4">Người dùng</th>
                <th className="px-6 py-4">Gói dịch vụ</th>
                <th className="px-6 py-4">Số tiền</th>
                <th className="px-6 py-4">Thời gian</th>
                <th className="px-6 py-4">Trạng thái</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800 text-slate-300">
              {transactions.map((tx, index) => {
                const statusCfg = STATUS_CONFIG[tx.status] || STATUS_CONFIG.pending;
                return (
                  <motion.tr
                    initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: index * 0.03 }}
                    key={tx.id} className="hover:bg-slate-800/30 transition-colors"
                  >
                    <td className="px-6 py-4 font-medium text-white">{tx.username}</td>
                    <td className="px-6 py-4 text-sm">{tx.planName}</td>
                    <td className="px-6 py-4 text-sm font-bold text-green-400">{formatCurrency(tx.amount)}</td>
                    <td className="px-6 py-4 text-sm text-slate-400">{formatDate(tx.createdAt)}</td>
                    <td className="px-6 py-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-bold border ${statusCfg.className}`}>
                        {statusCfg.label}
                      </span>
                    </td>
                  </motion.tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      <ConfirmDialog
        open={Boolean(deleteTarget)}
        title="Xóa gói dịch vụ?"
        description={deleteTarget ? `Bạn có chắc muốn xóa gói "${deleteTarget.name}"? Người dùng đang sử dụng gói này sẽ bị ảnh hưởng.` : ''}
        confirmLabel="Xóa gói"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  );
};

export default Subscriptions;