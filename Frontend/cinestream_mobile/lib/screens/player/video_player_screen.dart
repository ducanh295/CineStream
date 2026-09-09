import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
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

class _VideoPlayerScreenState
    extends State<VideoPlayerScreen> {
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isFullscreen = false;
  bool _isFavorite = false;

  double _progress = 28 * 60 + 14;

  static const double _totalSeconds =
      2 * 60 * 60 + 18 * 60;

  Movie get _movie {
    return widget.movie ??
        Movie(
          id: 1,
          title: 'The Forgotten Meridian',
          description:
              "A disgraced cartographer discovers a map that shouldn't exist — one that leads to a city erased from every record in history. As governments close in, she must decide whether some secrets are better left buried.",
          posterUrl:
              'https://images.unsplash.com/photo-1519608487953-e999c86e7455?auto=format&fit=crop&w=1200&q=80',
          videoUrl: null,
          videoStatus: 0,
          trailerUrl: null,
          duration: 138,
          releaseYear: 2024,
          type: 0,
          averageRating: 8.4,
          viewCount: 0,
          categories: const [],
          actors: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  }

  static const List<_NextMovie> _nextMovies = [
    _NextMovie(
      title: 'Ember & Ash',
      duration: '1h 54m',
      imageUrl:
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=800&q=80',
    ),
    _NextMovie(
      title: 'Neon Dharma',
      duration: '2h 6m',
      imageUrl:
          'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=800&q=80',
    ),
    _NextMovie(
      title: 'Cold Latitude',
      duration: '2h 31m',
      imageUrl:
          'https://images.unsplash.com/photo-1518568740560-333139a27e72?auto=format&fit=crop&w=800&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101512),
      drawerScrimColor: Colors.black.withValues(
        alpha: 0.58,
      ),
      drawer: const AppDrawer(
        currentRoute: null,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildVideoPlayer(),
                    _buildMovieHeader(),
                    _buildNowPlaying(),
                    _buildNextMovies(),
                    _buildActionButtons(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D100E),
              image: DecorationImage(
                image: NetworkImage(
                  _movie.posterUrl ?? '',
                ),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {},
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(
                      alpha: 0.52,
                    ),
                    Colors.black.withValues(
                      alpha: 0.08,
                    ),
                    Colors.black.withValues(
                      alpha: 0.72,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        Positioned(
          top: 45,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              _circleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              Row(
                children: [
                  _circleButton(
                    icon: _isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    onTap: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _circleButton(
                    icon: _isFullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    onTap: () {
                      setState(() {
                        _isFullscreen =
                            !_isFullscreen;
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  Builder(
                    builder: (scaffoldContext) {
                      return _circleButton(
                        icon: Icons.menu_rounded,
                        onTap: () {
                          Scaffold.of(
                            scaffoldContext,
                          ).openDrawer();
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        Positioned.fill(
          child: Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isPlaying = !_isPlaying;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 200,
                ),
                width: _isPlaying ? 66 : 72,
                height: _isPlaying ? 66 : 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.darkGreen.withValues(
                    alpha: 0.96,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.25,
                      ),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ),
        ),

        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: Row(
            children: [
              Text(
                _formatCurrentTime(_progress),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape:
                        const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    activeTrackColor:
                        AppTheme.darkGreen,
                    inactiveTrackColor:
                        Colors.white.withValues(
                      alpha: 0.28,
                    ),
                    thumbColor:
                        AppTheme.darkGreen,
                    overlayColor:
                        AppTheme.darkGreen.withValues(
                      alpha: 0.18,
                    ),
                  ),
                  child: Slider(
                    value: _progress,
                    min: 0,
                    max: _totalSeconds,
                    onChanged: (value) {
                      setState(() {
                        _progress = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '2h 18m',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMovieHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        0,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _movie.title,
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
                  'Thriller · '
                  '${_movie.releaseYear ?? '2024'}',
                  style: const TextStyle(
                    color: Color(0xFFB8C0BA),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppTheme.yellow,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_movie.averageRating.toStringAsFixed(1)}/10',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _formatDuration(
                        _movie.duration ?? 0,
                      ),
                      style: const TextStyle(
                        color: Color(0xFFB8C0BA),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _headerIconButton(
            icon: _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: _isFavorite
                ? const Color(0xFFE76F7A)
                : Colors.white,
            onTap: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });

              _showMessage(
                _isFavorite
                    ? 'Đã thêm vào danh sách yêu thích.'
                    : 'Đã bỏ khỏi danh sách yêu thích.',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying() {
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
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.darkGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'ĐANG PHÁT',
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
            _movie.description ??
                "A disgraced cartographer discovers a map that shouldn't exist — one that leads to a city erased from every record in history. As governments close in, she must decide whether some secrets are better left buried.",
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

  Widget _buildNextMovies() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 30,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Text(
              'PHIM TIẾP THEO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 195,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              scrollDirection: Axis.horizontal,
              physics:
                  const BouncingScrollPhysics(),
              itemCount: _nextMovies.length,
              separatorBuilder: (_, _) {
                return const SizedBox(
                  width: 14,
                );
              },
              itemBuilder: (context, index) {
                final item =
                    _nextMovies[index];

                return _buildNextMovieCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMovieCard(
    _NextMovie movie,
  ) {
    return SizedBox(
      width: 150,
      child: GestureDetector(
        onTap: () {
          final selectedMovie =
              _createMovieFromNextMovie(movie);

          Navigator.pushNamed(
            context,
            AppRoutes.movieDetail,
            arguments: selectedMovie,
          );
        },
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(16),
                    child: Image.network(
                      movie.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) {
                        return Container(
                          color: const Color(
                            0xFF222924,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.movie_rounded,
                              color: Colors.white24,
                              size: 42,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(
                              alpha: 0.02,
                            ),
                            Colors.black.withValues(
                              alpha: 0.64,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 11,
                    bottom: 11,
                    child: Container(
                      width: 37,
                      height: 37,
                      decoration:
                          const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppTheme.darkGreen,
                        size: 24,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 9,
                    bottom: 9,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.65,
                        ),
                        borderRadius:
                            BorderRadius.circular(7),
                      ),
                      child: Text(
                        movie.duration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Movie _createMovieFromNextMovie(
    _NextMovie movie,
  ) {
    int duration = 0;

    switch (movie.title) {
      case 'Ember & Ash':
        duration = 114;
        break;
      case 'Neon Dharma':
        duration = 126;
        break;
      case 'Cold Latitude':
        duration = 151;
        break;
    }

    return Movie(
      id: movie.title.hashCode,
      title: movie.title,
      description:
          'Một bộ phim được đề xuất dựa trên nội dung bạn đang xem.',
      posterUrl: movie.imageUrl,
      releaseYear: 2024,
      duration: duration,
      averageRating: 8.0,
      viewCount: 0,
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        28,
        20,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              icon:
                  Icons.chat_bubble_outline_rounded,
              label: 'Bình luận',
              onTap: () {
                _showMessage(
                  'Tính năng bình luận sẽ được kết nối sau.',
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionButton(
              icon: Icons.share_outlined,
              label: 'Chia sẻ',
              onTap: () {
                _showMessage(
                  'Tùy chọn chia sẻ sẽ được kết nối sau.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(
        alpha: 0.38,
      ),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1B241F),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: color,
          size: 22,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF18211C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
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

  String _formatCurrentTime(
    double seconds,
  ) {
    final totalMinutes = seconds ~/ 60;
    final minutes = totalMinutes % 60;
    final hours = totalMinutes ~/ 60;
    final secs = seconds.toInt() % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int duration) {
    if (duration <= 0) {
      return '2h 18m';
    }

    final hours = duration ~/ 60;
    final minutes = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _NextMovie {
  final String title;
  final String duration;
  final String imageUrl;

  const _NextMovie({
    required this.title,
    required this.duration,
    required this.imageUrl,
  });
}