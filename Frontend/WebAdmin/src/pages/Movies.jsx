// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { useState, useEffect, useCallback } from 'react';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { motion } from 'framer-motion';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { Plus, Search, Edit2, Trash2, PlayCircle, Loader2, Film, X, Layers, Star, ChevronLeft, ChevronRight } from 'lucide-react';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { Link } from 'react-router-dom';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import movieApi from '../api/movieApi';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import categoryApi from '../api/categoryApi';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import Modal from '../components/Modal';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import ConfirmDialog from '../components/ConfirmDialog';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
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
  isFeatured: false,
  publishStatus: 2, // 0 = Draft, 1 = ComingSoon, 2 = Published
  categoryIds: [],
};

// MovieType: Single = 0, Series = 1 (khớp enum bên Backend)
const MOVIE_TYPE_LABEL = { 0: 'Phim lẻ', 1: 'Phim bộ' };

// Cấu hình nhãn và màu sắc cho 3 trạng thái phát hành
const PUBLISH_STATUS_CONFIG = {
  0: { label: 'Bản nháp', color: 'bg-slate-800 text-slate-400 border-slate-700' },
  1: { label: 'Sắp chiếu', color: 'bg-blue-500/10 text-blue-400 border-blue-500/20' },
  2: { label: 'Đã phát hành', color: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' },
};

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const Movies = () => {
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [movies, setMovies] = useState([]);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [categories, setCategories] = useState([]);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [loading, setLoading] = useState(true);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [errorMsg, setErrorMsg] = useState('');
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [search, setSearch] = useState('');

  // Trạng thái phân trang danh sách phim
  const [page, setPage] = useState(1);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [pageSize, setPageSize] = useState(10);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [totalPages, setTotalPages] = useState(1);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [totalCount, setTotalCount] = useState(0);

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [modalOpen, setModalOpen] = useState(false);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [editingId, setEditingId] = useState(null);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [form, setForm] = useState(EMPTY_FORM);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [formErrors, setFormErrors] = useState({});
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [saving, setSaving] = useState(false);

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [deleteTarget, setDeleteTarget] = useState(null);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [deleting, setDeleting] = useState(false);

  // Danh sách luồng phát có sẵn từ kho HLS nội bộ
  const [availableStreams, setAvailableStreams] = useState({ internalStreams: [], cdnPresets: [] });
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [showHlsPicker, setShowHlsPicker] = useState(false);

  // Tải danh sách phim phân trang từ máy chủ Backend
  const fetchMovies = useCallback(async (pageNumber = 1, searchTerm = '', size = 10) => {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setLoading(true);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setErrorMsg('');
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const params = {
        page: pageNumber,
        pageSize: size,
        includeDraft: true,
      };
      // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
      if (searchTerm.trim()) params.search = searchTerm.trim();
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const result = await movieApi.getAll(params);
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const movieData = result?.data;
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const items = Array.isArray(movieData) ? movieData : movieData?.items || [];
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setMovies(items);
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setTotalPages(movieData?.totalPages || 1);
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setTotalCount(movieData?.totalCount || items.length);
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setPage(movieData?.pageNumber || pageNumber);
    } catch (err) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setErrorMsg(err.message || 'Không thể tải danh sách phim. Vui lòng thử lại!');
    } finally {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setLoading(false);
    }
  }, []);

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const fetchCategories = useCallback(async () => {
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const result = await categoryApi.getAll();
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setCategories(Array.isArray(result?.data) ? result.data : []);
    } catch {
      // Không chặn trang nếu lỗi lấy category, chỉ ảnh hưởng form thêm/sửa
    }
  }, []);

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const fetchAvailableStreams = useCallback(async () => {
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const result = await movieApi.getAvailableStreams();
      // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
      if (result?.data) {
        // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
        setAvailableStreams(result.data);
      }
    } catch {
      // Không chặn trang nếu không tải được danh sách luồng phát có sẵn
    }
  }, []);

  // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
  useEffect(() => {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    fetchCategories();
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    fetchAvailableStreams();
  }, [fetchCategories, fetchAvailableStreams]);

  // Tự động tải lại danh sách phim theo trang, từ khóa tìm kiếm và kích thước trang
  useEffect(() => {
    // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
    const timer = setTimeout(() => {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      fetchMovies(page, search, pageSize);
    }, 300);
    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
    return () => clearTimeout(timer);
  }, [page, search, pageSize, fetchMovies]);

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const openCreateModal = () => {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setEditingId(null);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setForm(EMPTY_FORM);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setFormErrors({});
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setShowHlsPicker(false);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setModalOpen(true);
  };

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const openEditModal = async (movie) => {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setEditingId(movie.id);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setShowHlsPicker(false);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
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
      isFeatured: Boolean(movie.isFeatured),
      publishStatus: movie.publishStatus ?? 2,
      categoryIds: (movie.categories || []).map((c) => c.id),
    });
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setFormErrors({});
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setModalOpen(true);

    // Nạp thêm chi tiết từ API getById để đảm bảo dữ liệu luôn đầy đủ và mới nhất
    try {
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const res = await movieApi.getById(movie.id);
      // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
      if (res?.data) {
        // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
        const detail = res.data;
        // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
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
          isFeatured: detail.isFeatured ?? prev.isFeatured,
          publishStatus: detail.publishStatus ?? prev.publishStatus,
          categoryIds: (detail.categories || []).map((c) => c.id),
        }));
      }
    } catch {
      // Giữ nguyên dữ liệu từ bảng danh sách nếu không thể gọi API chi tiết
    }
  };

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const closeModal = () => {
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (saving) return;
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setShowHlsPicker(false);
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setModalOpen(false);
  };

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const toggleCategory = (id) => {
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setForm((prev) => {
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const exists = prev.categoryIds.includes(id);
      // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
      return {
        ...prev,
        categoryIds: exists
          ? prev.categoryIds.filter((c) => c !== id)
          : [...prev.categoryIds, id],
      };
    });
  };

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const validateForm = () => {
    // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
    const errors = {};
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (!form.title.trim()) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      errors.title = 'Tiêu đề phim không được để trống!';
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    } else if (form.title.trim().length > 255) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      errors.title = 'Tiêu đề tối đa 255 ký tự!';
    }
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (form.duration && (Number(form.duration) < 1 || Number(form.duration) > 1000)) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      errors.duration = 'Thời lượng phải từ 1 đến 1000 phút!';
    }
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (form.releaseYear && (Number(form.releaseYear) < 1888 || Number(form.releaseYear) > 2100)) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      errors.releaseYear = 'Năm phát hành phải từ 1888 đến 2100!';
    }
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setFormErrors(errors);
    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
    return Object.keys(errors).length === 0;
  };

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
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
        title: form.title.trim(),
        description: form.description.trim() || null,
        posterUrl: form.posterUrl.trim() || null,
        videoUrl: form.videoUrl.trim() || null,
        trailerUrl: form.trailerUrl.trim() || null,
        duration: form.duration ? Number(form.duration) : null,
        releaseYear: form.releaseYear ? Number(form.releaseYear) : null,
        type: Number(form.type),
        isFeatured: Boolean(form.isFeatured),
        publishStatus: Number(form.publishStatus),
        categoryIds: form.categoryIds,
      };

      // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
      if (editingId) {
        // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
        payload.videoStatus = Number(form.videoStatus);
        // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
        await movieApi.update(editingId, payload);
      } else {
        // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
        await movieApi.create(payload);
      }

      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setModalOpen(false);
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      await fetchMovies(page, search, pageSize);
    } catch (err) {
      // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
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

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const handleDelete = async () => {
    // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
    if (!deleteTarget) return;
    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
    setDeleting(true);
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      await movieApi.delete(deleteTarget.id);
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setDeleteTarget(null);
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const targetPage = movies.length === 1 && page > 1 ? page - 1 : page;
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setPage(targetPage);
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      await fetchMovies(targetPage, search, pageSize);
    } catch (err) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setErrorMsg(err.message || 'Xóa phim thất bại!');
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setDeleteTarget(null);
    } finally {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setDeleting(false);
    }
  };

  // Chuyển đổi nhanh trạng thái phim nổi bật (Bật / Tắt trực tiếp trên từng dòng bảng)
  const handleToggleFeatured = async (movie) => {
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      await movieApi.toggleFeatured(movie.id);
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setMovies((prev) =>
        prev.map((m) => (m.id === movie.id ? { ...m, isFeatured: !m.isFeatured } : m))
      );
    } catch (err) {
      // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
      setErrorMsg(err.message || 'Không thể thay đổi trạng thái phim nổi bật!');
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
          <h1 className="text-3xl font-bold text-white">Quản lý nội dung</h1>
          {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
          <p className="text-slate-400 mt-1">Danh sách phim lẻ, phim bộ và các tập phim.</p>
        </div>
        {/* Hiển thị phần tử giao diện giao diện và nội dung con của nó. */}
        <motion.button
          whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}
          onClick={openCreateModal}
          className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-xl flex items-center gap-2 font-bold shadow-lg shadow-blue-600/30 transition-all"
        >
          {/* Hiển thị phần tử giao diện Plus và nội dung con của nó. */}
          <Plus size={20} /> Thêm phim mới
        </motion.button>
      </div>

      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
        <div className="p-4 border-b border-slate-800 flex flex-col md:flex-row gap-4 bg-slate-900/50">
          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="relative flex-1">
            {/* Hiển thị phần tử giao diện Search và nội dung con của nó. */}
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
            {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
            <input
              type="text"
              value={search}
              onChange={(e) => {
                // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
                setSearch(e.target.value);
                // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
                setPage(1);
              }}
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
            {/* Hiển thị phần tử giao diện Loader2 và nội dung con của nó. */}
            <Loader2 className="animate-spin mb-3" size={32} />
            {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
            <p>Đang tải danh sách phim...</p>
          </div>
        ) : movies.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-slate-500">
            {/* Hiển thị phần tử giao diện Film và nội dung con của nó. */}
            <Film size={40} className="mb-3 opacity-50" />
            {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
            <p>{search ? 'Không tìm thấy phim phù hợp.' : 'Chưa có phim nào. Hãy thêm mới!'}</p>
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
                  <th className="px-6 py-4">Phim</th>
                  {/* Hiển thị phần tử giao diện th và nội dung con của nó. */}
                  <th className="px-6 py-4">Thể loại</th>
                  {/* Hiển thị phần tử giao diện th và nội dung con của nó. */}
                  <th className="px-6 py-4">Trạng thái</th>
                  {/* Hiển thị phần tử giao diện th và nội dung con của nó. */}
                  <th className="px-6 py-4">Loại</th>
                  {/* Hiển thị phần tử giao diện th và nội dung con của nó. */}
                  <th className="px-6 py-4">Năm</th>
                  {/* Hiển thị phần tử giao diện th và nội dung con của nó. */}
                  <th className="px-6 py-4 text-center">Thao tác</th>
                </tr>
              </thead>
              {/* Hiển thị phần tử giao diện tbody và nội dung con của nó. */}
              <tbody className="divide-y divide-slate-800 text-slate-300">
                {movies.map((movie, index) => (
                  <motion.tr
                    initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: index * 0.03 }}
                    key={movie.id} className="hover:bg-slate-800/30 transition-colors group"
                  >
                    {/* Hiển thị phần tử giao diện td và nội dung con của nó. */}
                    <td className="px-6 py-4">
                      {/* Hiển thị phần tử giao diện Link và nội dung con của nó. */}
                      <Link
                        to={`/movies/${movie.id}`}
                        className="flex items-center gap-4 group/movie hover:text-blue-400 transition-colors"
                        title={`Xem chi tiết ${movie.title}`}
                      >
                        {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
                        <div className="w-12 h-16 bg-slate-800 rounded-lg flex items-center justify-center border border-slate-700 group-hover:border-blue-500 transition-all overflow-hidden relative shrink-0">
                          {movie.posterUrl ? (
                            <img src={movie.posterUrl} alt={movie.title} className="w-full h-full object-cover" />
                          ) : (
                            <PlayCircle className="text-white/20" />
                          )}
                        </div>
                        {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
                        <div>
                          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
                          <div className="flex items-center gap-2 flex-wrap">
                            {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
                            <p className="font-bold text-white group-hover/movie:text-blue-300 transition-colors">{movie.title}</p>
                            {movie.isFeatured && (
                              <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-500/15 text-amber-400 border border-amber-500/30 shrink-0">
                                Nổi bật
                              </span>
                            )}
                          </div>
                          {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                          <span className="text-xs text-slate-500">ID: {movie.id}</span>
                        </div>
                      </Link>
                    </td>
                    {/* Hiển thị phần tử giao diện td và nội dung con của nó. */}
                    <td className="px-6 py-4">
                      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
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
                    {/* Hiển thị phần tử giao diện td và nội dung con của nó. */}
                    <td className="px-6 py-4 text-sm">
                      {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                      <span className={`px-2.5 py-1 rounded-full text-xs font-bold border ${
                        PUBLISH_STATUS_CONFIG[movie.publishStatus]?.color || PUBLISH_STATUS_CONFIG[2].color
                      }`}>
                        {PUBLISH_STATUS_CONFIG[movie.publishStatus]?.label || 'Đã phát hành'}
                      </span>
                    </td>
                    {/* Hiển thị phần tử giao diện td và nội dung con của nó. */}
                    <td className="px-6 py-4 text-sm">{MOVIE_TYPE_LABEL[movie.type] || '—'}</td>
                    {/* Hiển thị phần tử giao diện td và nội dung con của nó. */}
                    <td className="px-6 py-4 text-sm">{movie.releaseYear || '—'}</td>
                    {/* Hiển thị phần tử giao diện td và nội dung con của nó. */}
                    <td className="px-6 py-4">
                      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
                      <div className="flex items-center justify-center gap-2">
                        {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
                        <button
                          type="button"
                          onClick={() => handleToggleFeatured(movie)}
                          className={`p-2 rounded-lg transition-all ${
                            movie.isFeatured
                              ? 'bg-amber-500/15 text-amber-400 hover:bg-amber-500/25 border border-amber-500/30'
                              : 'hover:bg-slate-700/50 text-slate-400 hover:text-amber-400'
                          }`}
                          title={movie.isFeatured ? "Hạ khỏi Banner nổi bật" : "Đặt làm Phim nổi bật trên Banner"}
                        >
                          {/* Hiển thị phần tử giao diện Star và nội dung con của nó. */}
                          <Star size={18} className={movie.isFeatured ? "fill-amber-400" : ""} />
                        </button>
                        {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
                        <button
                          onClick={() => openEditModal(movie)}
                          className="p-2 hover:bg-blue-500/10 hover:text-blue-400 rounded-lg transition-all"
                        >
                          {/* Hiển thị phần tử giao diện Edit2 và nội dung con của nó. */}
                          <Edit2 size={18} />
                        </button>
                        {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
                        <button
                          onClick={() => setDeleteTarget(movie)}
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

        {/* Thanh điều khiển phân trang danh sách phim */}
        {totalCount > 0 && (
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 px-6 py-4 border-t border-slate-800 bg-slate-900/60 rounded-b-2xl">
            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div className="flex items-center gap-3 text-sm text-slate-400">
              {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
              <span>
                Hiển thị <span className="font-semibold text-white">{(page - 1) * pageSize + 1}</span> - <span className="font-semibold text-white">{Math.min(page * pageSize, totalCount)}</span> trên tổng số <span className="font-semibold text-white">{totalCount}</span> phim
              </span>
              {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
              <span className="text-slate-600">|</span>
              {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
              <label className="flex items-center gap-1.5 text-xs text-slate-400">
                {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                <span>Số hàng:</span>
                {/* Hiển thị phần tử giao diện select và nội dung con của nó. */}
                <select
                  value={pageSize}
                  onChange={(e) => {
                    // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
                    const newSize = Number(e.target.value);
                    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
                    setPageSize(newSize);
                    // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
                    setPage(1);
                  }}
                  className="bg-slate-800 border border-slate-700 text-white rounded-lg px-2 py-1 outline-none text-xs cursor-pointer focus:border-blue-500"
                >
                  {/* Hiển thị phần tử giao diện option và nội dung con của nó. */}
                  <option value={8}>8 / trang</option>
                  {/* Hiển thị phần tử giao diện option và nội dung con của nó. */}
                  <option value={10}>10 / trang</option>
                  {/* Hiển thị phần tử giao diện option và nội dung con của nó. */}
                  <option value={20}>20 / trang</option>
                  {/* Hiển thị phần tử giao diện option và nội dung con của nó. */}
                  <option value={50}>50 / trang</option>
                </select>
              </label>
            </div>

            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div className="flex items-center gap-1.5">
              {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
              <button
                type="button"
                disabled={page <= 1 || loading}
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                className="flex items-center gap-1 px-3 py-1.5 rounded-xl border border-slate-700 bg-slate-800/80 text-slate-300 hover:bg-slate-700 disabled:opacity-30 disabled:cursor-not-allowed text-xs font-medium transition-all"
              >
                {/* Hiển thị phần tử giao diện ChevronLeft và nội dung con của nó. */}
                <ChevronLeft size={16} />
                {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                <span>Trước</span>
              </button>

              {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
              <div className="flex items-center gap-1 px-1">
                {Array.from({ length: totalPages }, (_, i) => i + 1)
                  .filter((p) => p === 1 || p === totalPages || Math.abs(p - page) <= 1)
                  .map((p, idx, arr) => {
                    // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
                    const prevP = arr[idx - 1];
                    // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
                    const showEllipsis = prevP && p - prevP > 1;
                    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
                    return (
                      <div key={p} className="flex items-center">
                        {showEllipsis && <span className="px-1.5 text-slate-500 text-xs">...</span>}
                        {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
                        <button
                          type="button"
                          disabled={loading}
                          onClick={() => setPage(p)}
                          className={`min-w-[32px] h-8 px-2.5 rounded-xl text-xs font-semibold transition-all ${
                            page === p
                              ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/20'
                              : 'bg-slate-800/50 text-slate-400 hover:bg-slate-800 hover:text-white border border-slate-700/50'
                          }`}
                        >
                          {p}
                        </button>
                      </div>
                    );
                  })}
              </div>

              {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
              <button
                type="button"
                disabled={page >= totalPages || loading}
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                className="flex items-center gap-1 px-3 py-1.5 rounded-xl border border-slate-700 bg-slate-800/80 text-slate-300 hover:bg-slate-700 disabled:opacity-30 disabled:cursor-not-allowed text-xs font-medium transition-all"
              >
                {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                <span>Sau</span>
                {/* Hiển thị phần tử giao diện ChevronRight và nội dung con của nó. */}
                <ChevronRight size={16} />
              </button>
            </div>
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
            <label className="text-slate-400 text-xs font-bold uppercase ml-1">Tiêu đề phim *</label>
            {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
            <input
              type="text"
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              placeholder="Ví dụ: Quan Xẩm Lốc Cốc"
              className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
            />
            {formErrors.title && <p className="text-red-400 text-xs ml-1">{formErrors.title}</p>}
          </div>

          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="space-y-1">
            {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
            <label className="text-slate-400 text-xs font-bold uppercase ml-1">Mô tả</label>
            {/* Hiển thị phần tử giao diện textarea và nội dung con của nó. */}
            <textarea
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              placeholder="Nội dung tóm tắt phim..."
              rows={3}
              className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all resize-none"
            />
          </div>

          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div className="space-y-1">
              {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Poster URL</label>
              {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
              <input
                type="text"
                value={form.posterUrl}
                onChange={(e) => setForm({ ...form, posterUrl: e.target.value })}
                placeholder="https://..."
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              />
            </div>
            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div className="space-y-1">
              {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Trailer URL</label>
              {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
              <input
                type="text"
                value={form.trailerUrl}
                onChange={(e) => setForm({ ...form, trailerUrl: e.target.value })}
                placeholder="https://youtube.com/..."
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              />
            </div>
          </div>

          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="space-y-2">
            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div className="flex flex-wrap items-center justify-between gap-2">
              {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Video URL (HLS .m3u8 hoặc MP4)</label>
              {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
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
                {/* Hiển thị phần tử giao diện Layers và nội dung con của nó. */}
                <Layers size={13} />
                {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                <span>Kho HLS nội bộ ({availableStreams.internalStreams.length})</span>
              </button>
            </div>

            {/* Panel chọn nhanh HLS nội bộ */}
            {showHlsPicker && (
              <div className="bg-slate-900 border border-blue-500/30 rounded-xl p-3 space-y-2 animate-fadeIn shadow-lg">
                {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
                <div className="flex items-center justify-between text-xs text-slate-400 pb-1.5 border-b border-slate-800">
                  {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                  <span className="font-semibold text-blue-300">Kho video HLS trên máy chủ Kestrel:</span>
                  {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
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
                          // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
                          setForm((prev) => ({ ...prev, videoUrl: s.relativeUrl, videoStatus: 1 }));
                          // Thực thi thao tác cập nhật trạng thái hoặc gọi dịch vụ liên quan.
                          setShowHlsPicker(false);
                        }}
                        className="w-full text-left p-2 rounded-lg bg-slate-800/60 hover:bg-blue-600/20 border border-slate-700/60 hover:border-blue-500/40 transition-all flex items-center justify-between gap-3 group"
                      >
                        {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
                        <div>
                          {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
                          <p className="text-xs font-semibold text-white group-hover:text-blue-300 transition-colors">
                            Thư mục #{s.streamKey} — {s.relativeUrl}
                          </p>
                          {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
                          <p className="text-[11px] text-slate-400">
                            {s.segmentCount} phân đoạn .ts • {s.totalSizeMb} MB
                          </p>
                        </div>
                        {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
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

            {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
            <input
              type="text"
              value={form.videoUrl}
              onChange={(e) => setForm({ ...form, videoUrl: e.target.value })}
              placeholder="Ví dụ: /videos/1/master.m3u8 (hoặc bấm Kho HLS nội bộ ở trên để chọn)"
              className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all font-mono text-sm"
            />
          </div>

          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div className="space-y-1">
              {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Thời lượng (phút)</label>
              {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
              <input
                type="number"
                value={form.duration}
                onChange={(e) => setForm({ ...form, duration: e.target.value })}
                placeholder="106"
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              />
              {formErrors.duration && <p className="text-red-400 text-xs ml-1">{formErrors.duration}</p>}
            </div>
            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div className="space-y-1">
              {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Năm phát hành</label>
              {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
              <input
                type="number"
                value={form.releaseYear}
                onChange={(e) => setForm({ ...form, releaseYear: e.target.value })}
                placeholder="2024"
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              />
              {formErrors.releaseYear && <p className="text-red-400 text-xs ml-1">{formErrors.releaseYear}</p>}
            </div>
            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div className="space-y-1 col-span-2 md:col-span-1">
              {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Loại phim</label>
              {/* Hiển thị phần tử giao diện select và nội dung con của nó. */}
              <select
                value={form.type}
                onChange={(e) => setForm({ ...form, type: Number(e.target.value) })}
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              >
                {/* Hiển thị phần tử giao diện option và nội dung con của nó. */}
                <option value={0}>Phim lẻ</option>
                {/* Hiển thị phần tử giao diện option và nội dung con của nó. */}
                <option value={1}>Phim bộ</option>
              </select>
            </div>
            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div className="space-y-1 col-span-2 md:col-span-1">
              {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Trạng thái phát hành</label>
              {/* Hiển thị phần tử giao diện select và nội dung con của nó. */}
              <select
                value={form.publishStatus}
                onChange={(e) => setForm({ ...form, publishStatus: Number(e.target.value) })}
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all font-medium"
              >
                {/* Hiển thị phần tử giao diện option và nội dung con của nó. */}
                <option value={0}>Bản nháp (Ẩn)</option>
                {/* Hiển thị phần tử giao diện option và nội dung con của nó. */}
                <option value={1}>Sắp chiếu</option>
                {/* Hiển thị phần tử giao diện option và nội dung con của nó. */}
                <option value={2}>Đã phát hành</option>
              </select>
            </div>
            {editingId && (
              <div className="space-y-1 col-span-2 md:col-span-1">
                {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Trạng thái Video</label>
                {/* Hiển thị phần tử giao diện select và nội dung con của nó. */}
                <select
                  value={form.videoStatus}
                  onChange={(e) => setForm({ ...form, videoStatus: Number(e.target.value) })}
                  className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
                >
                  {/* Hiển thị phần tử giao diện option và nội dung con của nó. */}
                  <option value={0}>Chưa xử lý</option>
                  {/* Hiển thị phần tử giao diện option và nội dung con của nó. */}
                  <option value={1}>Sẵn sàng</option>
                  {/* Hiển thị phần tử giao diện option và nội dung con của nó. */}
                  <option value={2}>Lỗi</option>
                </select>
              </div>
            )}
          </div>

          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div className="space-y-2">
            {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
            <label className="text-slate-400 text-xs font-bold uppercase ml-1">Thể loại</label>
            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div className="flex flex-wrap gap-2">
              {categories.length === 0 ? (
                <p className="text-slate-600 text-sm italic">Chưa có thể loại nào. Hãy thêm thể loại trước.</p>
              ) : (
                categories.map((cat) => {
                  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
                  const selected = form.categoryIds.includes(cat.id);
                  // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
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

          {/* Tùy chọn Phim nổi bật (Banner Carousel) */}
          <div className="p-3.5 rounded-xl bg-slate-800/40 border border-slate-700/60 flex items-center justify-between gap-4">
            {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
            <div>
              {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
              <p className="text-sm font-bold text-white flex items-center gap-2">
                {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                <span>Đánh dấu là Phim nổi bật</span>
                {form.isFeatured && (
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">
                    Banner ON
                  </span>
                )}
              </p>
              {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
              <p className="text-xs text-slate-400 mt-0.5">
                Hiển thị phim này trên Banner Carousel trang chủ của ứng dụng mobile.
              </p>
            </div>
            {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
            <button
              type="button"
              onClick={() => setForm((prev) => ({ ...prev, isFeatured: !prev.isFeatured }))}
              className={`w-12 h-6 rounded-full transition-colors relative p-0.5 shrink-0 outline-none focus:ring-2 focus:ring-amber-500/50 ${
                form.isFeatured ? 'bg-amber-500' : 'bg-slate-700'
              }`}
            >
              {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
              <div
                className={`w-5 h-5 rounded-full bg-white transition-transform ${
                  form.isFeatured ? 'translate-x-6' : 'translate-x-0'
                }`}
              />
            </button>
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

      {/* Hiển thị phần tử giao diện ConfirmDialog và nội dung con của nó. */}
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

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default Movies;