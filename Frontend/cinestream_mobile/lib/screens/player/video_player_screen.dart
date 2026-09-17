import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../models/movie.dart';
import '../../services/movie_service.dart';
import '../../widgets/app_drawer.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Movie? movie;

  const VideoPlayerScreen({
    super.key,
    this.movie,
  });

  @override
  State<VideoPlayerScreen> createState() =>
      _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final MovieService _movieService = MovieService.instance;

  Movie? _movie;
  MoviePlayback? _playback;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  bool _isLoading = true;
  bool _isInitializingVideo = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _movie = widget.movie;
    _loadPlayback();
  }

  Future<void> _loadPlayback() async {
    final movie = widget.movie;

    if (movie == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Không tìm thấy thông tin bộ phim.';
      });

      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _isInitializingVideo = false;
        _errorMessage = null;
        _playback = null;
      });
    }

    await _disposeVideoControllers();

    try {
      final playback = await _movieService.getPlayback(movie.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _playback = playback;
        _isLoading = false;
      });

      final streamUrl = playback.streamUrl?.trim();

      if (playback.videoStatus != 1 ||
          streamUrl == null ||
          streamUrl.isEmpty) {
        return;
      }

      await _initializeVideo(streamUrl);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isInitializingVideo = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  Future<void> _initializeVideo(String streamUrl) async {
    if (streamUrl.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _isInitializingVideo = true;
        _errorMessage = null;
      });
    }

    try {
      // Chuẩn hóa đường dẫn: nếu là đường dẫn tương đối thì ghép địa chỉ máy chủ Backend
      var resolvedUrl = streamUrl.trim();
      if (resolvedUrl.startsWith('/')) {
        resolvedUrl = 'http://localhost:5182$resolvedUrl';
      }

      final uri = Uri.tryParse(resolvedUrl);

      if (uri == null ||
          !uri.hasScheme ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw Exception('URL video không hợp lệ.');
      }

      final controller = VideoPlayerController.networkUrl(uri);

      _videoPlayerController = controller;

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      final aspectRatio = controller.value.aspectRatio > 0
          ? controller.value.aspectRatio
          : 16 / 9;

      final chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        showOptions: true,
        allowPlaybackSpeedChanging: true,
        aspectRatio: aspectRatio,

        deviceOrientationsOnEnterFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],

        deviceOrientationsAfterFullScreen: const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],

        placeholder: _buildVideoPlaceholder(),

        errorBuilder: (context, errorMessage) {
          return _buildVideoError(errorMessage);
        },
      );

      _chewieController = chewieController;

      if (mounted) {
        setState(() {
          _isInitializingVideo = false;
        });
      }
    } catch (e) {
      await _disposeVideoControllers();

      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializingVideo = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  Future<void> _disposeVideoControllers() async {
    final chewie = _chewieController;
    final video = _videoPlayerController;

    _chewieController = null;
    _videoPlayerController = null;

    chewie?.dispose();

    if (video != null) {
      await video.dispose();
    }
  }

  String _cleanErrorMessage(Object error) {
    final text = error.toString();

    return text
        .replaceFirst('Exception: ', '')
        .replaceFirst('PlatformException(', '')
        .trim();
  }

  @override
  void dispose() {
    _restorePortraitOrientation();

    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    _chewieController = null;
    _videoPlayerController = null;

    super.dispose();
  }

  Future<void> _restorePortraitOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (_) {
      // Web có thể không hỗ trợ đầy đủ orientation API.
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = _movie;

    return Scaffold(
      backgroundColor: const Color(0xFF101512),
      drawerScrimColor: Colors.black.withValues(alpha: 0.58),
      drawer: const AppDrawer(
        currentRoute: null,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlayerArea(),
              if (movie != null) ...[
                _buildMovieHeader(movie),
                _buildDescription(movie),
                _buildTechnicalInfo(),
              ],
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerArea() {
    final controller = _chewieController;

    if (_isLoading) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildLoadingView(
          message: 'Đang lấy thông tin phát...',
        ),
      );
    }

    if (_errorMessage != null && controller == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildVideoError(_errorMessage!),
      );
    }

    if (_playback == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildVideoError(
          'Không có dữ liệu phát.',
        ),
      );
    }

    final streamUrl = _playback!.streamUrl?.trim();

    if (_playback!.videoStatus != 1 ||
        streamUrl == null ||
        streamUrl.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildVideoNotReady(),
      );
    }

    if (_isInitializingVideo || controller == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildLoadingView(
          message: 'Đang khởi tạo video...',
        ),
      );
    }

    final aspectRatio =
        controller.videoPlayerController.value.aspectRatio > 0
            ? controller.videoPlayerController.value.aspectRatio
            : 16 / 9;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Chewie(
        controller: controller,
      ),
    );
  }

  Widget _buildLoadingView({
    required String message,
  }) {
    return Container(
      color: const Color(0xFF0D100E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    final posterUrl = _movie?.posterUrl;

    if (posterUrl == null || posterUrl.isEmpty) {
      return Container(
        color: const Color(0xFF0D100E),
        child: const Center(
          child: Icon(
            Icons.movie_outlined,
            color: Colors.white24,
            size: 70,
          ),
        ),
      );
    }

    return Image.network(
      posterUrl,
      fit: BoxFit.cover,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return Container(
          color: const Color(0xFF0D100E),
          child: const Center(
            child: Icon(
              Icons.movie_outlined,
              color: Colors.white24,
              size: 70,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoError(String message) {
    return Container(
      color: const Color(0xFF0D100E),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white70,
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _loadPlayback,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(
                  color: Colors.white54,
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoNotReady() {
    return Container(
      color: const Color(0xFF0D100E),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              color: Colors.white70,
              size: 52,
            ),
            SizedBox(height: 12),
            Text(
              'Video chưa sẵn sàng phát.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieHeader(Movie movie) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movie.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              height: 1.12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _movieInfo(movie),
            style: const TextStyle(
              color: Color(0xFFB8C0BA),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _movieInfo(Movie movie) {
    final parts = <String>[];

    if (movie.releaseYear != null) {
      parts.add(
        movie.releaseYear.toString(),
      );
    }

    if (movie.duration != null) {
      parts.add(
        '${movie.duration} phút',
      );
    }

    parts.add(
      movie.isSeries
          ? 'Phim bộ'
          : 'Phim lẻ',
    );

    return parts.join(' · ');
  }

  Widget _buildDescription(Movie movie) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        20,
        26,
        20,
        0,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18211C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF6FAF8E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'THÔNG TIN PHIM',
                style: TextStyle(
                  color: Color(0xFF6FAF8E),
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            movie.description ??
                'Chưa có mô tả cho bộ phim này.',
            style: const TextStyle(
              color: Color(0xFFD7DDD9),
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalInfo() {
    final playback = _playback;

    if (playback == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THÔNG TIN PHÁT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),

          _infoRow(
            'Trạng thái',
            playback.videoStatus == 1
                ? 'Sẵn sàng'
                : 'Chưa sẵn sàng',
          ),

          if (playback.duration != null)
            _infoRow(
              'Thời lượng',
              '${playback.duration} phút',
            ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8D9690),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

