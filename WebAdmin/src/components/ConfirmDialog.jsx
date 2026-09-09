import { motion, AnimatePresence } from 'framer-motion';
import { AlertTriangle, Loader2 } from 'lucide-react';

/**
 * Hộp thoại xác nhận hành động nguy hiểm (xóa, khóa tài khoản...)
 * Props:
 *  - open: boolean
 *  - title: string
 *  - description: string
 *  - confirmLabel: string (mặc định 'Xóa')
 *  - loading: boolean, hiển thị spinner trên nút xác nhận khi đang xử lý
 *  - onConfirm: () => void
 *  - onCancel: () => void
 */
const ConfirmDialog = ({
  open,
  title = 'Xác nhận hành động',
  description,
  confirmLabel = 'Xóa',
  loading = false,
  onConfirm,
  onCancel,
}) => {
  return (
    <AnimatePresence>
      {open && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-[110] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
          onClick={onCancel}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            onClick={(e) => e.stopPropagation()}
            className="w-full max-w-sm bg-slate-900 border border-slate-800 rounded-2xl shadow-2xl p-6"
          >
            <div className="w-12 h-12 rounded-full bg-red-500/10 flex items-center justify-center mb-4">
              <AlertTriangle className="text-red-400" size={24} />
            </div>
            <h3 className="text-lg font-bold text-white">{title}</h3>
            {description && <p className="text-slate-400 text-sm mt-2">{description}</p>}

            <div className="flex gap-3 mt-6">
              <button
                type="button"
                onClick={onCancel}
                disabled={loading}
                className="flex-1 py-2.5 rounded-xl border border-slate-700 text-slate-300 font-medium hover:bg-slate-800 transition-colors disabled:opacity-50"
              >
                Hủy
              </button>
              <button
                type="button"
                onClick={onConfirm}
                disabled={loading}
                className="flex-1 py-2.5 rounded-xl bg-red-600 hover:bg-red-700 text-white font-bold transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
              >
                {loading ? <Loader2 className="animate-spin" size={18} /> : confirmLabel}
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default ConfirmDialog;