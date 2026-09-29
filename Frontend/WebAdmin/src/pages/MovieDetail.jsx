 
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

  //logic thêm log trạng thái luồng phát video và cập nhật giao diện người dùng. 
  const addLog = useCallback((message, type = 'info') => {
    // Cập nhật danh sách log với log mới, giữ nguyên các log trước đó và giới hạn tối đa 200 log. 
    const time = new Date().toLocaleTimeString(); 
    setLogs((prev) => [
      { id: Date.now() + Math.random(), time, message, type },
      ...prev.slice(0, 199),
    ]);
  }, []);

  //logic fetch chi tiết phim từ API và cập nhật trạng thái giao diện người dùng. 
  const fetchMovie = useCallback(async () => {
     
    setLoading(true);
     
    setErrorMsg('');
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Gọi API để lấy chi tiết phim theo id từ params và kiểm tra dữ liệu trả về. 
      const result = await movieApi.getById(id);
      // nếu dữ liệu trả về không thành công hoặc không có dữ liệu, phát sinh lỗi để thông báo trạng thái bất thường.
      if (!result?.success || !result?.data) {
        // Phát sinh lỗi để thông báo trạng thái bất thường.
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
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
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

  // logic mở Modal chỉnh sửa phim và tải dữ liệu vào form. 
  const openEditModal = () => {
     
    if (!movie) return;
    // đoạn này sẽ thiết lập dữ liệu hiện tại của phim vào form chỉnh sửa, đặt trạng thái lỗi về rỗng, ẩn trình chọn HLS, mở Modal và tải dữ liệu phụ trợ. 
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

  // logic đóng Modal chỉnh sửa phim và đặt trạng thái giao diện về mặc định. 
  const closeEditModal = () => {
     
    if (saving) return; 
    setShowHlsPicker(false);
     
    setEditModalOpen(false);
  };

  // logic cập nhật danh sách thể loại được chọn trong form chỉnh sửa phim và cập nhật giao diện người dùng. 
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

  // logic xử lý lưu chỉnh sửa phim và gọi API cập nhật dữ liệu, đồng thời cập nhật giao diện người dùng. 
  const handleSaveEdit = async (e) => {
     
    e.preventDefault();
     
    if (!editForm) return;

     
    if (!editForm.title.trim()) {
       
      setEditErrors({ title: 'Tiêu đề phim không được để trống!' });
       
      return;
    }

     
    setSaving(true);
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // đoạn này có nghĩa là tạo một đối tượng payload chứa dữ liệu phim đã được chỉnh sửa từ form, sau đó gọi API để cập nhật thông tin phim theo id. Nếu thành công, đóng Modal và tải lại chi tiết phim. Nếu có lỗi, hiển thị thông báo lỗi. 
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
    // logic phát thử phim bằng HLS hoặc MP4 và quản lý trạng thái luồng phát video, đồng thời cập nhật giao diện người dùng. 
    const video = videoRef.current;
    // dòng này nghĩa là lấy URL của luồng video từ đối tượng playback. Nếu không có video hoặc URL luồng trống, trả về undefined và không thực hiện phát thử.
    const streamUrl = playback?.streamUrl;
    // nếu không có video hoặc URL luồng trống, trả về undefined và không thực hiện phát thử.
    if (!video || !streamUrl) return undefined;

    // logic xác định URL cuối cùng để phát thử phim, nếu URL bắt đầu bằng '/', thêm tiền tố 'http://localhost:5182' để tạo URL đầy đủ. 
    let finalUrl = streamUrl;
    if (finalUrl.startsWith('/')) {
       
      finalUrl = 'http://localhost:5182' + finalUrl;
    }

     
    setLogs([]);
     
    setStreamStatus('Đang khởi tạo kết nối luồng...');
     
    setStatusTone('connecting');
     
    addLog(`Bắt đầu kết nối tới URL: ${finalUrl}`, 'info');

    //let hls là biến để lưu trữ đối tượng Hls nếu sử dụng HLS để phát thử phim. 
    let hls;
    //Nếu URL kết thúc bằng '.m3u8' và Hls được hỗ trợ, sử dụng HLS để phát thử phim. Nếu không, sử dụng thẻ video HTML5 để phát thử phim MP4.
    if (finalUrl.includes('.m3u8') && Hls.isSupported()) {
       
      hls = new Hls({
        enableWorker: true,
        lowLatencyMode: false,
      });

      // Gắn URL luồng HLS vào đối tượng Hls và gắn thẻ video HTML5 để phát thử phim. 
      hls.loadSource(finalUrl);
      // Gắn thẻ video HTML5 để phát thử phim. 
      hls.attachMedia(video);

      // Đăng ký các sự kiện của Hls để quản lý trạng thái luồng phát video và cập nhật giao diện người dùng. 
      hls.on(Hls.Events.MANIFEST_PARSED, (event, data) => {
        // Cập nhật trạng thái luồng phát video và hiển thị thông báo thành công khi nạp manifest HLS thành công. 
        setStreamStatus(`HLS Manifest nạp thành công (${data.levels.length} tầng chất lượng)`);
        // Cập nhật trạng thái hiển thị màu sắc cho giao diện người dùng khi nạp manifest HLS thành công. 
        setStatusTone('success');
        // Thêm log thông báo nạp manifest HLS thành công và số lượng tầng chất lượng tìm thấy. 
        addLog(`HLS Manifest nạp thành công. Tìm thấy ${data.levels.length} tầng chất lượng.`, 'success');
        // Thử phát video tự động khi manifest HLS đã nạp thành công. Nếu không thể phát tự động, hiển thị thông báo yêu cầu người dùng bấm Play trên khung phát. 
        video.play().catch(() => {
          // Thêm log thông báo yêu cầu người dùng bấm Play trên khung phát để bắt đầu xem video. 
          addLog('Bấm Play trên khung phát để bắt đầu xem video.', 'warning');
        });
      });

      // khai báo các sự kiện khác của Hls để quản lý trạng thái luồng phát video và cập nhật giao diện người dùng.
      hls.on(Hls.Events.FRAG_LOADED, (event, data) => {
        // sự kiện này được gọi khi một phân đoạn HLS đã được tải thành công. Cập nhật trạng thái luồng phát video và hiển thị thông báo về phân đoạn đã tải. 
        const fragUrl = data.frag.relurl || data.frag.url;
        // lấy thời lượng phân đoạn và kích thước dữ liệu đã tải để hiển thị thông tin chi tiết về phân đoạn. Nếu không có dữ liệu, đặt giá trị mặc định. 
        const duration = data.frag.duration?.toFixed(1) || '0.0';
        // tính toán kích thước dữ liệu đã tải từ các thuộc tính stats của đối tượng data. Nếu không có dữ liệu, đặt giá trị mặc định là 0. 
        const bytes = data.stats?.loaded || data.frag?.stats?.loaded || data.frag?.loaded || 0;
        // chuyển đổi kích thước dữ liệu từ byte sang KB và hiển thị với 1 chữ số thập phân. Nếu không có dữ liệu, hiển thị 'Chuẩn nén'. 
        const sizeText = bytes > 0 ? `${(bytes / 1024).toFixed(1)} KB` : 'Chuẩn nén';
        // Cập nhật trạng thái luồng phát video và hiển thị thông báo về phân đoạn đã tải, bao gồm số thứ tự phân đoạn, URL phân đoạn, thời lượng và kích thước dữ liệu. 
        setStreamStatus(`Đang phát phân đoạn ${data.frag.sn ?? ''}`);
         
        setStatusTone('playing');
        // Thêm log thông báo về phân đoạn HLS đã tải thành công, bao gồm số thứ tự phân đoạn, URL phân đoạn, thời lượng và kích thước dữ liệu. 
        addLog(`Tải phân đoạn [${data.frag.sn ?? 'ts'}]: ${fragUrl} (${duration}s | ${sizeText})`, 'segment');
      });

      // còn dòng này nghĩa là đăng ký sự kiện lỗi của Hls để quản lý trạng thái luồng phát video và cập nhật giao diện người dùng khi xảy ra lỗi nghiêm trọng. Nếu có lỗi nghiêm trọng, hiển thị thông báo lỗi và thêm log chi tiết về lỗi. 
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

  //logic xử lý phát thử phim bằng cách gọi API lấy thông tin luồng phát và cập nhật trạng thái giao diện người dùng. 
  const handlePlay = async () => {
    // đặt trạng thái loading luồng phát và xóa thông báo lỗi luồng trước đó. 
    setPlaybackLoading(true);
     
    setPlaybackError('');
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Gọi API để lấy thông tin luồng phát phim theo id và kiểm tra dữ liệu trả về. 
      const result = await movieApi.getPlayback(id);
       
      if (!result?.success || !result?.data) {
        // Phát sinh lỗi để thông báo trạng thái bất thường.
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

  //nếu có lỗi hoặc không tìm thấy phim, hiển thị thông báo lỗi và nút quay lại danh sách phim.
  if (errorMsg || !movie) {
     
    return (
      <div className="space-y-5">
        {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
        <button type="button" onClick={() => navigate(-1)} className="flex items-center gap-2 text-slate-400 hover:text-white transition-colors"><ArrowLeft size={18} /> Quay lại</button>
         
        <div className="bg-red-500/10 border border-red-500/20 text-red-400 rounded-2xl p-6">{errorMsg || 'Không tìm thấy phim.'}</div>
      </div>
    );
  }

  //logic lấy danh sách thể loại của phim từ dữ liệu chi tiết phim và đặt mặc định là mảng rỗng nếu không có dữ liệu. 
  const categoriesList = movie.categories || [];

   
  return (
    <div className="space-y-6">
      {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
      <button type="button" onClick={() => navigate(-1)} className="flex items-center gap-2 text-slate-400 hover:text-white transition-colors"><ArrowLeft size={18} /> Quay lại danh sách</button>

      {/* Hiển thị phần tử giao diện section và nội dung con của nó. */}
      <section className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
         
        <div className="grid grid-cols-1 lg:grid-cols-[280px_1fr]">
           
          <div className="aspect-2/3 lg:aspect-auto bg-slate-800">
            {movie.posterUrl ? <img src={movie.posterUrl} alt={movie.title} className="w-full h-full object-cover" /> : <div className="h-full min-h-80 flex items-center justify-center text-slate-600"><Film size={64} /></div>}
          </div>
           
          <div className="p-6 lg:p-8 flex flex-col">
             
            <div className="flex flex-wrap items-center gap-2 text-xs font-bold uppercase tracking-wide">
              {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
              <span className="px-2.5 py-1 rounded-full bg-blue-500/10 text-blue-400 border border-blue-500/20">{MOVIE_TYPE_LABEL[movie.type] || 'Nội dung'}</span>
              {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
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
              {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
              <span className="flex items-center gap-2"><Calendar size={16} /> {movie.releaseYear || 'Chưa rõ năm'}</span>
              {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
              <span className="flex items-center gap-2"><Clock3 size={16} /> {movie.duration ? `${movie.duration} phút` : 'Chưa rõ thời lượng'}</span>
              {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
              <span className="flex items-center gap-2"><Video size={16} /> {movie.streamType || 'NONE'}</span>
            </div>
            
             
            <div className="mt-5 flex flex-wrap gap-2">
              {categoriesList.length > 0 ? categoriesList.map((category) => (
                <span key={category.id} className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-slate-800 text-slate-300 text-sm">
                  {/* Hiển thị phần tử giao diện Tag và nội dung con của nó. */}
                  <Tag size={14} /> {category.name}
                </span>
              )) : <span className="text-slate-500 text-sm">Chưa gán thể loại</span>}
            </div>
            
             
            <p className="mt-6 text-slate-300 leading-7 whitespace-pre-wrap">{movie.description || 'Phim chưa có mô tả.'}</p>
            
             
            <div className="mt-auto pt-8 flex flex-wrap gap-3">
              {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
              <button
                type="button"
                onClick={openEditModal}
                className="bg-amber-600 hover:bg-amber-500 text-white px-5 py-3 rounded-xl flex items-center gap-2 font-bold transition-colors shadow-lg shadow-amber-600/20"
              >
                {/* Hiển thị phần tử giao diện Edit2 và nội dung con của nó. */}
                <Edit2 size={18} /> Chỉnh sửa phim
              </button>

              {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
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
                {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                <span>Loại stream: <strong className="text-blue-400">{playback.streamType}</strong></span>
                {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                <span>•</span>
                {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                <span className="flex items-center gap-1.5">
                  {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                  <span className={`w-2 h-2 rounded-full ${
                    statusTone === 'playing' || statusTone === 'success'
                      ? 'bg-emerald-400 animate-pulse'
                      : statusTone === 'connecting'
                      ? 'bg-amber-400 animate-pulse'
                      : statusTone === 'error'
                      ? 'bg-rose-400'
                      : 'bg-slate-500'
                  }`} />
                  {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
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
            {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
            <button
              type="button"
              onClick={() => setPlayback(null)}
              className="p-2 rounded-lg text-slate-500 hover:text-white hover:bg-slate-800 transition-colors"
              title="Đóng khung phát"
            >
              {/* Hiển thị phần tử giao diện X và nội dung con của nó. */}
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
                {/* Hiển thị phần tử giao diện Terminal và nội dung con của nó. */}
                <Terminal size={15} className="text-blue-400" />
                {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                <span>Nhật ký phân đoạn & render thời gian thực (Real-time Segment Log)</span>
              </div>
               
              <div className="flex items-center gap-2">
                {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                <span className="text-[11px] text-slate-500 font-mono">{logs.length} bản ghi</span>
                {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
                <button
                  type="button"
                  onClick={() => setLogs([])}
                  className="flex items-center gap-1 px-2.5 py-1 text-xs text-slate-400 hover:text-white hover:bg-slate-800 rounded-md transition-colors"
                  title="Xóa log"
                >
                  {/* Hiển thị phần tử giao diện Trash2 và nội dung con của nó. */}
                  <Trash2 size={13} />
                  {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
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
                    {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                    <span className="text-slate-500 shrink-0">[{item.time}]</span>
                    {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
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
              {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Tiêu đề phim *</label>
              {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
              <input
                type="text"
                value={editForm.title}
                onChange={(e) => setEditForm({ ...editForm, title: e.target.value })}
                className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              />
              {editErrors.title && <p className="text-red-400 text-xs ml-1">{editErrors.title}</p>}
            </div>

             
            <div className="space-y-1">
              {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
              <label className="text-slate-400 text-xs font-bold uppercase ml-1">Mô tả phim</label>
              {/* Hiển thị phần tử giao diện textarea và nội dung con của nó. */}
              <textarea
                rows={3}
                value={editForm.description}
                onChange={(e) => setEditForm({ ...editForm, description: e.target.value })}
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
                  value={editForm.posterUrl}
                  onChange={(e) => setEditForm({ ...editForm, posterUrl: e.target.value })}
                  className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all text-sm"
                />
              </div>
               
              <div className="space-y-1">
                {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Trailer URL (YouTube)</label>
                {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
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
                {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Đường dẫn Video Stream</label>
                {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
                <button
                  type="button"
                  onClick={() => setShowHlsPicker(!showHlsPicker)}
                  className="text-xs text-blue-400 hover:text-blue-300 flex items-center gap-1 font-semibold"
                >
                  {/* Hiển thị phần tử giao diện Layers và nội dung con của nó. */}
                  <Layers size={13} />
                  {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
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
                        {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                        <span className="font-mono text-blue-400">{s.relativeUrl}</span>
                        {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                        <span className="text-[10px] text-slate-400">{s.totalSizeMb} MB</span>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
              <input
                type="text"
                value={editForm.videoUrl}
                onChange={(e) => setEditForm({ ...editForm, videoUrl: e.target.value })}
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
                  value={editForm.duration}
                  onChange={(e) => setEditForm({ ...editForm, duration: e.target.value })}
                  className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
                />
              </div>
               
              <div className="space-y-1">
                {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Năm phát hành</label>
                {/* Hiển thị phần tử giao diện input và nội dung con của nó. */}
                <input
                  type="number"
                  value={editForm.releaseYear}
                  onChange={(e) => setEditForm({ ...editForm, releaseYear: e.target.value })}
                  className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
                />
              </div>
               
              <div className="space-y-1 col-span-2 md:col-span-1">
                {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
                <label className="text-slate-400 text-xs font-bold uppercase ml-1">Loại phim</label>
                {/* Hiển thị phần tử giao diện select và nội dung con của nó. */}
                <select
                  value={editForm.type}
                  onChange={(e) => setEditForm({ ...editForm, type: Number(e.target.value) })}
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
                  value={editForm.publishStatus}
                  onChange={(e) => setEditForm({ ...editForm, publishStatus: Number(e.target.value) })}
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
            </div>

             
            <div className="space-y-2">
              {/* Hiển thị phần tử giao diện label và nội dung con của nó. */}
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
                  {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
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
              {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
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
              {/* Hiển thị phần tử giao diện button và nội dung con của nó. */}
              <button
                type="button"
                onClick={closeEditModal}
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
                {saving ? <Loader2 className="animate-spin" size={18} /> : 'Lưu thay đổi'}
              </button>
            </div>
          </form>
        )}
      </Modal>
    </div>
  );
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default MovieDetail;
