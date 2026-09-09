import { useState, useEffect, useCallback, useRef } from 'react';
import { motion } from 'framer-motion';
import { Send, Bot, User, Trash2, Loader2, Sparkles, Film } from 'lucide-react';
import aiApi from '../api/aiApi';
import ConfirmDialog from '../components/ConfirmDialog';

const AiChat = () => {
  const [messages, setMessages] = useState([]); // { id, message, isFromAI, createdAt, recommendedMovies? }
  const [input, setInput] = useState('');
  const [loadingHistory, setLoadingHistory] = useState(true);
  const [sending, setSending] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [clearing, setClearing] = useState(false);
  const [confirmClearOpen, setConfirmClearOpen] = useState(false);

  const bottomRef = useRef(null);

  const fetchHistory = useCallback(async () => {
    setLoadingHistory(true);
    setErrorMsg('');
    try {
      const result = await aiApi.getHistory(30);
      const history = result?.data || [];
      // Sắp xếp theo thời gian tăng dần để hiển thị đúng thứ tự hội thoại
      const sorted = [...history].sort(
        (a, b) => new Date(a.createdAt) - new Date(b.createdAt)
      );
      setMessages(sorted);
    } catch (err) {
      setErrorMsg(err.message || 'Không thể tải lịch sử trò chuyện.');
    } finally {
      setLoadingHistory(false);
    }
  }, []);

  useEffect(() => {
    Promise.resolve().then(() => {
      fetchHistory();
    });
  }, [fetchHistory]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, sending]);

  const handleSend = async (e) => {
    e.preventDefault();
    const text = input.trim();
    if (!text || sending) return;

    setErrorMsg('');
    // Hiện tin nhắn của Admin ngay lập tức (optimistic UI)
    const tempUserMsg = {
      id: `temp-user-${Date.now()}`,
      message: text,
      isFromAI: false,
      createdAt: new Date().toISOString(),
    };
    setMessages((prev) => [...prev, tempUserMsg]);
    setInput('');
    setSending(true);

    try {
      const result = await aiApi.sendMessage(text);
      if (!result?.success || !result?.data) {
        throw new Error(result?.message || 'CineBot không phản hồi được. Vui lòng thử lại!');
      }
      const { reply, recommendedMovies, createdAt } = result.data;
      const aiMsg = {
        id: `temp-ai-${Date.now()}`,
        message: reply,
        isFromAI: true,
        createdAt: createdAt || new Date().toISOString(),
        recommendedMovies: recommendedMovies || [],
      };
      setMessages((prev) => [...prev, aiMsg]);
    } catch (err) {
      setErrorMsg(err.message || 'Có lỗi xảy ra khi gửi tin nhắn!');
    } finally {
      setSending(false);
    }
  };

  const handleClearHistory = async () => {
    setClearing(true);
    try {
      await aiApi.clearHistory();
      setMessages([]);
      setConfirmClearOpen(false);
    } catch (err) {
      setErrorMsg(err.message || 'Xóa lịch sử thất bại!');
      setConfirmClearOpen(false);
    } finally {
      setClearing(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white">Trợ lý AI CineBot</h1>
          <p className="text-slate-400 mt-1">Kiểm thử trợ lý AI tư vấn và gợi ý phim cho người dùng.</p>
        </div>
        <button
          onClick={() => setConfirmClearOpen(true)}
          disabled={messages.length === 0}
          className="bg-slate-800 text-red-400 px-5 py-2.5 rounded-xl border border-slate-700 flex items-center gap-2 hover:bg-red-500/10 hover:border-red-500/30 transition-all disabled:opacity-40 disabled:cursor-not-allowed"
        >
          <Trash2 size={18} /> Xóa lịch sử
        </button>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl shadow-xl flex flex-col h-[65vh]">
        {/* Khung hội thoại */}
        <div className="flex-1 overflow-y-auto p-6 space-y-5">
          {errorMsg && (
            <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-sm p-3 rounded-xl">
              {errorMsg}
            </div>
          )}

          {loadingHistory ? (
            <div className="flex flex-col items-center justify-center h-full text-slate-500">
              <Loader2 className="animate-spin mb-3" size={32} />
              <p>Đang tải lịch sử trò chuyện...</p>
            </div>
          ) : messages.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-full text-slate-500">
              <Sparkles size={40} className="mb-3 opacity-50" />
              <p>Chưa có hội thoại nào. Hãy thử hỏi CineBot điều gì đó!</p>
              <p className="text-xs mt-1 text-slate-600">Ví dụ: "Gợi ý cho tôi phim hành động hay"</p>
            </div>
          ) : (
            messages.map((msg) => (
              <motion.div
                key={msg.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className={`flex gap-3 ${msg.isFromAI ? 'flex-row' : 'flex-row-reverse'}`}
              >
                <div
                  className={`w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0 ${
                    msg.isFromAI ? 'bg-blue-600' : 'bg-slate-700'
                  }`}
                >
                  {msg.isFromAI ? <Bot size={18} className="text-white" /> : <User size={18} className="text-white" />}
                </div>

                <div className={`max-w-[75%] ${msg.isFromAI ? '' : 'flex flex-col items-end'}`}>
                  <div
                    className={`px-4 py-3 rounded-2xl text-sm whitespace-pre-wrap ${
                      msg.isFromAI
                        ? 'bg-slate-800 text-slate-200 rounded-tl-sm'
                        : 'bg-blue-600 text-white rounded-tr-sm'
                    }`}
                  >
                    {msg.message}
                  </div>

                  {/* Danh sách phim gợi ý (nếu có) */}
                  {msg.isFromAI && msg.recommendedMovies && msg.recommendedMovies.length > 0 && (
                    <div className="mt-2 flex flex-wrap gap-2">
                      {msg.recommendedMovies.map((movie) => (
                        <div
                          key={movie.id}
                          className="flex items-center gap-2 bg-slate-800/70 border border-slate-700 rounded-xl px-3 py-2"
                        >
                          <div className="w-8 h-10 bg-slate-700 rounded overflow-hidden flex-shrink-0">
                            {movie.posterUrl ? (
                              <img src={movie.posterUrl} alt={movie.title} className="w-full h-full object-cover" />
                            ) : (
                              <Film size={14} className="text-slate-500 m-auto mt-2" />
                            )}
                          </div>
                          <span className="text-xs text-slate-300 font-medium">{movie.title}</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </motion.div>
            ))
          )}

          {sending && (
            <div className="flex gap-3">
              <div className="w-9 h-9 rounded-full bg-blue-600 flex items-center justify-center flex-shrink-0">
                <Bot size={18} className="text-white" />
              </div>
              <div className="px-4 py-3 rounded-2xl bg-slate-800 text-slate-400 rounded-tl-sm flex items-center gap-2">
                <Loader2 className="animate-spin" size={16} /> CineBot đang trả lời...
              </div>
            </div>
          )}

          <div ref={bottomRef} />
        </div>

        {/* Ô nhập tin nhắn */}
        <form onSubmit={handleSend} className="border-t border-slate-800 p-4 flex gap-3">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Nhập tin nhắn để trò chuyện với CineBot..."
            disabled={sending}
            className="flex-1 bg-slate-800 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all disabled:opacity-50"
          />
          <button
            type="submit"
            disabled={sending || !input.trim()}
            className="bg-blue-600 hover:bg-blue-700 text-white px-5 py-3 rounded-xl flex items-center gap-2 font-bold transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {sending ? <Loader2 className="animate-spin" size={20} /> : <Send size={20} />}
          </button>
        </form>
      </div>

      <ConfirmDialog
        open={confirmClearOpen}
        title="Xóa toàn bộ lịch sử trò chuyện?"
        description="Toàn bộ hội thoại với CineBot của tài khoản này sẽ bị xóa vĩnh viễn. Hành động này không thể hoàn tác."
        confirmLabel="Xóa lịch sử"
        loading={clearing}
        onConfirm={handleClearHistory}
        onCancel={() => !clearing && setConfirmClearOpen(false)}
      />
    </div>
  );
};

export default AiChat;