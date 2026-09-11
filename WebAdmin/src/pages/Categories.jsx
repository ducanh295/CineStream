import { useState, useEffect, useCallback } from 'react';
import { motion } from 'framer-motion';
import { Plus, Search, Edit2, Trash2, Tag, Loader2, RefreshCw } from 'lucide-react';
import categoryApi from '../api/categoryApi';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';

const EMPTY_FORM = { name: '', description: '' };

const Categories = () => {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');
  const [search, setSearch] = useState('');

  // Modal thêm/sửa
  const [modalOpen, setModalOpen] = useState(false);
  const [editingId, setEditingId] = useState(null); // null = đang tạo mới
  const [form, setForm] = useState(EMPTY_FORM);
  const [formErrors, setFormErrors] = useState({});
  const [saving, setSaving] = useState(false);

  // Dialog xác nhận xóa
  const [deleteTarget, setDeleteTarget] = useState(null); // category object hoặc null
  const [deleting, setDeleting] = useState(false);

  const fetchCategories = useCallback(async () => {
    setLoading(true);
    setErrorMsg('');
    try {
      const result = await categoryApi.getAll();
      setCategories(Array.isArray(result?.data) ? result.data : []);
    } catch (err) {
      setErrorMsg(err.message || 'Không thể tải danh sách thể loại. Vui lòng thử lại!');
    } finally {
      setLoading(false);
    }
  }, []);

    useEffect(() => {
    // Đẩy sang microtask để tránh cảnh báo "setState đồng bộ trong effect"
    Promise.resolve().then(() => {
      fetchCategories();
    });
  }, [fetchCategories]);

  const filteredCategories = categories.filter((c) =>
    c.name.toLowerCase().includes(search.trim().toLowerCase())
  );

  // ----- Mở modal thêm mới -----
  const openCreateModal = () => {
    setEditingId(null);
    setForm(EMPTY_FORM);
    setFormErrors({});
    setModalOpen(true);
  };

  // ----- Mở modal sửa -----
  const openEditModal = (category) => {
    setEditingId(category.id);
    setForm({ name: category.name, description: category.description || '' });
    setFormErrors({});
    setModalOpen(true);
  };

  const closeModal = () => {
    if (saving) return; // không cho đóng khi đang gửi request
    setModalOpen(false);
  };

  // ----- Validate cơ bản phía client trước khi gửi -----
  const validateForm = () => {
    const errors = {};
    if (!form.name.trim()) {
      errors.name = 'Tên thể loại không được để trống!';
    } else if (form.name.trim().length > 100) {
      errors.name = 'Tên thể loại tối đa 100 ký tự!';
    }
    if (form.description && form.description.length > 500) {
      errors.description = 'Mô tả tối đa 500 ký tự!';
    }
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  // ----- Submit form thêm/sửa -----
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    setSaving(true);
    try {
      const payload = {
        name: form.name.trim(),
        description: form.description.trim() || null,
      };

      if (editingId) {
        await categoryApi.update(editingId, payload);
      } else {
        await categoryApi.create(payload);
      }

      setModalOpen(false);
      await fetchCategories();
    } catch (err) {
      // Backend trả về { success:false, message, errors: [...] }
      if (err.errors && err.errors.length > 0) {
        setFormErrors({ general: err.errors.join(', ') });
      } else {
        setFormErrors({ general: err.message || 'Có lỗi xảy ra, vui lòng thử lại!' });
      }
    } finally {
      setSaving(false);
    }
  };

  // ----- Xóa -----
  const handleDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await categoryApi.delete(deleteTarget.id);
      setDeleteTarget(null);
      await fetchCategories();
    } catch (err) {
      setErrorMsg(err.message || 'Xóa thể loại thất bại!');
      setDeleteTarget(null);
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white">Quản lý thể loại</h1>
          <p className="text-slate-400 mt-1">Danh mục phân loại nội dung phim trên hệ thống.</p>
        </div>
        <motion.button
          whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}
          onClick={openCreateModal}
          className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-xl flex items-center gap-2 font-bold shadow-lg shadow-blue-600/30 transition-all"
        >
          <Plus size={20} /> Thêm thể loại
        </motion.button>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        {/* Thanh công cụ */}
        <div className="p-4 border-b border-slate-800 flex flex-col md:flex-row gap-4 bg-slate-900/50">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Tìm kiếm thể loại..."
              className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl py-2 pl-10 pr-4 focus:ring-2 focus:ring-blue-500 outline-none transition-all"
            />
          </div>
          <button
            onClick={fetchCategories}
            disabled={loading}
            className="bg-slate-800 text-slate-300 px-4 py-2 rounded-xl border border-slate-700 flex items-center gap-2 hover:bg-slate-700 disabled:opacity-50"
          >
            <RefreshCw size={18} className={loading ? 'animate-spin' : ''} /> Làm mới
          </button>
        </div>

        {/* Thông báo lỗi tải dữ liệu */}
        {errorMsg && (
          <div className="mx-4 mt-4 bg-red-500/10 border border-red-500/20 text-red-400 text-sm p-3 rounded-xl">
            {errorMsg}
          </div>
        )}

        {/* Trạng thái loading lần đầu */}
        {loading && categories.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-slate-500">
            <Loader2 className="animate-spin mb-3" size={32} />
            <p>Đang tải danh sách thể loại...</p>
          </div>
        ) : filteredCategories.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-slate-500">
            <Tag size={40} className="mb-3 opacity-50" />
            <p>{search ? 'Không tìm thấy thể loại phù hợp.' : 'Chưa có thể loại nào. Hãy thêm mới!'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead className="bg-slate-800/50 text-slate-400 uppercase text-xs font-bold tracking-wider">
                <tr>
                  <th className="px-6 py-4">Tên thể loại</th>
                  <th className="px-6 py-4">Mô tả</th>
                  <th className="px-6 py-4 text-center">Thao tác</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800 text-slate-300">
                {filteredCategories.map((category, index) => (
                  <motion.tr
                    initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: index * 0.03 }}
                    key={category.id} className="hover:bg-slate-800/30 transition-colors group"
                  >
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-lg bg-blue-500/10 flex items-center justify-center border border-blue-500/20">
                          <Tag size={16} className="text-blue-400" />
                        </div>
                        <span className="font-bold text-white">{category.name}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-400 max-w-md">
                      {category.description || <span className="italic text-slate-600">Không có mô tả</span>}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-center gap-2">
                        <button
                          onClick={() => openEditModal(category)}
                          className="p-2 hover:bg-blue-500/10 hover:text-blue-400 rounded-lg transition-all"
                        >
                          <Edit2 size={18} />
                        </button>
                        <button
                          onClick={() => setDeleteTarget(category)}
                          className="p-2 hover:bg-red-500/10 hover:text-red-400 rounded-lg transition-all"
                        >
                          <Trash2 size={18} />
                        </button>
                      </div>
                    </td>
                  </motion.tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modal Thêm/Sửa thể loại */}
      <Modal
        open={modalOpen}
        title={editingId ? 'Chỉnh sửa thể loại' : 'Thêm thể loại mới'}
        onClose={closeModal}
      >
        <form onSubmit={handleSubmit} className="space-y-5">
          {formErrors.general && (
            <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-sm p-3 rounded-xl">
              {formErrors.general}
            </div>
          )}

          <div className="space-y-1">
            <label className="text-slate-400 text-xs font-bold uppercase ml-1">Tên thể loại *</label>
            <input
              type="text"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              placeholder="Ví dụ: Hành Động"
              className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
            />
            {formErrors.name && <p className="text-red-400 text-xs ml-1">{formErrors.name}</p>}
          </div>

          <div className="space-y-1">
            <label className="text-slate-400 text-xs font-bold uppercase ml-1">Mô tả</label>
            <textarea
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              placeholder="Mô tả ngắn gọn về thể loại này..."
              rows={4}
              className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all resize-none"
            />
            {formErrors.description && <p className="text-red-400 text-xs ml-1">{formErrors.description}</p>}
          </div>

          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={closeModal}
              disabled={saving}
              className="flex-1 py-3 rounded-xl border border-slate-700 text-slate-300 font-medium hover:bg-slate-800 transition-colors disabled:opacity-50"
            >
              Hủy
            </button>
            <button
              type="submit"
              disabled={saving}
              className="flex-1 py-3 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {saving ? <Loader2 className="animate-spin" size={18} /> : editingId ? 'Lưu thay đổi' : 'Thêm mới'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Dialog xác nhận xóa */}
      <ConfirmDialog
        open={Boolean(deleteTarget)}
        title="Xóa thể loại?"
        description={deleteTarget ? `Bạn có chắc muốn xóa thể loại "${deleteTarget.name}"? Hành động này không thể hoàn tác.` : ''}
        confirmLabel="Xóa thể loại"
        loading={deleting}
        onConfirm={handleDelete}
        onCancel={() => !deleting && setDeleteTarget(null)}
      />
    </div>
  );
};

export default Categories;