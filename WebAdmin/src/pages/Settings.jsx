import { useState } from 'react';
import { motion } from 'framer-motion';
import { Save, Globe, Bot, UserCog, Bell, Loader2, CheckCircle2 } from 'lucide-react';
import { useAuth } from '../context/useAuth';

// ⚠️ DỮ LIỆU MẪU (MOCK) mẫu tạm thời cho cấu hình hệ thống khi có API thật.
const TABS = [
  { id: 'general', label: 'Chung', icon: Globe },
  { id: 'ai', label: 'AI Chatbot', icon: Bot },
  { id: 'account', label: 'Tài khoản', icon: UserCog },
  { id: 'notifications', label: 'Thông báo', icon: Bell },
];

const SectionCard = ({ title, description, children }) => (
  <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
    <h3 className="text-lg font-bold text-white">{title}</h3>
    {description && <p className="text-slate-500 text-sm mt-1">{description}</p>}
    <div className="mt-5 space-y-4">{children}</div>
  </div>
);

const FieldRow = ({ label, hint, children }) => (
  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 py-3 border-b border-slate-800 last:border-b-0">
    <div>
      <p className="text-slate-300 text-sm font-medium">{label}</p>
      {hint && <p className="text-slate-500 text-xs mt-0.5">{hint}</p>}
    </div>
    <div className="shrink-0">{children}</div>
  </div>
);

const ToggleSwitch = ({ checked, onChange }) => (
  <button
    type="button"
    onClick={() => onChange(!checked)}
    className={`w-12 h-7 rounded-full transition-colors relative shrink-0 ${checked ? 'bg-blue-600' : 'bg-slate-700'}`}
  >
    <span
      className={`absolute top-1 w-5 h-5 rounded-full bg-white transition-transform ${
        checked ? 'translate-x-6' : 'translate-x-1'
      }`}
    />
  </button>
);

const inputClass =
  'bg-slate-800/50 border border-slate-700 text-white rounded-xl py-2.5 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all w-full sm:w-72';

const Settings = () => {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState('general');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  // Cấu hình chung
  const [siteName, setSiteName] = useState('CineStream');
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [allowRegister, setAllowRegister] = useState(true);

  // Cấu hình AI Chatbot
  const [aiEnabled, setAiEnabled] = useState(true);
  const [aiModel, setAiModel] = useState('gemini-3.5-flash-lite');
  const [aiHistoryLimit, setAiHistoryLimit] = useState(30);

  // Thông báo
  const [emailNotify, setEmailNotify] = useState(true);
  const [newUserNotify, setNewUserNotify] = useState(true);

  // TODO(API thật): thay bằng gọi systemApi.updateSettings(payload) khi Backend có endpoint
  const handleSave = async (e) => {
    e.preventDefault();
    setSaving(true);
    setSaved(false);
    // Giả lập độ trễ gọi API
    await new Promise((resolve) => setTimeout(resolve, 600));
    setSaving(false);
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  };

  return (
    <div className="space-y-6">
      <div className="bg-amber-500/10 border border-amber-500/20 text-amber-400 text-sm px-4 py-2.5 rounded-xl">
        ⚠️ trang đang hiển thị dữ liệu mẫu
      </div>

      <div>
        <h1 className="text-3xl font-bold text-white">Cấu hình hệ thống</h1>
        <p className="text-slate-400 mt-1">Quản lý các thiết lập chung của nền tảng CineStream.</p>
      </div>

      <div className="flex flex-col lg:flex-row gap-6">
        {/* Tab menu */}
        <div className="lg:w-64 shrink-0">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-2 flex lg:flex-col gap-1 overflow-x-auto">
            {TABS.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all text-sm font-medium whitespace-nowrap ${
                  activeTab === tab.id
                    ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/30'
                    : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <tab.icon size={18} /> {tab.label}
              </button>
            ))}
          </div>
        </div>

        {/* Nội dung tab */}
        <form onSubmit={handleSave} className="flex-1 space-y-6">
          {activeTab === 'general' && (
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
              <SectionCard title="Thông tin chung" description="Cấu hình cơ bản của nền tảng.">
                <FieldRow label="Tên hệ thống" hint="Hiển thị ở tiêu đề trang và email gửi đi">
                  <input type="text" value={siteName} onChange={(e) => setSiteName(e.target.value)} className={inputClass} />
                </FieldRow>
                <FieldRow label="Chế độ bảo trì" hint="Tạm ngừng truy cập từ người dùng khi bật">
                  <ToggleSwitch checked={maintenanceMode} onChange={setMaintenanceMode} />
                </FieldRow>
                <FieldRow label="Cho phép đăng ký mới" hint="Người dùng mới có thể tự tạo tài khoản">
                  <ToggleSwitch checked={allowRegister} onChange={setAllowRegister} />
                </FieldRow>
              </SectionCard>
            </motion.div>
          )}

          {activeTab === 'ai' && (
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
              <SectionCard title="Trợ lý AI CineBot" description="Cấu hình trợ lý AI tư vấn phim cho người dùng.">
                <FieldRow label="Kích hoạt CineBot" hint="Bật/tắt tính năng trò chuyện AI trên toàn hệ thống">
                  <ToggleSwitch checked={aiEnabled} onChange={setAiEnabled} />
                </FieldRow>
                <FieldRow label="Model AI" hint="Model Gemini đang sử dụng để xử lý hội thoại">
                  <select value={aiModel} onChange={(e) => setAiModel(e.target.value)} className={inputClass}>
                    <option value="gemini-3.5-flash-lite">gemini-3.5-flash-lite</option>
                    <option value="gemini-3.5-flash">gemini-3.5-flash</option>
                    <option value="gemini-3.5-pro">gemini-3.5-pro</option>
                  </select>
                </FieldRow>
                <FieldRow label="Giới hạn lịch sử" hint="Số tin nhắn gần nhất được lưu để trả lời có ngữ cảnh">
                  <input
                    type="number"
                    value={aiHistoryLimit}
                    onChange={(e) => setAiHistoryLimit(e.target.value)}
                    className={inputClass}
                  />
                </FieldRow>
              </SectionCard>
            </motion.div>
          )}

          {activeTab === 'account' && (
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
              <SectionCard title="Thông tin tài khoản" description="Thông tin tài khoản quản trị viên đang đăng nhập.">
                <FieldRow label="Tên đăng nhập">
                  <span className="text-white text-sm font-medium">{user?.username || '—'}</span>
                </FieldRow>
                <FieldRow label="Email">
                  <span className="text-white text-sm font-medium">{user?.email || '—'}</span>
                </FieldRow>
                <FieldRow label="Tên hiển thị">
                  <span className="text-white text-sm font-medium">{user?.profile?.displayName || '—'}</span>
                </FieldRow>
                <FieldRow label="Vai trò">
                  <span className="px-3 py-1 rounded-full text-xs font-bold bg-purple-500/10 text-purple-400 border border-purple-500/20">
                    Quản trị viên
                  </span>
                </FieldRow>
              </SectionCard>
            </motion.div>
          )}

          {activeTab === 'notifications' && (
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
              <SectionCard title="Thông báo" description="Tùy chỉnh cách hệ thống gửi thông báo cho quản trị viên.">
                <FieldRow label="Thông báo qua Email" hint="Nhận email khi có sự kiện quan trọng">
                  <ToggleSwitch checked={emailNotify} onChange={setEmailNotify} />
                </FieldRow>
                <FieldRow label="Thông báo người dùng mới" hint="Nhận thông báo khi có tài khoản mới đăng ký">
                  <ToggleSwitch checked={newUserNotify} onChange={setNewUserNotify} />
                </FieldRow>
              </SectionCard>
            </motion.div>
          )}

          <div className="flex items-center gap-4">
            <button
              type="submit"
              disabled={saving}
              className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-xl flex items-center gap-2 font-bold shadow-lg shadow-blue-600/30 transition-all disabled:opacity-50"
            >
              {saving ? <Loader2 className="animate-spin" size={20} /> : <Save size={20} />}
              Lưu thay đổi
            </button>

            {saved && (
              <motion.span
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                className="text-green-400 text-sm font-medium flex items-center gap-1.5"
              >
                <CheckCircle2 size={16} /> Đã lưu thành công
              </motion.span>
            )}
          </div>
        </form>
      </div>
    </div>
  );
};

export default Settings;