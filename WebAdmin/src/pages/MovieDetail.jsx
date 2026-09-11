import { useEffect, useRef, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Calendar, Clock3, Film, Loader2, Play, Tag, Video, X } from 'lucide-react';
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
  const videoRef = useRef(null);

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

    let hls;
    if (streamUrl.includes('.m3u8') && Hls.isSupported()) {
      hls = new Hls();
      hls.loadSource(streamUrl);
      hls.attachMedia(video);
    } else {
      video.src = streamUrl;
    }

    return () => {
      hls?.destroy();
      video.removeAttribute('src');
      video.load();
    };
  }, [playback]);

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
        <section className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <div className="flex items-center justify-between gap-4 mb-4"><div><h2 className="text-xl font-bold text-white">Phát thử nội dung</h2><p className="text-slate-500 text-sm mt-1">Loại stream: {playback.streamType}</p></div><button type="button" onClick={() => setPlayback(null)} className="p-2 rounded-lg text-slate-500 hover:text-white hover:bg-slate-800"><X size={18} /></button></div>
          {playback.streamUrl ? <video ref={videoRef} controls playsInline className="w-full max-h-140 rounded-xl bg-black">Trình duyệt không hỗ trợ phát video.</video> : <p className="text-slate-400">Backend chưa trả về đường dẫn stream cho phim này.</p>}
        </section>
      )}
    </div>
  );
};

export default MovieDetail;
