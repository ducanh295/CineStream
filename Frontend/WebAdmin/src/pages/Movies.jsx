import { useState, useEffect, useCallback } from 'react';
import { motion } from 'framer-motion';
import { Plus, Search, Edit2, Trash2, PlayCircle, Loader2, Film, X, Layers } from 'lucide-react';
import { Link } from 'react-router-dom';
import movieApi from '../api/movieApi';
import categoryApi from '../api/categoryApi';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';

const EMPTY_FORM = {
  title: '',
  description: '',
  posterUrl: '',
  videoUrl: '',
  trailerUrl: '',
  duration: '',
  releaseYear: '',
  type: 0, // MovieType.Single = 0, Series = 1
  videoStatus: 1,
  categoryIds: [],
};

// MovieType: Single = 0, Series = 1 (khớp enum bên Backend)
const MOVIE_TYPE_LABEL = { 0: 'Phim lẻ', 1: 'Phim bộ' };

const Movies = () => {
  const [movies, setMovies] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');
  const [search, setSearch] = useState('');

  const [modalOpen, setModalOpen] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [formErrors, setFormErrors] = useState({});
  const [saving, setSaving] = useState(false);

  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleting, setDeleting] = useState(false);

  // Danh sách luồng phát có sẵn từ kho HLS nội bộ
  const [availableStreams, setAvailableStreams] = useState({ internalStreams: [], cdnPresets: [] });
  const [showHlsPicker, setShowHlsPicker] = useState(false);

  const fetchMovies = useCallback(async (searchTerm = '') => {
    setLoading(true);
    setErrorMsg('');
    try {
      const params = {};
      if (searchTerm.trim()) params.search = searchTerm.trim();
      params.page = 1;
      params.pageSize = 100;
      const result = await movieApi.getAll(params);
      const movieData = result?.data;
      setMovies(Array.isArray(movieData) ? movieData : movieData?.items || []);
    } catch (err) {
      setErrorMsg(err.message || 'Không thể tải danh sách phim. Vui lòng thử lại!');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchCategories = useCallback(async () => {
    try {
      const result = await categoryApi.getAll();
      setCategories(Array.isArray(result?.data) ? result.data : []);
    } catch {
      // Không chặn trang nếu lỗi lấy category, chỉ ảnh hưởng form thêm/sửa
    }
  }, []);

  const fetchAvailableStreams = useCallback(async () => {
    try {
      const result = await movieApi.getAvailableStreams();
      if (result?.data) {
        setAvailableStreams(result.data);
      }
    } catch {
      // Không chặn trang nếu không tải được danh sách luồng phát có sẵn
    }
  }, []);

  useEffect(() => {
    Promise.resolve().then(() => {
      fetchMovies();
      fetchCategories();
      fetchAvailableStreams();
    });
  }, [fetchMovies, fetchCategories, fetchAvailableStreams]);

  // Debounce tìm kiếm để không gọi API liên tục khi gõ
  useEffect(() => {
    const timer = setTimeout(() => {
      fetchMovies(search);
    }, 400);
    return () => clearTimeout(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search]);

  const openCreateModal = () => {
    setEditingId(null);
    setForm(EMPTY_FORM);
    setFormErrors({});
    setShowHlsPicker(false);
    setModalOpen(true);
  };

  const openEditModal = async (movie) => {
    setEditingId(movie.id);
    setShowHlsPicker(false);
    setForm({
      title: movie.title || '',
      description: movie.description || '',
      posterUrl: movie.posterUrl || '',
      videoUrl: movie.videoUrl || '',
      trailerUrl: movie.trailerUrl || '',
      duration: movie.duration ?? '',
      releaseYear: movie.releaseYear ?? '',
      type: movie.type ?? 0,
      videoStatus: movie.videoStatus ?? 1,
      categoryIds: (movie.categories || []).map((c) => c.id),
    });
    setFormErrors({});
    setModalOpen(true);

    // Nạp thêm chi tiết từ API getById để đảm bảo dữ liệu luôn đầy đủ và mới nhất
    try {
      const res = await movieApi.getById(movie.id);
      if (res?.data) {
        const detail = res.data;
        setForm((prev) => ({
          ...prev,
          title: detail.title ?? prev.title,
          description: detail.description ?? prev.description,
          posterUrl: detail.posterUrl ?? prev.posterUrl,
          videoUrl: detail.videoUrl ?? prev.videoUrl,
          trailerUrl: detail.trailerUrl ?? prev.trailerUrl,
          duration: detail.duration ?? prev.duration,
          releaseYear: detail.releaseYear ?? prev.releaseYear,
          type: detail.type ?? prev.type,
          videoStatus: detail.videoStatus ?? prev.videoStatus,
          categoryIds: (detail.categories || []).map((c) => c.id),
        }));
      }
    } catch {
      // Giữ nguyên dữ liệu từ bảng danh sách nếu không thể gọi API chi tiết
    }
  };

  const closeModal = () => {
    if (saving) return;
    setShowHlsPicker(false);
    setModalOpen(false);
  };

  const toggleCategory = (id) => {
    setForm((prev) => {
      const exists = prev.categoryIds.includes(id);
      return {
        ...prev,
        categoryIds: exists
          ? prev.categoryIds.filter((c) => c !== id)
          : [...prev.categoryIds, id],
      };
    });
  };

  const validateForm = () => {
    const errors = {};
    if (!form.title.trim()) {
      errors.title = 'Tiêu đề phim không được để trống!';
    } else if (form.title.trim().length > 255) {
      errors.title = 'Tiêu đề tối đa 255 ký tự!';
    }
    if (form.duration && (Number(form.duration) < 1 || Number(form.duration) > 1000)) {
      errors.duration = 'Thời lượng phải từ 1 đến 1000 phút!';
    }
    if (form.releaseYear && (Number(form.releaseYear) < 1888 || Number(form.releaseYear) > 2100)) {
      errors.releaseYear = 'Năm phát hành phải từ 1888 đến 2100!';
    }
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    setSaving(true);
    try {
      const payload = {
        title: form.title.trim(),
        description: form.description.trim() || null,
        posterUrl: form.posterUrl.trim() || null,
        videoUrl: form.videoUrl.trim() || null,
        trailerUrl: form.trailerUrl.trim() || null,
        duration: form.duration ? Number(form.duration) : null,
        releaseYear: form.releaseYear ? Number(form.releaseYear) : null,
        type: Number(form.type),
        categoryIds: form.categoryIds,
      };

      if (editingId) {
        payload.videoStatus = Number(form.videoStatus);
        await movieApi.update(editingId, payload);
      } else {
        await movieApi.create(payload);
      }

      setModalOpen(false);
      await fetchMovies(search);
    } catch (err) {
      if (err.errors && err.errors.length > 0) {
        setFormErrors({ general: err.errors.join(', ') });
      } else {
        setFormErrors({ general: err.message || 'Có lỗi xảy ra, vui lòng thử lại!' });
      }
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await movieApi.delete(deleteTarget.id);
      setDeleteTarget(null);
      await fetchMovies(search);
    } catch (err) {
      setErrorMsg(err.message || 'Xóa phim thất bại!');
      setDeleteTarget(null);
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white">Quản lý nội dung</h1>
          <p className="text-slate-400 mt-1">Danh sách phim lẻ, phim bộ và các tập phim.</p>
        </div>
        <motion.button
          whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}
          onClick={openCreateModal}
          className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-xl flex items-center gap-2 font-bold shadow-lg shadow-blue-600/30 transition-all"
        >
          <Plus size={20} /> Thêm phim mới
        </motion.button>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        <div className="p-4 border-b border-slate-800 flex flex-col md:flex-row gap-4 bg-slate-900/50">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Tìm kiếm phim..."
              className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl py-2 pl-10 pr-4 focus:ring-2 focus:ring-blue-500 outline-none transition-all"
            />
          </div>
        </div>

        {errorMsg && (
          <div className="mx-4 mt-4 bg-red-500/10 border border-red-500/20 text-red-400 text-sm p-3 rounded-xl">
            {errorMsg}
          </div>
        )}

        {loading && movies.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-slate-500">
            <Loader2 className="animate-spin mb-3" size={32} />
            <p>Đang tải danh sách phim...</p>
          </div>
        ) : movies.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-slate-500">
            <Film size={40} className="mb-3 opacity-50" />
            <p>{search ? 'Không tìm thấy phim phù hợp.' : 'Chưa có phim nào. Hãy thêm mới!'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead className="bg-slate-800/50 text-slate-400 uppercase text-xs font-bold tracking-wider">
                <tr>
                  <th className="px-6 py-4">Phim</th>
                  <th className="px-6 py-4">Thể loại</th>
                  <th className="px-6 py-4">Loại</th>
                  <th className="px-6 py-4">Năm</th>
                  <th className="px-6 py-4 text-center">Thao tác</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800 text-slate-300">
                {movies.map((movie, index) => (
                  <motion.tr
                    initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: index * 0.03 }}
                    key={movie.id} className="hover:bg-slate-800/30 transition-colors group"
                  >
                    <td className="px-6 py-4">
                      <Link
                        to={`/movies/${movie.id}`}
                        className="flex items-center gap-4 group/movie hover:text-blue-400 transition-colors"
                        title={`Xem chi tiết ${movie.title}`}
                      >
                        <div className="w-12 h-16 bg-slate-800 rounded-lg flex items-center justify-center border border-slate-700 group-hover:border-blue-500 transition-all overflow-hidden relative shrink-0">
                          {movie.posterUrl ? (
                            <img src={movie.posterUrl} alt={movie.title} className="w-full h-full object-cover" />
                          ) : (
                            <PlayCircle className="text-white/20" />
                          )}
                        </div>
                        <div>
                          <p className="font-bold text-white group-hover/movie:text-blue-300 transition-colors">{movie.title}</p>
                          <span className="text-xs text-slate-500">ID: {movie.id}</span>
                        </div>
                      </Link>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex flex-wrap gap-1 max-w-50">
                        {(movie.categories || []).length > 0 ? (
                          movie.categories.map((c) => (
                            <span key={c.id} className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-blue-500/10 text-blue-400 border border-blue-500/20">
                              {c.name}
                            </span>
                          ))
                        ) : (
                          <span className="text-slate-600 text-xs italic">Chưa gán</span>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm">{MOVIE_TYPE_LABEL[movie.type] || '—'}</td>
                    <td className="px-6 py-4 text-sm">{movie.releaseYear || '—'}</td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-center gap-2">
                        <button
                          onClick={() => openEditModal(movie)}
                          className="p-2 hover:bg-blue-500/10 hover:text-blue-400 rounded-lg transition-all"
                        >
                          <Edit2 size={18} />
                        </button>
                        <button
                          onClick={() => setDeleteTarget(movie)}
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

      {/* Modal Thêm/Sửa phim */}
      <Modal
        open={modalOpen}
        title={editingId ? 'Chỉnh sửa phim' : 'Thêm phim mới'}
        onClose={closeModal}
        maxWidth="max-w-2xl"
      >
        <form onSubmit={handleSubmit} className="space-y-5">
          {formErrors.general && (
            <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-sm p-3 rounded-xl">
              {formErrors.general}
            </div>
          )}

          <div className="space-y-1">
            <label className="text-slate-400 text-xs font-bold uppercase ml-1">Tiêu đề phim *</label>
            <input
              type="text"
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              placeholder="Ví dụ: Quan Xẩm Lốc Cốc"
              className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
            />
            {formErrors.title && <p className="text-red-400 text-xs ml-1">{formErrors.title}</p>}
          </div>

          <div className="space-y-1">
            <label className="text-slate-400 text-xs font-bold uppercase ml-1">Mô tả</label>
            <textarea
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              placeholder="Nội dung tóm tắt phim..."
              rows={3}
              className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all resize-none"
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-1">
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Poster URL</label>
              <input
                type="text"
                value={form.posterUrl}
                onChange={(e) => setForm({ ...form, posterUrl: e.target.value })}
                placeholder="https://..."
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              />
            </div>
            <div className="space-y-1">
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Trailer URL</label>
              <input
                type="text"
                value={form.trailerUrl}
                onChange={(e) => setForm({ ...form, trailerUrl: e.target.value })}
                placeholder="https://youtube.com/..."
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              />
            </div>
          </div>

          <div className="space-y-2">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Video URL (HLS .m3u8 hoặc MP4)</label>
              <button
                type="button"
                onClick={() => setShowHlsPicker(!showHlsPicker)}
                className={`px-2.5 py-1 text-xs rounded-lg border font-medium transition-all flex items-center gap-1.5 ${
                  showHlsPicker
                    ? 'bg-blue-600 text-white border-blue-500 shadow-md shadow-blue-500/20'
                    : 'bg-slate-800/80 text-blue-400 border-slate-700 hover:bg-slate-800'
                }`}
                title="Chọn nhanh từ các thư mục video HLS đã băm trên máy chủ bằng split_video.bat"
              >
                <Layers size={13} />
                <span>Kho HLS nội bộ ({availableStreams.internalStreams.length})</span>
              </button>
            </div>

            {/* Panel chọn nhanh HLS nội bộ */}
            {showHlsPicker && (
              <div className="bg-slate-900 border border-blue-500/30 rounded-xl p-3 space-y-2 animate-fadeIn shadow-lg">
                <div className="flex items-center justify-between text-xs text-slate-400 pb-1.5 border-b border-slate-800">
                  <span className="font-semibold text-blue-300">Kho video HLS trên máy chủ Kestrel:</span>
                  <span className="text-[11px] text-blue-400 font-mono">Bấm để tự động điền URL</span>
                </div>
                {availableStreams.internalStreams.length === 0 ? (
                  <p className="text-xs text-slate-500 italic py-1">Chưa phát hiện thư mục HLS nào trong wwwroot/videos. Hãy dùng split_video.bat để băm video.</p>
                ) : (
                  <div className="space-y-1.5 max-h-44 overflow-y-auto pr-1">
                    {availableStreams.internalStreams.map((s) => (
                      <button
                        key={s.streamKey}
                        type="button"
                        onClick={() => {
                          setForm((prev) => ({ ...prev, videoUrl: s.relativeUrl, videoStatus: 1 }));
                          setShowHlsPicker(false);
                        }}
                        className="w-full text-left p-2 rounded-lg bg-slate-800/60 hover:bg-blue-600/20 border border-slate-700/60 hover:border-blue-500/40 transition-all flex items-center justify-between gap-3 group"
                      >
                        <div>
                          <p className="text-xs font-semibold text-white group-hover:text-blue-300 transition-colors">
                            Thư mục #{s.streamKey} — {s.relativeUrl}
                          </p>
                          <p className="text-[11px] text-slate-400">
                            {s.segmentCount} phân đoạn .ts • {s.totalSizeMb} MB
                          </p>
                        </div>
                        <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium shrink-0 ${
                          s.isAssigned
                            ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                            : 'bg-blue-500/10 text-blue-400 border border-blue-500/20'
                        }`}>
                          {s.isAssigned ? `Đang gán: ${s.assignedMovieTitle}` : 'Sẵn sàng'}
                        </span>
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}

            <input
              type="text"
              value={form.videoUrl}
              onChange={(e) => setForm({ ...form, videoUrl: e.target.value })}
              placeholder="Ví dụ: /videos/1/master.m3u8 (hoặc bấm Kho HLS nội bộ ở trên để chọn)"
              className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all font-mono text-sm"
            />
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="space-y-1">
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Thời lượng (phút)</label>
              <input
                type="number"
                value={form.duration}
                onChange={(e) => setForm({ ...form, duration: e.target.value })}
                placeholder="106"
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              />
              {formErrors.duration && <p className="text-red-400 text-xs ml-1">{formErrors.duration}</p>}
            </div>
            <div className="space-y-1">
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Năm phát hành</label>
              <input
                type="number"
                value={form.releaseYear}
                onChange={(e) => setForm({ ...form, releaseYear: e.target.value })}
                placeholder="2024"
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              />
              {formErrors.releaseYear && <p className="text-red-400 text-xs ml-1">{formErrors.releaseYear}</p>}
            </div>
            <div className="space-y-1 col-span-2 md:col-span-1">
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Loại phim</label>
              <select
                value={form.type}
                onChange={(e) => setForm({ ...form, type: Number(e.target.value) })}
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              >
                <option value={0}>Phim lẻ</option>
                <option value={1}>Phim bộ</option>
              </select>
            </div>
            {editingId && (
              <div className="space-y-1 col-span-2 md:col-span-1">
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Trạng thái Video</label>
                <select
                  value={form.videoStatus}
                  onChange={(e) => setForm({ ...form, videoStatus: Number(e.target.value) })}
                  className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
                >
                  <option value={0}>Chưa xử lý</option>
                  <option value={1}>Sẵn sàng</option>
                  <option value={2}>Lỗi</option>
                </select>
              </div>
            )}
          </div>

          <div className="space-y-2">
            <label className="text-slate-400 text-xs font-bold uppercase ml-1">Thể loại</label>
            <div className="flex flex-wrap gap-2">
              {categories.length === 0 ? (
                <p className="text-slate-600 text-sm italic">Chưa có thể loại nào. Hãy thêm thể loại trước.</p>
              ) : (
                categories.map((cat) => {
                  const selected = form.categoryIds.includes(cat.id);
                  return (
                    <button
                      key={cat.id}
                      type="button"
                      onClick={() => toggleCategory(cat.id)}
                      className={`px-3 py-1.5 rounded-full text-sm font-medium border transition-all flex items-center gap-1 ${
                        selected
                          ? 'bg-blue-600 border-blue-600 text-white'
                          : 'bg-slate-800 border-slate-700 text-slate-300 hover:border-blue-500/50'
                      }`}
                    >
                      {cat.name}
                      {selected && <X size={14} />}
                    </button>
                  );
                })
              )}
            </div>
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

      <ConfirmDialog
        open={Boolean(deleteTarget)}
        title="Xóa phim?"
        description={deleteTarget ? `Bạn có chắc muốn xóa phim "${deleteTarget.title}"? Hành động này không thể hoàn tác.` : ''}
        confirmLabel="Xóa phim"
        loading={deleting}
        onConfirm={handleDelete}
        onCancel={() => !deleting && setDeleteTarget(null)}
      />
    </div>
  );
};

export default Movies;