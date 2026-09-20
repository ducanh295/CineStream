import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/useAuth';
import { Bot, UserCog, Save, RotateCcw, Loader2, Eye, EyeOff, CheckCircle2 } from 'lucide-react';
import aiApi from '../api/aiApi';
import ConfirmDialog from '../components/ConfirmDialog';

const InfoRow = ({ label, value }) => (
  <div className="flex items-center justify-between gap-4 py-3 border-b border-slate-800 last:border-b-0">
    <span className="text-slate-400 text-sm">{label}</span>
    <span className="text-white text-sm font-medium text-right">{value || '—'}</span>
  </div>
);

const Settings = () => {
  const { user } = useAuth();

  // Trạng thái cấu hình AI Gemini
  const [aiConfig, setAiConfig] = useState(null);
  const [loadingConfig, setLoadingConfig] = useState(true);
  const [apiKeyInput, setApiKeyInput] = useState('');
  const [modelInput, setModelInput] = useState('gemini-3.5-flash-lite');
  const [showKey, setShowKey] = useState(false);
  const [saving, setSaving] = useState(false);
  const [resetting, setResetting] = useState(false);
  const [confirmResetOpen, setConfirmResetOpen] = useState(false);
  const [notice, setNotice] = useState(null);

  const fetchAiConfig = useCallback(async () => {
    setLoadingConfig(true);
    try {
      const res = await aiApi.getConfig();
      const data = res?.data;
      if (data) {
        setAiConfig(data);
        setApiKeyInput(data.apiKey || '');
        setModelInput(data.model || 'gemini-3.5-flash-lite');
      }
    } catch (err) {
      setNotice({
        type: 'error',
        text: err.response?.data?.message || err.message || 'Không thể tải cấu hình AI.',
      });
    } finally {
      setLoadingConfig(false);
    }
  }, []);

  useEffect(() => {
    fetchAiConfig();
  }, [fetchAiConfig]);

  const handleSaveAiConfig = async (e) => {
    e.preventDefault();
    if (!apiKeyInput.trim()) {
      setNotice({ type: 'error', text: 'API Key không được để trống!' });
      return;
    }

    setSaving(true);
    setNotice(null);
    try {
      const res = await aiApi.updateConfig({
        apiKey: apiKeyInput.trim(),
        model: modelInput.trim() || 'gemini-3.5-flash-lite',
      });
      setAiConfig(res?.data);
      setNotice({ type: 'success', text: 'Lưu cấu hình Gemini API Key thành công!' });
      setShowKey(false);
    } catch (err) {
      setNotice({
        type: 'error',
        text: err.response?.data?.message || err.message || 'Lưu cấu hình AI thất bại.',
      });
    } finally {
      setSaving(false);
    }
  };

  const handleConfirmReset = async () => {
    setResetting(true);
    setNotice(null);
    try {
      await aiApi.deleteConfig();
      setNotice({
        type: 'success',
        text: 'Đã xóa cấu hình tùy chỉnh, khôi phục về API Key mặc định của hệ thống.',
      });
      setConfirmResetOpen(false);
      await fetchAiConfig();
    } catch (err) {
      setNotice({
        type: 'error',
        text: err.response?.data?.message || err.message || 'Khôi phục cấu hình thất bại.',
      });
      setConfirmResetOpen(false);
    } finally {
      setResetting(false);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-white">Cấu hình hệ thống</h1>
        <p className="text-slate-400 mt-1">Quản lý tài khoản quản trị và cấu hình khóa API cho Trợ lý AI CineBot.</p>
      </div>

      {notice && (
        <div
          className={`p-4 rounded-xl text-sm flex items-center gap-2 border ${
            notice.type === 'success'
              ? 'bg-emerald-500/10 border-emerald-500/20 text-emerald-400'
              : 'bg-red-500/10 border-red-500/20 text-red-400'
          }`}
        >
          {notice.type === 'success' ? <CheckCircle2 size={18} /> : null}
          <span>{notice.text}</span>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Khối 1: Thông tin tài khoản Admin */}
        <section className="bg-slate-900 border border-slate-800 rounded-2xl p-6 flex flex-col justify-between">
          <div>
            <div className="flex items-center gap-3 mb-4">
              <UserCog className="text-blue-400" size={22} />
              <h2 className="text-lg font-bold text-white">Tài khoản Quản trị</h2>
            </div>
            <InfoRow label="Tên đăng nhập" value={user?.username} />
            <InfoRow label="Email" value={user?.email} />
            <InfoRow label="Tên hiển thị" value={user?.profile?.displayName} />
            <InfoRow label="Vai trò hệ thống" value="Quản trị viên (Admin)" />
          </div>

          <div className="mt-6 p-4 rounded-xl bg-slate-800/40 border border-slate-800 text-xs text-slate-400 leading-5">
            Tài khoản này có đầy đủ đặc quyền quản trị kho phim, kiểm soát người dùng, đối soát giao dịch và cấu hình dịch vụ toàn hệ thống.
          </div>
        </section>

        {/* Khối 2: Cấu hình Gemini API Key cho Chatbot */}
        <section className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <div className="flex items-center justify-between gap-3 mb-4">
            <div className="flex items-center gap-3">
              <Bot className="text-indigo-400" size={22} />
              <h2 className="text-lg font-bold text-white">Cấu hình Trợ lý AI (Gemini)</h2>
            </div>
            {aiConfig && (
              <span
                className={`text-[10px] uppercase font-bold px-2.5 py-1 rounded-md border tracking-wider ${
                  aiConfig.isCustom
                    ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                    : 'bg-slate-800 text-slate-400 border-slate-700'
                }`}
              >
                {aiConfig.isCustom ? 'Tùy chỉnh (Database)' : 'Mặc định (AppSettings)'}
              </span>
            )}
          </div>

          {loadingConfig ? (
            <div className="py-12 flex flex-col items-center justify-center text-slate-500 gap-2">
              <Loader2 size={24} className="animate-spin text-indigo-500" />
              <span>Đang tải cấu hình AI...</span>
            </div>
          ) : (
            <form onSubmit={handleSaveAiConfig} className="space-y-4">
              {/* Google Gemini API Key */}
              <div>
                <label className="block text-xs font-semibold uppercase text-slate-400 mb-2">
                  Google Gemini API Key
                </label>
                <div className="relative">
                  <input
                    type={showKey ? 'text' : 'password'}
                    value={apiKeyInput}
                    onChange={(e) => setApiKeyInput(e.target.value)}
                    placeholder="Nhập API Key bắt đầu bằng AIzaSy..."
                    className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 pr-24 text-sm text-white focus:outline-none focus:border-indigo-500 font-mono transition-colors"
                  />
                  <div className="absolute right-2 top-1/2 -translate-y-1/2 flex items-center gap-1">
                    <button
                      type="button"
                      onClick={() => setShowKey(!showKey)}
                      title={showKey ? 'Ẩn khóa' : 'Hiện khóa'}
                      className="p-1.5 text-slate-400 hover:text-slate-200 transition-colors"
                    >
                      {showKey ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                </div>
                {aiConfig?.maskedApiKey && !showKey && (
                  <p className="text-[11px] text-slate-500 mt-1 font-mono">
                    Khóa đang kích hoạt: {aiConfig.maskedApiKey}
                  </p>
                )}
              </div>

              {/* Gemini Model */}
              <div>
                <label className="block text-xs font-semibold uppercase text-slate-400 mb-2">
                  Mô hình Gemini (Model)
                </label>
                <select
                  value={modelInput}
                  onChange={(e) => setModelInput(e.target.value)}
                  className="w-full bg-slate-800 border border-slate-700 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-indigo-500 transition-colors"
                >
                  <option value="gemini-3.5-flash-lite">gemini-3.5-flash-lite (Phản hồi cực nhanh - Mặc định)</option>
                  <option value="gemini-1.5-flash">gemini-1.5-flash (Cân bằng tốc độ và chất lượng)</option>
                  <option value="gemini-1.5-pro">gemini-1.5-pro (Suy luận sâu sắc, ngữ cảnh rộng)</option>
                </select>
              </div>

              {/* Endpoint thông tin */}
              <InfoRow label="Cổng dịch vụ (Base URL)" value={aiConfig?.baseUrl || 'https://generativelanguage.googleapis.com/v1beta'} />

              {/* Nhóm nút bấm thao tác */}
              <div className="pt-2 flex flex-col sm:flex-row gap-3">
                <button
                  type="submit"
                  disabled={saving}
                  className="flex-1 py-2.5 px-4 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-bold flex items-center justify-center gap-2 transition-colors disabled:opacity-50"
                >
                  {saving ? <Loader2 size={16} className="animate-spin" /> : <Save size={16} />}
                  <span>Lưu cấu hình</span>
                </button>

                {aiConfig?.isCustom && (
                  <button
                    type="button"
                    onClick={() => setConfirmResetOpen(true)}
                    disabled={resetting}
                    className="py-2.5 px-4 rounded-xl border border-slate-700 hover:bg-slate-800 text-slate-300 text-sm font-medium flex items-center justify-center gap-2 transition-colors disabled:opacity-50"
                  >
                    {resetting ? <Loader2 size={16} className="animate-spin" /> : <RotateCcw size={16} />}
                    <span>Đặt lại mặc định</span>
                  </button>
                )}
              </div>
            </form>
          )}
        </section>
      </div>

      <ConfirmDialog
        open={confirmResetOpen}
        title="Khôi phục cấu hình mặc định?"
        description="Khóa API Key tùy chỉnh trong cơ sở dữ liệu sẽ bị xóa. Hệ thống sẽ quay trở lại sử dụng khóa Gemini API được khai báo mặc định trong appsettings.json."
        confirmLabel="Khôi phục"
        loading={resetting}
        onConfirm={handleConfirmReset}
        onCancel={() => !resetting && setConfirmResetOpen(false)}
      />
    </div>
  );
};

export default Settings;
