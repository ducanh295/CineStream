import { useEffect, useRef, useState, useCallback } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Calendar, Clock3, Film, Loader2, Play, Tag, Video, X, Terminal, Trash2, Activity } from 'lucide-react';
import Hls from 'hls.js';
import movieApi from '../api/movieApi';

const MOVIE_TYPE_LABEL = { 0: 'Phim lẻ', 1: 'Phim bộ' };

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

  const addLog = useCallback((message, type = 'info') => {
    const time = new Date().toLocaleTimeString();
    setLogs((prev) => [
      { id: Date.now() + Math.random(), time, message, type },
      ...prev.slice(0, 199),
    ]);
  }, []);

  useEffect(() => {
    let active = true;

    const fetchMovie = async () => {
      setLoading(true);
      setErrorMsg('');
      try {
        const result = await movieApi.getById(id);
        if (!result?.success || !result?.data) {
          throw new Error(result?.message || 'Không tìm thấy phim.');
        }
        if (active) setMovie(result.data);
      } catch (err) {
        if (active) setErrorMsg(err.message || 'Không thể tải chi tiết phim.');
      } finally {
        if (active) setLoading(false);
      }
    };

    fetchMovie();
    return () => { active = false; };
  }, [id]);

  useEffect(() => {
    const video = videoRef.current;
    const streamUrl = playback?.streamUrl;
    if (!video || !streamUrl) return undefined;

    // Chuẩn hóa đường dẫn: nếu là đường dẫn tương đối thì ghép máy chủ Backend cổng 5182
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
        addLog(`HLS Manifest nạp thành công. Tìm thấy ${data.levels.length} tầng chất lượng (tối đa: ${data.levels[0]?.height || 'HD'}p).`, 'success');
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
        addLog(`Tải phân đoạn [${data.frag.sn ?? 'ts'}]: ${fragUrl} (Thời lượng: ${duration}s | Dung lượng: ${sizeText})`, 'segment');
      });

      hls.on(Hls.Events.LEVEL_SWITCHED, (event, data) => {
        addLog(`Tự động điều chỉnh bitrate phù hợp đường truyền: Tầng ${data.level}`, 'info');
      });

      hls.on(Hls.Events.ERROR, (event, data) => {
        if (data.fatal) {
          setStreamStatus('Lỗi phát luồng HLS');
          setStatusTone('error');
          setPlaybackError('Lỗi phát luồng HLS: ' + (data.details || 'Không thể giải mã manifest.'));
          addLog(`Lỗi nghiêm trọng: ${data.details}`, 'error');
        } else {
          addLog(`Cảnh báo luồng: ${data.details}`, 'warning');
        }
      });
    } else {
      video.src = finalUrl;
      const onLoadedMetadata = () => {
        setStreamStatus('Tải video trực tiếp thành công');
        setStatusTone('success');
        addLog(`Đã nạp metadata video: Thời lượng ${Math.round(video.duration)}s, độ phân giải ${video.videoWidth}x${video.videoHeight}.`, 'success');
        video.play().catch(() => {
          addLog('Bấm Play trên khung phát để bắt đầu xem video.', 'warning');
        });
      };
      const onError = () => {
        setStreamStatus('Lỗi tải video trực tiếp');
        setStatusTone('error');
        setPlaybackError('Không thể tải file video từ đường dẫn.');
        addLog('Không thể tải file video từ đường dẫn đã cung cấp.', 'error');
      };
      const onWaiting = () => {
        addLog('Đang chờ đệm dữ liệu video (Buffering)...', 'warning');
      };
      const onPlaying = () => {
        setStreamStatus('Đang phát nội dung');
        setStatusTone('playing');
      };

      video.addEventListener('loadedmetadata', onLoadedMetadata);
      video.addEventListener('error', onError);
      video.addEventListener('waiting', onWaiting);
      video.addEventListener('playing', onPlaying);

      return () => {
        video.removeEventListener('loadedmetadata', onLoadedMetadata);
        video.removeEventListener('error', onError);
        video.removeEventListener('waiting', onWaiting);
        video.removeEventListener('playing', onPlaying);
        video.removeAttribute('src');
        video.load();
      };
    }

    return () => {
      hls?.destroy();
      video.removeAttribute('src');
      video.load();
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

  const categories = movie.categories || [];

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
            </div>
            <h1 className="text-3xl lg:text-4xl font-bold text-white mt-4">{movie.title}</h1>
            <div className="mt-5 flex flex-wrap gap-x-5 gap-y-3 text-sm text-slate-400">
              <span className="flex items-center gap-2"><Calendar size={16} /> {movie.releaseYear || 'Chưa rõ năm'}</span>
              <span className="flex items-center gap-2"><Clock3 size={16} /> {movie.duration ? `${movie.duration} phút` : 'Chưa rõ thời lượng'}</span>
              <span className="flex items-center gap-2"><Video size={16} /> {movie.streamType || 'NONE'}</span>
            </div>
            <div className="mt-5 flex flex-wrap gap-2">
              {categories.length > 0 ? categories.map((category) => <span key={category.id} className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-slate-800 text-slate-300 text-sm"><Tag size={14} /> {category.name}</span>) : <span className="text-slate-500 text-sm">Chưa gán thể loại</span>}
            </div>
            <p className="mt-6 text-slate-300 leading-7 whitespace-pre-wrap">{movie.description || 'Phim chưa có mô tả.'}</p>
            <div className="mt-auto pt-8 flex flex-wrap gap-3">
              <button type="button" onClick={handlePlay} disabled={playbackLoading || !movie.videoUrl} className="bg-blue-600 hover:bg-blue-700 text-white px-5 py-3 rounded-xl flex items-center gap-2 font-bold transition-colors disabled:opacity-40 disabled:cursor-not-allowed">
                {playbackLoading ? <Loader2 className="animate-spin" size={18} /> : <Play size={18} />} Phát thử
              </button>
              {movie.trailerUrl && <a href={movie.trailerUrl} target="_blank" rel="noreferrer" className="bg-slate-800 hover:bg-slate-700 text-slate-200 px-5 py-3 rounded-xl flex items-center gap-2 font-bold transition-colors">Mở trailer</a>}
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

          {/* Bảng điều khiển Console Log thời gian thực tương tự player.html */}
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
    </div>
  );
};

export default MovieDetail;
