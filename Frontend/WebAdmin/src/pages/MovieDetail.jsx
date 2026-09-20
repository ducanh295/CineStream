import { useEffect, useRef, useState, useCallback } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Calendar, Clock3, Film, Loader2, Play, Tag, Video, X, Terminal, Trash2, Edit2, Layers } from 'lucide-react';
import Hls from 'hls.js';
import movieApi from '../api/movieApi';
import categoryApi from '../api/categoryApi';
import Modal from '../components/Modal';

const MOVIE_TYPE_LABEL = { 0: 'Phim lẻ', 1: 'Phim bộ' };

// Cấu hình hiển thị nhãn và màu sắc cho 3 trạng thái phát hành
const PUBLISH_STATUS_CONFIG = {
  0: { label: 'Bản nháp', color: 'bg-slate-800 text-slate-400 border-slate-700' },
  1: { label: 'Sắp chiếu', color: 'bg-blue-500/10 text-blue-400 border-blue-500/20' },
  2: { label: 'Đã phát hành', color: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' },
};

const MovieDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [movie, setMovie] = useState(null);
  const [playback, setPlayback] = useState(null);
  const [loading, setLoading] = useState(true);
  const [playbackLoading, setPlaybackLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [playbackError, setPlaybackError] = useState('');
  const [logs, setLogs] = useState([]);
  const [streamStatus, setStreamStatus] = useState('Sẵn sàng');
  const [statusTone, setStatusTone] = useState('idle');
  const videoRef = useRef(null);

  // Quản trị Modal chỉnh sửa phim trực tiếp tại trang chi tiết
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [editForm, setEditForm] = useState(null);
  const [editErrors, setEditErrors] = useState({});
  const [saving, setSaving] = useState(false);
  const [categories, setCategories] = useState([]);
  const [availableStreams, setAvailableStreams] = useState({ internalStreams: [], cdnPresets: [] });
  const [showHlsPicker, setShowHlsPicker] = useState(false);

  const addLog = useCallback((message, type = 'info') => {
    const time = new Date().toLocaleTimeString();
    setLogs((prev) => [
      { id: Date.now() + Math.random(), time, message, type },
      ...prev.slice(0, 199),
    ]);
  }, []);

  const fetchMovie = useCallback(async () => {
    setLoading(true);
    setErrorMsg('');
    try {
      const result = await movieApi.getById(id);
      if (!result?.success || !result?.data) {
        throw new Error(result?.message || 'Không tìm thấy phim.');
      }
      setMovie(result.data);
    } catch (err) {
      setErrorMsg(err.message || 'Không thể tải chi tiết phim.');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    fetchMovie();
  }, [fetchMovie]);

  // Tải danh mục thể loại và luồng HLS cho form sửa phim
  const loadFormData = async () => {
    try {
      const [catRes, streamRes] = await Promise.all([
        categoryApi.getAll(),
        movieApi.getAvailableStreams(),
      ]);
      if (catRes?.data) setCategories(Array.isArray(catRes.data) ? catRes.data : []);
      if (streamRes?.data) setAvailableStreams(streamRes.data);
    } catch {
      // Bỏ qua lỗi nạp dữ liệu phụ trợ
    }
  };

  const openEditModal = () => {
    if (!movie) return;
    setEditForm({
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
    setEditErrors({});
    setShowHlsPicker(false);
    setEditModalOpen(true);
    loadFormData();
  };

  const closeEditModal = () => {
    if (saving) return;
    setShowHlsPicker(false);
    setEditModalOpen(false);
  };

  const toggleCategory = (catId) => {
    if (!editForm) return;
    setEditForm((prev) => {
      const exists = prev.categoryIds.includes(catId);
      return {
        ...prev,
        categoryIds: exists
          ? prev.categoryIds.filter((c) => c !== catId)
          : [...prev.categoryIds, catId],
      };
    });
  };

  const handleSaveEdit = async (e) => {
    e.preventDefault();
    if (!editForm) return;

    if (!editForm.title.trim()) {
      setEditErrors({ title: 'Tiêu đề phim không được để trống!' });
      return;
    }

    setSaving(true);
    try {
      const payload = {
        title: editForm.title.trim(),
        description: editForm.description.trim() || null,
        posterUrl: editForm.posterUrl.trim() || null,
        videoUrl: editForm.videoUrl.trim() || null,
        trailerUrl: editForm.trailerUrl.trim() || null,
        duration: editForm.duration ? Number(editForm.duration) : null,
        releaseYear: editForm.releaseYear ? Number(editForm.releaseYear) : null,
        type: Number(editForm.type),
        videoStatus: Number(editForm.videoStatus),
        isFeatured: Boolean(editForm.isFeatured),
        publishStatus: Number(editForm.publishStatus),
        categoryIds: editForm.categoryIds,
      };

      await movieApi.update(id, payload);
      setEditModalOpen(false);
      await fetchMovie();
    } catch (err) {
      setEditErrors({ general: err.message || 'Không thể cập nhật phim!' });
    } finally {
      setSaving(false);
    }
  };

  useEffect(() => {
    const video = videoRef.current;
    const streamUrl = playback?.streamUrl;
    if (!video || !streamUrl) return undefined;

    let finalUrl = streamUrl;
    if (finalUrl.startsWith('/')) {
      finalUrl = 'http://localhost:5182' + finalUrl;
    }

    setLogs([]);
    setStreamStatus('Đang khởi tạo kết nối luồng...');
    setStatusTone('connecting');
    addLog(`Bắt đầu kết nối tới URL: ${finalUrl}`, 'info');

    let hls;
    if (finalUrl.includes('.m3u8') && Hls.isSupported()) {
      hls = new Hls({
        enableWorker: true,
        lowLatencyMode: false,
      });

      hls.loadSource(finalUrl);
      hls.attachMedia(video);

      hls.on(Hls.Events.MANIFEST_PARSED, (event, data) => {
        setStreamStatus(`HLS Manifest nạp thành công (${data.levels.length} tầng chất lượng)`);
        setStatusTone('success');
        addLog(`HLS Manifest nạp thành công. Tìm thấy ${data.levels.length} tầng chất lượng.`, 'success');
        video.play().catch(() => {
          addLog('Bấm Play trên khung phát để bắt đầu xem video.', 'warning');
        });
      });

      hls.on(Hls.Events.FRAG_LOADED, (event, data) => {
        const fragUrl = data.frag.relurl || data.frag.url;
        const duration = data.frag.duration?.toFixed(1) || '0.0';
        const bytes = data.stats?.loaded || data.frag?.stats?.loaded || data.frag?.loaded || 0;
        const sizeText = bytes > 0 ? `${(bytes / 1024).toFixed(1)} KB` : 'Chuẩn nén';
        setStreamStatus(`Đang phát phân đoạn ${data.frag.sn ?? ''}`);
        setStatusTone('playing');
        addLog(`Tải phân đoạn [${data.frag.sn ?? 'ts'}]: ${fragUrl} (${duration}s | ${sizeText})`, 'segment');
      });

      hls.on(Hls.Events.ERROR, (event, data) => {
        if (data.fatal) {
          setStatusTone('error');
          setStreamStatus(`Lỗi luồng: ${data.details}`);
          addLog(`Lỗi luồng nghiêm trọng: ${data.details}`, 'error');
        }
      });
    } else {
      video.src = finalUrl;
      video.onloadedmetadata = () => {
        setStreamStatus('Video MP4 đã nạp metadata thành công');
        setStatusTone('success');
        addLog(`Video MP4 nạp thành công. Thời lượng: ${video.duration?.toFixed(0)}s`, 'success');
        video.play().catch(() => {
          addLog('Bấm Play trên khung phát để bắt đầu xem video.', 'warning');
        });
      };
      video.onerror = () => {
        setStatusTone('error');
        setStreamStatus('Lỗi khi tải file video MP4');
        addLog(`Không thể tải video từ URL: ${finalUrl}`, 'error');
      };
    }

    return () => {
      if (hls) {
        hls.destroy();
      }
    };
  }, [playback, addLog]);

  const handlePlay = async () => {
    setPlaybackLoading(true);
    setPlaybackError('');
    try {
      const result = await movieApi.getPlayback(id);
      if (!result?.success || !result?.data) {
        throw new Error(result?.message || 'Không thể lấy thông tin phát phim.');
      }
      setPlayback(result.data);
    } catch (err) {
      setPlaybackError(err.message || 'Không thể phát thử phim.');
    } finally {
      setPlaybackLoading(false);
    }
  };

  if (loading) {
    return <div className="flex min-h-[60vh] items-center justify-center text-slate-500"><Loader2 className="animate-spin" size={34} /></div>;
  }

  if (errorMsg || !movie) {
    return (
      <div className="space-y-5">
        <button type="button" onClick={() => navigate(-1)} className="flex items-center gap-2 text-slate-400 hover:text-white transition-colors"><ArrowLeft size={18} /> Quay lại</button>
        <div className="bg-red-500/10 border border-red-500/20 text-red-400 rounded-2xl p-6">{errorMsg || 'Không tìm thấy phim.'}</div>
      </div>
    );
  }

  const categoriesList = movie.categories || [];

  return (
    <div className="space-y-6">
      <button type="button" onClick={() => navigate(-1)} className="flex items-center gap-2 text-slate-400 hover:text-white transition-colors"><ArrowLeft size={18} /> Quay lại danh sách</button>

      <section className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
        <div className="grid grid-cols-1 lg:grid-cols-[280px_1fr]">
          <div className="aspect-2/3 lg:aspect-auto bg-slate-800">
            {movie.posterUrl ? <img src={movie.posterUrl} alt={movie.title} className="w-full h-full object-cover" /> : <div className="h-full min-h-80 flex items-center justify-center text-slate-600"><Film size={64} /></div>}
          </div>
          <div className="p-6 lg:p-8 flex flex-col">
            <div className="flex flex-wrap items-center gap-2 text-xs font-bold uppercase tracking-wide">
              <span className="px-2.5 py-1 rounded-full bg-blue-500/10 text-blue-400 border border-blue-500/20">{MOVIE_TYPE_LABEL[movie.type] || 'Nội dung'}</span>
              <span className={`px-2.5 py-1 rounded-full border ${movie.videoStatus ? 'bg-green-500/10 text-green-400 border-green-500/20' : 'bg-slate-800 text-slate-400 border-slate-700'}`}>{movie.videoStatus ? 'Có video' : 'Chưa có video'}</span>
              
              {/* Badge Trạng thái phát hành */}
              <span className={`px-2.5 py-1 rounded-full border font-bold ${
                PUBLISH_STATUS_CONFIG[movie.publishStatus]?.color || PUBLISH_STATUS_CONFIG[2].color
              }`}>
                {PUBLISH_STATUS_CONFIG[movie.publishStatus]?.label || 'Đã phát hành'}
              </span>

              {movie.isFeatured && (
                <span className="px-2.5 py-1 rounded-full bg-amber-500/15 text-amber-400 border border-amber-500/30 font-bold">
                  Phim nổi bật Banner
                </span>
              )}
            </div>

            <h1 className="text-3xl lg:text-4xl font-bold text-white mt-4">{movie.title}</h1>
            
            <div className="mt-5 flex flex-wrap gap-x-5 gap-y-3 text-sm text-slate-400">
              <span className="flex items-center gap-2"><Calendar size={16} /> {movie.releaseYear || 'Chưa rõ năm'}</span>
              <span className="flex items-center gap-2"><Clock3 size={16} /> {movie.duration ? `${movie.duration} phút` : 'Chưa rõ thời lượng'}</span>
              <span className="flex items-center gap-2"><Video size={16} /> {movie.streamType || 'NONE'}</span>
            </div>
            
            <div className="mt-5 flex flex-wrap gap-2">
              {categoriesList.length > 0 ? categoriesList.map((category) => (
                <span key={category.id} className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-slate-800 text-slate-300 text-sm">
                  <Tag size={14} /> {category.name}
                </span>
              )) : <span className="text-slate-500 text-sm">Chưa gán thể loại</span>}
            </div>
            
            <p className="mt-6 text-slate-300 leading-7 whitespace-pre-wrap">{movie.description || 'Phim chưa có mô tả.'}</p>
            
            <div className="mt-auto pt-8 flex flex-wrap gap-3">
              <button
                type="button"
                onClick={openEditModal}
                className="bg-amber-600 hover:bg-amber-500 text-white px-5 py-3 rounded-xl flex items-center gap-2 font-bold transition-colors shadow-lg shadow-amber-600/20"
              >
                <Edit2 size={18} /> Chỉnh sửa phim
              </button>

              <button
                type="button"
                onClick={handlePlay}
                disabled={playbackLoading || !movie.videoUrl}
                className="bg-blue-600 hover:bg-blue-700 text-white px-5 py-3 rounded-xl flex items-center gap-2 font-bold transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
              >
                {playbackLoading ? <Loader2 className="animate-spin" size={18} /> : <Play size={18} />} Phát thử
              </button>

              {movie.trailerUrl && (
                <a href={movie.trailerUrl} target="_blank" rel="noreferrer" className="bg-slate-800 hover:bg-slate-700 text-slate-200 px-5 py-3 rounded-xl flex items-center gap-2 font-bold transition-colors">
                  Mở trailer
                </a>
              )}
            </div>

            {!movie.videoUrl && <p className="mt-3 text-amber-400 text-sm">Phim chưa có Video URL nên chưa thể phát thử.</p>}
          </div>
        </div>
      </section>

      {playbackError && <div className="bg-red-500/10 border border-red-500/20 text-red-400 rounded-xl p-4">{playbackError}</div>}

      {playback && (
        <section className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <div>
              <h2 className="text-xl font-bold text-white">Phát thử nội dung</h2>
              <div className="flex items-center gap-3 mt-1 text-sm text-slate-400">
                <span>Loại stream: <strong className="text-blue-400">{playback.streamType}</strong></span>
                <span>•</span>
                <span className="flex items-center gap-1.5">
                  <span className={`w-2 h-2 rounded-full ${
                    statusTone === 'playing' || statusTone === 'success'
                      ? 'bg-emerald-400 animate-pulse'
                      : statusTone === 'connecting'
                      ? 'bg-amber-400 animate-pulse'
                      : statusTone === 'error'
                      ? 'bg-rose-400'
                      : 'bg-slate-500'
                  }`} />
                  <span className={
                    statusTone === 'playing' || statusTone === 'success'
                      ? 'text-emerald-400'
                      : statusTone === 'connecting'
                      ? 'text-amber-400'
                      : statusTone === 'error'
                      ? 'text-rose-400'
                      : 'text-slate-400'
                  }>{streamStatus}</span>
                </span>
              </div>
            </div>
            <button
              type="button"
              onClick={() => setPlayback(null)}
              className="p-2 rounded-lg text-slate-500 hover:text-white hover:bg-slate-800 transition-colors"
              title="Đóng khung phát"
            >
              <X size={18} />
            </button>
          </div>

          {playback.streamUrl ? (
            <video ref={videoRef} controls playsInline className="w-full max-h-140 rounded-xl bg-black border border-slate-800">
              Trình duyệt không hỗ trợ phát video.
            </video>
          ) : (
            <p className="text-slate-400">Backend chưa trả về đường dẫn stream cho phim này.</p>
          )}

          {/* Bảng điều khiển Console Log thời gian thực */}
          <div className="bg-slate-950 border border-slate-800/80 rounded-xl p-4 shadow-inner">
            <div className="flex items-center justify-between gap-2 mb-3 pb-2.5 border-b border-slate-800/70">
              <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-slate-400">
                <Terminal size={15} className="text-blue-400" />
                <span>Nhật ký phân đoạn & render thời gian thực (Real-time Segment Log)</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-[11px] text-slate-500 font-mono">{logs.length} bản ghi</span>
                <button
                  type="button"
                  onClick={() => setLogs([])}
                  className="flex items-center gap-1 px-2.5 py-1 text-xs text-slate-400 hover:text-white hover:bg-slate-800 rounded-md transition-colors"
                  title="Xóa log"
                >
                  <Trash2 size={13} />
                  <span>Xóa</span>
                </button>
              </div>
            </div>

            <div className="font-mono text-xs text-slate-300 max-h-56 overflow-y-auto space-y-1 pr-1 select-text">
              {logs.length === 0 ? (
                <p className="text-slate-600 italic">Đang chờ sự kiện luồng phát...</p>
              ) : (
                logs.map((item) => (
                  <div key={item.id} className="leading-relaxed border-b border-slate-900/80 pb-1 flex items-start gap-2">
                    <span className="text-slate-500 shrink-0">[{item.time}]</span>
                    <span className={
                      item.type === 'segment' ? 'text-cyan-300' :
                      item.type === 'success' ? 'text-emerald-400 font-semibold' :
                      item.type === 'warning' ? 'text-amber-400' :
                      item.type === 'error' ? 'text-rose-400 font-semibold' :
                      'text-slate-300'
                    }>
                      {item.message}
                    </span>
                  </div>
                ))
              )}
            </div>
          </div>
        </section>
      )}

      {/* Modal Chỉnh sửa phim trực tiếp tại trang chi tiết */}
      <Modal
        open={editModalOpen}
        title="Chỉnh sửa thông tin phim"
        onClose={closeEditModal}
      >
        {editForm && (
          <form onSubmit={handleSaveEdit} className="space-y-4">
            {editErrors.general && (
              <div className="p-3 bg-red-500/10 border border-red-500/20 text-red-400 text-sm rounded-xl">
                {editErrors.general}
              </div>
            )}

            <div className="space-y-1">
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Tiêu đề phim *</label>
              <input
                type="text"
                value={editForm.title}
                onChange={(e) => setEditForm({ ...editForm, title: e.target.value })}
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              />
              {editErrors.title && <p className="text-red-400 text-xs ml-1">{editErrors.title}</p>}
            </div>

            <div className="space-y-1">
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Mô tả phim</label>
              <textarea
                rows={3}
                value={editForm.description}
                onChange={(e) => setEditForm({ ...editForm, description: e.target.value })}
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all resize-none"
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-1">
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Poster URL</label>
                <input
                  type="text"
                  value={editForm.posterUrl}
                  onChange={(e) => setEditForm({ ...editForm, posterUrl: e.target.value })}
                  className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all text-sm"
                />
              </div>
              <div className="space-y-1">
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Trailer URL (YouTube)</label>
                <input
                  type="text"
                  value={editForm.trailerUrl}
                  onChange={(e) => setEditForm({ ...editForm, trailerUrl: e.target.value })}
                  className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all text-sm"
                />
              </div>
            </div>

            {/* Video Stream URL kèm bộ chọn HLS nội bộ */}
            <div className="space-y-1">
              <div className="flex items-center justify-between">
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Đường dẫn Video Stream</label>
                <button
                  type="button"
                  onClick={() => setShowHlsPicker(!showHlsPicker)}
                  className="text-xs text-blue-400 hover:text-blue-300 flex items-center gap-1 font-semibold"
                >
                  <Layers size={13} />
                  <span>{showHlsPicker ? 'Ẩn kho HLS' : 'Chọn từ kho HLS nội bộ'}</span>
                </button>
              </div>

              {showHlsPicker && (
                <div className="p-3 bg-slate-950/80 border border-slate-800 rounded-xl space-y-2 mb-2">
                  <p className="text-xs text-slate-400 font-bold uppercase tracking-wider">Kho HLS nội bộ đã cắt</p>
                  <div className="space-y-1.5 max-h-40 overflow-y-auto pr-1">
                    {availableStreams.internalStreams.map((s) => (
                      <button
                        key={s.streamKey}
                        type="button"
                        onClick={() => {
                          setEditForm({ ...editForm, videoUrl: s.relativeUrl });
                          setShowHlsPicker(false);
                        }}
                        className="w-full p-2 rounded-lg bg-slate-900 hover:bg-slate-800 border border-slate-800 text-left text-xs text-slate-200 flex items-center justify-between"
                      >
                        <span className="font-mono text-blue-400">{s.relativeUrl}</span>
                        <span className="text-[10px] text-slate-400">{s.totalSizeMb} MB</span>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              <input
                type="text"
                value={editForm.videoUrl}
                onChange={(e) => setEditForm({ ...editForm, videoUrl: e.target.value })}
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all font-mono text-sm"
              />
            </div>

            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="space-y-1">
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Thời lượng (phút)</label>
                <input
                  type="number"
                  value={editForm.duration}
                  onChange={(e) => setEditForm({ ...editForm, duration: e.target.value })}
                  className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
                />
              </div>
              <div className="space-y-1">
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Năm phát hành</label>
                <input
                  type="number"
                  value={editForm.releaseYear}
                  onChange={(e) => setEditForm({ ...editForm, releaseYear: e.target.value })}
                  className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
                />
              </div>
              <div className="space-y-1 col-span-2 md:col-span-1">
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Loại phim</label>
                <select
                  value={editForm.type}
                  onChange={(e) => setEditForm({ ...editForm, type: Number(e.target.value) })}
                  className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
                >
                  <option value={0}>Phim lẻ</option>
                  <option value={1}>Phim bộ</option>
                </select>
              </div>
              <div className="space-y-1 col-span-2 md:col-span-1">
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Trạng thái phát hành</label>
                <select
                  value={editForm.publishStatus}
                  onChange={(e) => setEditForm({ ...editForm, publishStatus: Number(e.target.value) })}
                  className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all font-medium"
                >
                  <option value={0}>Bản nháp (Ẩn)</option>
                  <option value={1}>Sắp chiếu</option>
                  <option value={2}>Đã phát hành</option>
                </select>
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Thể loại</label>
              <div className="flex flex-wrap gap-2">
                {categories.map((cat) => {
                  const selected = editForm.categoryIds.includes(cat.id);
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
                })}
              </div>
            </div>

            <div className="p-3.5 rounded-xl bg-slate-800/40 border border-slate-700/60 flex items-center justify-between gap-4">
              <div>
                <p className="text-sm font-bold text-white flex items-center gap-2">
                  <span>Đánh dấu là Phim nổi bật</span>
                  {editForm.isFeatured && (
                    <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">
                      Banner ON
                    </span>
                  )}
                </p>
                <p className="text-xs text-slate-400 mt-0.5">
                  Hiển thị phim này trên Banner Carousel trang chủ của ứng dụng mobile.
                </p>
              </div>
              <button
                type="button"
                onClick={() => setEditForm((prev) => ({ ...prev, isFeatured: !prev.isFeatured }))}
                className={`w-12 h-6 rounded-full transition-colors relative p-0.5 shrink-0 outline-none ${
                  editForm.isFeatured ? 'bg-amber-500' : 'bg-slate-700'
                }`}
              >
                <div
                  className={`w-5 h-5 rounded-full bg-white transition-transform ${
                    editForm.isFeatured ? 'translate-x-6' : 'translate-x-0'
                  }`}
                />
              </button>
            </div>

            <div className="flex gap-3 pt-2">
              <button
                type="button"
                onClick={closeEditModal}
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
                {saving ? <Loader2 className="animate-spin" size={18} /> : 'Lưu thay đổi'}
              </button>
            </div>
          </form>
        )}
      </Modal>
    </div>
  );
};

export default MovieDetail;
