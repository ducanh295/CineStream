 
import { useState, useEffect, useCallback } from 'react';
 
import { motion } from 'framer-motion';
 
import { Plus, Search, Edit2, Trash2, PlayCircle, Loader2, Film, X, Layers, Star, ChevronLeft, ChevronRight } from 'lucide-react';
 
import { Link } from 'react-router-dom';
 
import movieApi from '../api/movieApi';
 
import categoryApi from '../api/categoryApi';
 
import Modal from '../components/Modal';
 
import ConfirmDialog from '../components/ConfirmDialog';

// Định nghĩa một đối tượng EMPTY_FORM để lưu trữ giá trị mặc định của biểu mẫu thêm/sửa phim. 
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

 
const Movies = () => {
   
  const [movies, setMovies] = useState([]);
   
  const [categories, setCategories] = useState([]);
   
  const [loading, setLoading] = useState(true);
   
  const [errorMsg, setErrorMsg] = useState('');
   
  const [search, setSearch] = useState('');

  // Trạng thái phân trang danh sách phim
  const [page, setPage] = useState(1);
   
  const [pageSize, setPageSize] = useState(10);
   
  const [totalPages, setTotalPages] = useState(1);
   
  const [totalCount, setTotalCount] = useState(0);

   
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

  // Tải danh sách phim phân trang từ máy chủ Backend
  const fetchMovies = useCallback(async (pageNumber = 1, searchTerm = '', size = 10) => {
     
    setLoading(true);
     
    setErrorMsg('');
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // khai báo một đối tượng params để lưu trữ các tham số truy vấn cho API getAll, bao gồm số trang, kích thước trang và trạng thái bản nháp. 
      const params = {
        page: pageNumber,
        pageSize: size,
        includeDraft: true,
      };
      // nếu searchTerm không rỗng, thêm tham số tìm kiếm vào params để lọc danh sách phim theo từ khóa.
      if (searchTerm.trim()) params.search = searchTerm.trim();
       
      const result = await movieApi.getAll(params);
       
      const movieData = result?.data;
       
      const items = Array.isArray(movieData) ? movieData : movieData?.items || [];
       
      setMovies(items);
      // Cập nhật trạng thái phân trang dựa trên dữ liệu trả về từ API, bao gồm tổng số trang
      setTotalPages(movieData?.totalPages || 1);
      // Cập nhật tổng số phim dựa trên dữ liệu trả về từ API, nếu không có dữ liệu, đặt mặc định là 0. 
      setTotalCount(movieData?.totalCount || items.length);
      // Cập nhật số trang hiện tại dựa trên dữ liệu trả về từ API, nếu không có dữ liệu, giữ nguyên giá trị hiện tại. 
      setPage(movieData?.pageNumber || pageNumber);
    } catch (err) {
       
      setErrorMsg(err.message || 'Không thể tải danh sách phim. Vui lòng thử lại!');
    } finally {
       
      setLoading(false);
    }
  }, []);

  // Tải danh sách thể loại phim từ máy chủ Backend 
  const fetchCategories = useCallback(async () => {
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
       
      const result = await categoryApi.getAll();
      // set categories dựa trên dữ liệu trả về từ API, nếu dữ liệu không phải là mảng, đặt mặc định là mảng rỗng. 
      setCategories(Array.isArray(result?.data) ? result.data : []);
    } catch {
      // Không chặn trang nếu lỗi lấy category, chỉ ảnh hưởng form thêm/sửa
    }
  }, []);

  // Tải danh sách luồng phát có sẵn từ máy chủ Backend (bao gồm luồng nội bộ và preset CDN) 
  const fetchAvailableStreams = useCallback(async () => {
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Gọi API để lấy danh sách luồng phát có sẵn từ máy chủ Backend và kiểm tra dữ liệu trả về. 
      const result = await movieApi.getAvailableStreams();
       
      if (result?.data) {
         
        setAvailableStreams(result.data);
      }
    } catch {
      // Không chặn trang nếu không tải được danh sách luồng phát có sẵn
    }
  }, []);

   
  useEffect(() => {
     
    fetchCategories();
     
    fetchAvailableStreams();
  }, [fetchCategories, fetchAvailableStreams]);

  // Tự động tải lại danh sách phim theo trang, từ khóa tìm kiếm và kích thước trang
  useEffect(() => {
     
    const timer = setTimeout(() => {
       
      fetchMovies(page, search, pageSize);
    }, 300);
     
    return () => clearTimeout(timer);
  }, [page, search, pageSize, fetchMovies]);

   
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
      isFeatured: Boolean(movie.isFeatured),
      publishStatus: movie.publishStatus ?? 2,
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
          isFeatured: detail.isFeatured ?? prev.isFeatured,
          publishStatus: detail.publishStatus ?? prev.publishStatus,
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

  // Chuyển đổi trạng thái chọn / bỏ chọn thể loại phim trong biểu mẫu thêm/sửa 
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

  // Hàm validateForm kiểm tra tính hợp lệ của dữ liệu trong biểu mẫu thêm/sửa phim trước khi gửi lên máy chủ. Nó kiểm tra các trường bắt buộc, độ dài ký tự và phạm vi giá trị, sau đó lưu trữ các lỗi vào trạng thái formErrors để hiển thị thông báo lỗi cho người dùng. Nếu không có lỗi nào, hàm trả về true, ngược lại trả về false. 
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

  // Hàm handleSubmit xử lý sự kiện gửi biểu mẫu thêm/sửa phim. Nó ngăn chặn hành vi mặc định của form, kiểm tra tính hợp lệ của dữ liệu bằng validateForm, sau đó gửi dữ liệu lên máy chủ thông qua API movieApi. Nếu đang chỉnh sửa, nó gọi API cập nhật, nếu là thêm mới, nó gọi API tạo phim mới. Sau khi thành công, nó đóng modal và tải lại danh sách phim. Nếu có lỗi xảy ra, nó lưu trữ thông báo lỗi vào trạng thái formErrors để hiển thị cho người dùng. 
  const handleSubmit = async (e) => {
     
    e.preventDefault();
     
    if (!validateForm()) return;

     
    setSaving(true);
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
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
        isFeatured: Boolean(form.isFeatured),
        publishStatus: Number(form.publishStatus),
        categoryIds: form.categoryIds,
      };

       
      if (editingId) {
         
        payload.videoStatus = Number(form.videoStatus);
         
        await movieApi.update(editingId, payload);
      } else {
         
        await movieApi.create(payload);
      }

       
      setModalOpen(false);
       
      await fetchMovies(page, search, pageSize);
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

  // Hàm handleDelete xử lý việc xóa phim. Nó kiểm tra xem có phim nào được chọn để xóa hay không, sau đó gọi API movieApi để xóa phim dựa trên ID của phim đó. Nếu xóa thành công, nó cập nhật lại danh sách phim và điều chỉnh trang hiện tại nếu cần thiết. Nếu có lỗi xảy ra trong quá trình xóa, nó lưu trữ thông báo lỗi vào trạng thái errorMsg để hiển thị cho người dùng 
  const handleDelete = async () => {
     
    if (!deleteTarget) return;
     
    setDeleting(true);
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
       
      await movieApi.delete(deleteTarget.id);
       
      setDeleteTarget(null);
       
      const targetPage = movies.length === 1 && page > 1 ? page - 1 : page;
       
      setPage(targetPage);
       
      await fetchMovies(targetPage, search, pageSize);
    } catch (err) {
       
      setErrorMsg(err.message || 'Xóa phim thất bại!');
       
      setDeleteTarget(null);
    } finally {
       
      setDeleting(false);
    }
  };

  // Chuyển đổi nhanh trạng thái phim nổi bật (Bật / Tắt trực tiếp trên từng dòng bảng)
  const handleToggleFeatured = async (movie) => {
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
       
      await movieApi.toggleFeatured(movie.id);
       
      setMovies((prev) =>
        prev.map((m) => (m.id === movie.id ? { ...m, isFeatured: !m.isFeatured } : m))
      );
    } catch (err) {
       
      setErrorMsg(err.message || 'Không thể thay đổi trạng thái phim nổi bật!');
    }
  };

   
  return (
    <div className="space-y-6">
       
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
         
        <div>
           
          <h1 className="text-3xl font-bold text-white">Quản lý nội dung</h1>
           
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

       
      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
         
        <div className="p-4 border-b border-slate-800 flex flex-col md:flex-row gap-4 bg-slate-900/50">
           
          <div className="relative flex-1">
            {/* Hiển thị phần tử giao diện Search và nội dung con của nó. */}
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
            {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
            <input
              type="text"
              value={search}
              onChange={(e) => {
                 
                setSearch(e.target.value);
                 
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
             
            <Loader2 className="animate-spin mb-3" size={32} />
             
            <p>Đang tải danh sách phim...</p>
          </div>
        ) : movies.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-slate-500">
            {/* Hiển thị phần tử giao diện Film và nội dung con của nó. */}
            <Film size={40} className="mb-3 opacity-50" />
             
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
                         
                        <div className="w-12 h-16 bg-slate-800 rounded-lg flex items-center justify-center border border-slate-700 group-hover:border-blue-500 transition-all overflow-hidden relative shrink-0">
                          {movie.posterUrl ? (
                            <img src={movie.posterUrl} alt={movie.title} className="w-full h-full object-cover" />
                          ) : (
                            <PlayCircle className="text-white/20" />
                          )}
                        </div>
                         
                        <div>
                           
                          <div className="flex items-center gap-2 flex-wrap">
                             
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
                     
                    const newSize = Number(e.target.value);
                     
                    setPageSize(newSize);
                     
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

               
              <div className="flex items-center gap-1 px-1">
                {Array.from({ length: totalPages }, (_, i) => i + 1)
                  .filter((p) => p === 1 || p === totalPages || Math.abs(p - page) <= 1)
                  .map((p, idx, arr) => {
                     
                    const prevP = arr[idx - 1];
                     
                    const showEllipsis = prevP && p - prevP > 1;
                     
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

           
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
             
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

           
          <div className="space-y-2">
             
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

           
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
             
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

           
          <div className="space-y-2">
            {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
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

          {/* Tùy chọn Phim nổi bật (Banner Carousel) */}
          <div className="p-3.5 rounded-xl bg-slate-800/40 border border-slate-700/60 flex items-center justify-between gap-4">
             
            <div>
               
              <p className="text-sm font-bold text-white flex items-center gap-2">
                {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                <span>Đánh dấu là Phim nổi bật</span>
                {form.isFeatured && (
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">
                    Banner ON
                  </span>
                )}
              </p>
               
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
               
              <div
                className={`w-5 h-5 rounded-full bg-white transition-transform ${
                  form.isFeatured ? 'translate-x-6' : 'translate-x-0'
                }`}
              />
            </button>
          </div>

           
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