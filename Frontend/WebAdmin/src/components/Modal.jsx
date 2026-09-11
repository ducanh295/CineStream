import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';

/**
 * Modal dùng chung cho toàn bộ Web Admin (form thêm/sửa Category, Movie, User...)
 * Props:
 *  - open: boolean, có hiển thị modal hay không
 *  - title: string, tiêu đề modal
 *  - onClose: () => void, gọi khi bấm nút X hoặc click ra ngoài
 *  - children: nội dung modal (thường là 1 <form>)
 *  - maxWidth: class Tailwind cho chiều rộng tối đa (mặc định 'max-w-lg')
 */
const Modal = ({ open, title, onClose, children, maxWidth = 'max-w-lg' }) => {
  return (
    <AnimatePresence>
      {open && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
          onClick={onClose}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 10 }}
            transition={{ duration: 0.2 }}
            onClick={(e) => e.stopPropagation()}
            className={`w-full ${maxWidth} bg-slate-900 border border-slate-800 rounded-2xl shadow-2xl max-h-[90vh] overflow-y-auto`}
          >
            <div className="flex items-center justify-between px-6 py-5 border-b border-slate-800 sticky top-0 bg-slate-900 z-10">
              <h3 className="text-lg font-bold text-white">{title}</h3>
              <button
                type="button"
                onClick={onClose}
                className="p-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
              >
                <X size={20} />
              </button>
            </div>
            <div className="p-6">{children}</div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default Modal;