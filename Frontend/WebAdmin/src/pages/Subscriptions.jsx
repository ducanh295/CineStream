import { CreditCard, ServerCrash } from 'lucide-react';

const Subscriptions = () => (
  <div className="space-y-6">
    <div>
      <h1 className="text-3xl font-bold text-white">Gói dịch vụ & Thanh toán</h1>
      <p className="text-slate-400 mt-1">Quản lý các gói đăng ký và lịch sử giao dịch của người dùng.</p>
    </div>

    <div className="bg-slate-900 border border-amber-500/20 rounded-2xl p-8 max-w-2xl">
      <div className="w-12 h-12 rounded-xl bg-amber-500/10 flex items-center justify-center mb-5">
        <ServerCrash className="text-amber-400" size={24} />
      </div>
      <h2 className="text-xl font-bold text-white">Backend chưa cung cấp chức năng thanh toán</h2>
      <p className="text-slate-400 mt-3 leading-6">
        Hiện Backend chưa có SubscriptionsController hoặc PaymentsController, nên WebAdmin không thể tải, tạo, sửa hoặc xóa gói dịch vụ và giao dịch.
      </p>
      <div className="mt-5 flex items-center gap-3 text-sm text-slate-500">
        <CreditCard size={18} />
        <span>Trang sẽ tự hoạt động sau khi Backend có API tương ứng.</span>
      </div>
    </div>
  </div>
);

export default Subscriptions;
