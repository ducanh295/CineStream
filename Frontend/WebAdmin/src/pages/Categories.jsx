// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { useState, useEffect, useCallback } from 'react';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { motion } from 'framer-motion';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { Plus, Search, Edit2, Trash2, Tag, Loader2, RefreshCw } from 'lucide-react';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import categoryApi from '../api/categoryApi';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import Modal from '../components/Modal';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import ConfirmDialog from '../components/ConfirmDialog';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const EMPTY_FORM = { name: '', description: '' };

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const Categories = () => {
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [categories, setCategories] = useState([]);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [loading, setLoading] = useState(true);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [errorMsg, setErrorMsg] = useState('');
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [search, setSearch] = useState('');

  // Modal thêm/sửa
  const [modalOpen, setModalOpen] = useState(false);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [editingId, setEditingId] = useState(null); // null = đang tạo mới
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [form, setForm] = useState(EMPTY_FORM);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [formErrors, setFormErrors] = useState({});
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [saving, setSaving] = useState(false);

  // Dialog xác nhận xóa
  const [deleteTarget, setDeleteTarget] = useState(null); // category object hoặc null
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [deleting, setDeleting] = useState(false);

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const fetchCategories = useCallback(async () => {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setLoading(true);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setErrorMsg('');
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const result = await categoryApi.getAll();
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setCategories(Array.isArray(result?.data) ? result.data : []);
    } catch (err) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setErrorMsg(err.message || 'Không thể tải danh sách thể loại. Vui lòng thử lại!');
    } finally {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setLoading(false);
    }
  }, []);

    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    useEffect(() => {
    // Đẩy sang microtask để tránh cảnh báo "setState đồng bộ trong effect"
    Promise.resolve().then(() => {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      fetchCategories();
    });
  }, [fetchCategories]);

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const filteredCategories = categories.filter((c) =>
    c.name.toLowerCase().includes(search.trim().toLowerCase())
  );

  // ----- Mở modal thêm mới -----
  const openCreateModal = () => {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setEditingId(null);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setForm(EMPTY_FORM);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setFormErrors({});
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setModalOpen(true);
  };

  // ----- Mở modal sửa -----
  const openEditModal = (category) => {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setEditingId(category.id);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setForm({ name: category.name, description: category.description || '' });
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setFormErrors({});
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setModalOpen(true);
  };

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const closeModal = () => {
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (saving) return; // không cho đóng khi đang gửi request
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setModalOpen(false);
  };

  // ----- Validate cơ bản phía client trước khi gửi -----
  const validateForm = () => {
    // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
    const errors = {};
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (!form.name.trim()) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      errors.name = 'Tên thể loại không được để trống!';
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    } else if (form.name.trim().length > 100) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      errors.name = 'Tên thể loại tối đa 100 ký tự!';
    }
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (form.description && form.description.length > 500) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      errors.description = 'Mô tả tối đa 500 ký tự!';
    }
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setFormErrors(errors);
    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
    return Object.keys(errors).length === 0;
  };

  // ----- Submit form thêm/sửa -----
  const handleSubmit = async (e) => {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    e.preventDefault();
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (!validateForm()) return;

    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setSaving(true);
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const payload = {
        name: form.name.trim(),
        description: form.description.trim() || null,
      };

      // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
      if (editingId) {
        // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
        await categoryApi.update(editingId, payload);
      } else {
        // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
        await categoryApi.create(payload);
      }

      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setModalOpen(false);
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      await fetchCategories();
    } catch (err) {
      // Backend trả về { success:false, message, errors: [...] }
      if (err.errors && err.errors.length > 0) {
        // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
        setFormErrors({ general: err.errors.join(', ') });
      } else {
        // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
        setFormErrors({ general: err.message || 'Có lỗi xảy ra, vui lòng thử lại!' });
      }
    } finally {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setSaving(false);
    }
  };

  // ----- Xóa -----
  const handleDelete = async () => {
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (!deleteTarget) return;
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setDeleting(true);
    setErrorMsg('');
    try {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      await categoryApi.delete(deleteTarget.id);
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setDeleteTarget(null);
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      await fetchCategories();
    } catch (err) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setErrorMsg(err.message || 'Xóa thể loại thất bại!');
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setDeleteTarget(null);
    } finally {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setDeleting(false);
    }
  };

  // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
  return (
    <div className="space-y-6">
      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
        <div>
          {/* Hiển thị phần tử giao diện h1 và nội dung con của nó. */}
          <h1 className="text-3xl font-bold text-white">Quản lý thể loại</h1>
          {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
          <p className="text-slate-400 mt-1">Danh mục phân loại nội dung phim trên hệ thống.</p>
        </div>
        {/* Hiển thị phần tử giao diện giao diện và nội dung con của nó. */}
        <motion.button
          whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}
          onClick={openCreateModal}
          className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-xl flex items-center gap-2 font-bold shadow-lg shadow-blue-600/30 transition-all"
        >
          {/* Hiển thị phần tử giao diện Plus và nội dung con của nó. */}
          <Plus size={20} /> Thêm thể loại
        </motion.button>
      </div>

      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        {/* Thanh công cụ */}
        <div className="p-4 border-b border-slate-800 flex flex-col md:flex-row gap-4 bg-slate-900/50">
          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="relative flex-1">
            {/* Hiển thị phần tử giao diện Search và nội dung con của nó. */}
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
            {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Tìm kiếm thể loại..."
              className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl py-2 pl-10 pr-4 focus:ring-2 focus:ring-blue-500 outline-none transition-all"
            />
          </div>
          {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
          <button
            onClick={fetchCategories}
            disabled={loading}
            className="bg-slate-800 text-slate-300 px-4 py-2 rounded-xl border border-slate-700 flex items-center gap-2 hover:bg-slate-700 disabled:opacity-50"
          >
            {/* Hiển thị phần tử giao diện RefreshCw và nội dung con của nó. */}
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
            {/* Hiển thị phần tử giao diện Loader2 và nội dung con của nó. */}
            <Loader2 className="animate-spin mb-3" size={32} />
            {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
            <p>Đang tải danh sách thể loại...</p>
          </div>
        ) : filteredCategories.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-slate-500">
            {/* Hiển thị phần tử giao diện Tag và nội dung con của nó. */}
            <Tag size={40} className="mb-3 opacity-50" />
            {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
            <p>{search ? 'Không tìm thấy thể loại phù hợp.' : 'Chưa có thể loại nào. Hãy thêm mới!'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            {/* Hiển thị phần tử giao diện table và nội dung con của nó. */}
            <table className="w-full text-left border-collapse">
              {/* Hiển thị phần tử giao diện thead và nội dung con của nó. */}
              <thead className="bg-slate-800/50 text-slate-400 uppercase text-xs font-bold tracking-wider">
                {/* Hiển thị phần tử giao diện tr và nội dung con của nó. */}
                <tr>
                  {/* Hiển thị phần tử giao diện th và nội dung con của nó. */}
                  <th className="px-6 py-4">Tên thể loại</th>
                  {/* Hiển thị phần tử giao diện th và nội dung con của nó. */}
                  <th className="px-6 py-4">Mô tả</th>
                  <th className="px-6 py-4 text-center">Số lượng phim</th>
                  <th className="px-6 py-4 text-center">Thao tác</th>
                </tr>
              </thead>
              {/* Hiển thị phần tử giao diện tbody và nội dung con của nó. */}
              <tbody className="divide-y divide-slate-800 text-slate-300">
                {filteredCategories.map((category, index) => (
                  <motion.tr
                    initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: index * 0.03 }}
                    key={category.id} className="hover:bg-slate-800/30 transition-colors group"
                  >
                    {/* Hiển thị phần tử giao diện td và nội dung con của nó. */}
                    <td className="px-6 py-4">
                      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
                      <div className="flex items-center gap-3">
                        {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
                        <div className="w-9 h-9 rounded-lg bg-blue-500/10 flex items-center justify-center border border-blue-500/20">
                          {/* Hiển thị phần tử giao diện Tag và nội dung con của nó. */}
                          <Tag size={16} className="text-blue-400" />
                        </div>
                        {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                        <span className="font-bold text-white">{category.name}</span>
                      </div>
                    </td>
                    {/* Hiển thị phần tử giao diện td và nội dung con của nó. */}
                    <td className="px-6 py-4 text-sm text-slate-400 max-w-md">
                      {category.description || <span className="italic text-slate-600">Không có mô tả</span>}
                    </td>
                    <td className="px-6 py-4 text-center">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${
                        (category.movieCount || 0) > 0
                          ? 'bg-blue-500/10 text-blue-400 border border-blue-500/20'
                          : 'bg-slate-800 text-slate-500'
                      }`}>
                        {category.movieCount || 0} phim
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
                      <div className="flex items-center justify-center gap-2">
                        {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
                        <button
                          onClick={() => openEditModal(category)}
                          className="p-2 hover:bg-blue-500/10 hover:text-blue-400 rounded-lg transition-all"
                        >
                          {/* Hiển thị phần tử giao diện Edit2 và nội dung con của nó. */}
                          <Edit2 size={18} />
                        </button>
                        {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
                        <button
                          onClick={() => setDeleteTarget(category)}
                          className="p-2 hover:bg-red-500/10 hover:text-red-400 rounded-lg transition-all"
                        >
                          {/* Hiển thị phần tử giao diện Trash2 và nội dung con của nó. */}
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
        {/* Hiển thị phần tử giao diện form và nội dung con của nó. */}
        <form onSubmit={handleSubmit} className="space-y-5">
          {formErrors.general && (
            <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-sm p-3 rounded-xl">
              {formErrors.general}
            </div>
          )}

          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="space-y-1">
            {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
            <label className="text-slate-400 text-xs font-bold uppercase ml-1">Tên thể loại *</label>
            {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
            <input
              type="text"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              placeholder="Ví dụ: Hành Động"
              className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
            />
            {formErrors.name && <p className="text-red-400 text-xs ml-1">{formErrors.name}</p>}
          </div>

          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="space-y-1">
            {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
            <label className="text-slate-400 text-xs font-bold uppercase ml-1">Mô tả</label>
            {/* Hiển thị phần tử giao diện textarea và nội dung con của nó. */}
            <textarea
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              placeholder="Mô tả ngắn gọn về thể loại này..."
              rows={4}
              className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all resize-none"
            />
            {formErrors.description && <p className="text-red-400 text-xs ml-1">{formErrors.description}</p>}
          </div>

          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="flex gap-3 pt-2">
            {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
            <button
              type="button"
              onClick={closeModal}
              disabled={saving}
              className="flex-1 py-3 rounded-xl border border-slate-700 text-slate-300 font-medium hover:bg-slate-800 transition-colors disabled:opacity-50"
            >
              Hủy
            </button>
            {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
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
        description={
          deleteTarget
            ? (deleteTarget.movieCount || 0) > 0
              ? `Cảnh báo: Thể loại "${deleteTarget.name}" đang có ${deleteTarget.movieCount} bộ phim liên kết. Hệ thống sẽ chặn xóa để bảo đảm toàn vẹn dữ liệu.`
              : `Bạn có chắc muốn xóa thể loại "${deleteTarget.name}"? Hành động này có thể hoàn tác bởi Quản trị viên.`
            : ''
        }
        confirmLabel="Xóa thể loại"
        loading={deleting}
        onConfirm={handleDelete}
        onCancel={() => !deleting && setDeleteTarget(null)}
      />
    </div>
  );
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default Categories;