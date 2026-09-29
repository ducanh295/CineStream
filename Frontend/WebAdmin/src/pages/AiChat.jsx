 
import { useState, useEffect, useCallback, useRef } from 'react';
 
import { motion } from 'framer-motion';
 
import { Send, Bot, User, Trash2, Loader2, Sparkles, Film } from 'lucide-react';
 
import aiApi from '../api/aiApi';
 
import ConfirmDialog from '../components/ConfirmDialog';

 // Định nghĩa thành phần AiChat để quản lý giao diện và logic trò chuyện với AI.
const AiChat = () => {
   
  const [messages, setMessages] = useState([]); // { id, message, isFromAI, createdAt, recommendedMovies? }
   
  const [input, setInput] = useState('');
   
  const [loadingHistory, setLoadingHistory] = useState(true);
   
  const [sending, setSending] = useState(false);
   
  const [errorMsg, setErrorMsg] = useState('');
   
  const [clearing, setClearing] = useState(false);
   
  const [confirmClearOpen, setConfirmClearOpen] = useState(false);

   
  const bottomRef = useRef(null);

   // Định nghĩa hàm fetchHistory để lấy lịch sử trò chuyện từ API.
  const fetchHistory = useCallback(async () => {
     
    setLoadingHistory(true);
     
    setErrorMsg('');
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Gọi API để lấy lịch sử trò chuyện với giới hạn 30 tin nhắn gần nhất. 
      const result = await aiApi.getHistory(30);
      // dòng này kiểm tra xem dữ liệu trả về có phải là một mảng hay không, nếu không thì gán giá trị mặc định là một mảng rỗng. 
      const history = Array.isArray(result?.data) ? result.data : [];
      // Sắp xếp theo thời gian tăng dần để hiển thị đúng thứ tự hội thoại
      const sorted = [...history].sort(
        // So sánh hai tin nhắn dựa trên thuộc tính createdAt để sắp xếp theo thời gian tăng dần.
        (a, b) => new Date(a.createdAt) - new Date(b.createdAt)
      );
       
      setMessages(sorted);
    } catch (err) {
       
      setErrorMsg(err.message || 'Không thể tải lịch sử trò chuyện.');
    } finally {
       
      setLoadingHistory(false);
    }
  }, []);

  // Sử dụng useEffect để gọi fetchHistory khi thành phần được gắn vào DOM hoặc khi fetchHistory thay đổi. 
  useEffect(() => {
    // Sử dụng Promise.resolve().then() để đảm bảo fetchHistory được gọi sau khi tất cả các hiệu ứng hiện tại đã hoàn thành, tránh xung đột với các hiệu ứng khác. 
    Promise.resolve().then(() => {
       
      fetchHistory();
    });
  }, [fetchHistory]);

   
  useEffect(() => {
    // Cuộn xuống cuối khung hội thoại mỗi khi messages hoặc sending thay đổi, đảm bảo người dùng luôn thấy tin nhắn mới nhất. 
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, sending]);

  //logic gửi tin nhắn đến AI và xử lý phản hồi từ API. 
  const handleSend = async (e) => {
    // Ngăn chặn hành vi mặc định của sự kiện gửi form để tránh tải lại trang. 
    e.preventDefault();
    // Loại bỏ khoảng trắng ở đầu và cuối của tin nhắn nhập vào để kiểm tra xem có nội dung hay không.
    const text = input.trim();
    // nếu tin nhắn trống hoặc đang gửi tin nhắn, thì không thực hiện hành động gửi.
    if (!text || sending) return;

     
    setErrorMsg('');
    // Hiện tin nhắn của Admin ngay lập tức (optimistic UI)
    const tempUserMsg = {
      id: `temp-user-${Date.now()}`,
      message: text,
      isFromAI: false,
      createdAt: new Date().toISOString(),
    };
    // Cập nhật danh sách tin nhắn với tin nhắn mới của Admin, giữ nguyên các tin nhắn trước đó. 
    setMessages((prev) => [...prev, tempUserMsg]);
    // Xóa nội dung ô nhập tin nhắn và đặt trạng thái sending thành true để hiển thị trạng thái đang gửi. 
    setInput('');
    
    setSending(true);

    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Gọi API để gửi tin nhắn đến AI và nhận phản hồi. 
      const result = await aiApi.sendMessage(text);
       
      if (!result?.success || !result?.data) {
        // Phát sinh lỗi để thông báo trạng thái bất thường.
        throw new Error(result?.message || 'CineBot không phản hồi được. Vui lòng thử lại!');
      }
      // Giải cấu trúc dữ liệu phản hồi từ API, bao gồm reply (phản hồi của AI), recommendedMovies (danh sách phim gợi ý) và createdAt (thời gian tạo phản hồi). 
      const { reply, recommendedMovies, createdAt } = result.data;
      // Tạo một đối tượng tin nhắn từ AI với thông tin phản hồi và các thuộc tính liên quan. 
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

  // logic xóa lịch sử trò chuyện với AI và cập nhật giao diện người dùng. 
  const handleClearHistory = async () => {
     
    setClearing(true);
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
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
        {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
        <button
          onClick={() => setConfirmClearOpen(true)}
          disabled={messages.length === 0}
          className="bg-slate-800 text-red-400 px-5 py-2.5 rounded-xl border border-slate-700 flex items-center gap-2 hover:bg-red-500/10 hover:border-red-500/30 transition-all disabled:opacity-40 disabled:cursor-not-allowed"
        >
          {/* Hiển thị phần tử giao diện Trash2 và nội dung con của nó. */}
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
              {/* Hiển thị phần tử giao diện Sparkles và nội dung con của nó. */}
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
                  className={`w-9 h-9 rounded-full flex items-center justify-center shrink-0 ${
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
                           
                          <div className="w-8 h-10 bg-slate-700 rounded overflow-hidden shrink-0">
                            {movie.posterUrl ? (
                              <img src={movie.posterUrl} alt={movie.title} className="w-full h-full object-cover" />
                            ) : (
                              <Film size={14} className="text-slate-500 m-auto mt-2" />
                            )}
                          </div>
                          {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
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
               
              <div className="w-9 h-9 rounded-full bg-blue-600 flex items-center justify-center shrink-0">
                {/* Hiển thị phần tử giao diện Bot và nội dung con của nó. */}
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
          {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Nhập tin nhắn để trò chuyện với CineBot..."
            disabled={sending}
            className="flex-1 bg-slate-800 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all disabled:opacity-50"
          />
          {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
          <button
            type="submit"
            disabled={sending || !input.trim()}
            className="bg-blue-600 hover:bg-blue-700 text-white px-5 py-3 rounded-xl flex items-center gap-2 font-bold transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {sending ? <Loader2 className="animate-spin" size={20} /> : <Send size={20} />}
          </button>
        </form>
      </div>

      {/* Hiển thị phần tử giao diện ConfirmDialog và nội dung con của nó. */}
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

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default AiChat;