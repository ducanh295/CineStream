import { useAuth } from '../context/useAuth';
import { Bot, Globe, ServerCrash, UserCog } from 'lucide-react';

const InfoRow = ({ label, value }) => (
  <div className="flex items-center justify-between gap-4 py-3 border-b border-slate-800 last:border-b-0">
    <span className="text-slate-400 text-sm">{label}</span>
    <span className="text-white text-sm font-medium text-right">{value || '—'}</span>
  </div>
);

const Settings = () => {
  const { user } = useAuth();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-white">Cấu hình hệ thống</h1>
        <p className="text-slate-400 mt-1">Thông tin quản trị và trạng thái các nhóm cấu hình.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <section className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <div className="flex items-center gap-3 mb-4"><UserCog className="text-blue-400" size={22} /><h2 className="text-lg font-bold text-white">Tài khoản hiện tại</h2></div>
          <InfoRow label="Tên đăng nhập" value={user?.username} />
          <InfoRow label="Email" value={user?.email} />
          <InfoRow label="Tên hiển thị" value={user?.profile?.displayName} />
          <InfoRow label="Vai trò" value="Quản trị viên" />
        </section>

        <section className="bg-slate-900 border border-amber-500/20 rounded-2xl p-6">
          <div className="flex items-center gap-3 mb-4"><ServerCrash className="text-amber-400" size={22} /><h2 className="text-lg font-bold text-white">Cấu hình hệ thống</h2></div>
          <p className="text-slate-400 text-sm leading-6">Backend hiện chưa có endpoint đọc hoặc cập nhật cấu hình hệ thống. Các thay đổi về bảo trì, đăng ký, thông báo và cấu hình AI chưa thể lưu từ WebAdmin.</p>
          <div className="mt-5 space-y-3 text-sm text-slate-500"><div className="flex items-center gap-2"><Globe size={16} /> Cấu hình chung: chưa hỗ trợ</div><div className="flex items-center gap-2"><Bot size={16} /> Cấu hình AI: dùng cấu hình Backend hiện tại</div></div>
        </section>
      </div>
    </div>
  );
};

export default Settings;
