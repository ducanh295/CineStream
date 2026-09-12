import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../services/favorite_service.dart';
import '../../services/movie_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/movie_card.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie? movie;

  const MovieDetailScreen({
    super.key,
    this.movie,
  });

  @override
  State<MovieDetailScreen> createState() =>
      _MovieDetailScreenState();
}

class _MovieDetailScreenState
    extends State<MovieDetailScreen> {
  final FavoriteService _favoriteService =
      FavoriteService();

  final MovieService _movieService =
      MovieService();

  late final Movie _movie;

  bool _isSaved = false;
  bool _isCheckingFavorite = true;
  bool _isUpdatingFavorite = false;

  bool _isLoadingRecommendations = true;

  String? _favoriteError;
  String? _recommendationError;

  List<Movie> _recommendedMovies = [];

  @override
  void initState() {
    super.initState();

    _movie = widget.movie ??
        Movie(
          id: 1,
          title: 'The Forgotten Meridian',
          description:
              'Một bí mật bị lãng quên giữa thành phố tương lai.',
          posterUrl:
              'https://images.unsplash.com/photo-1485846234645-a62644f84728',
          releaseYear: 2024,
          duration: 138,
          averageRating: 8.4,
          viewCount: 125000,
          videoStatus: 1,
        );

    _loadFavoriteStatus();
    _loadRecommendations();
  }

  // ============================================================
  // LOAD TOKEN
  // ============================================================

  Future<String?> _getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    const keys = [
      'token',
      'accessToken',
      'jwtToken',
    ];

    for (final key in keys) {
      final token = prefs.getString(key);

      if (token != null &&
          token.trim().isNotEmpty) {
        return token.trim();
      }
    }

    return null;
  }

  // ============================================================
  // FAVORITE
  // ============================================================

  Future<void> _loadFavoriteStatus() async {
    final token = await _getToken();

    if (!mounted) {
      return;
    }

    if (token == null) {
      setState(() {
        _isCheckingFavorite = false;
        _favoriteError = null;
        _isSaved = false;
      });

      return;
    }

    try {
      final isFavorite =
          await _favoriteService.checkFavorite(
        token,
        _movie.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaved = isFavorite;
        _isCheckingFavorite = false;
        _favoriteError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingFavorite = false;
        _favoriteError =
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isUpdatingFavorite) {
      return;
    }

    final token = await _getToken();

    if (!mounted) {
      return;
    }

    if (token == null) {
      _showMessage(
        'Bạn cần đăng nhập để sử dụng danh sách yêu thích.',
      );
      return;
    }

    setState(() {
      _isUpdatingFavorite = true;
      _favoriteError = null;
    });

    try {
      if (_isSaved) {
        await _favoriteService.removeFavorite(
          token,
          _movie.id,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _isSaved = false;
          _isUpdatingFavorite = false;
        });

        _showMessage(
          'Đã bỏ phim khỏi danh sách yêu thích.',
        );
      } else {
        await _favoriteService.addFavorite(
          token,
          _movie.id,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _isSaved = true;
          _isUpdatingFavorite = false;
        });

        _showMessage(
          'Đã thêm phim vào danh sách yêu thích.',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingFavorite = false;
        _favoriteError =
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
      });

      _showMessage(
        _favoriteError ??
            'Không thể cập nhật danh sách yêu thích.',
      );
    }
  }

  // ============================================================
  // RECOMMENDATIONS
  // ============================================================

  Future<void> _loadRecommendations() async {
    try {
      final movies =
          await _movieService.getMovies();

      if (!mounted) {
        return;
      }

      final recommendations = movies
          .where(
            (movie) => movie.id != _movie.id,
          )
          .toList();

      setState(() {
        _recommendedMovies =
            recommendations.take(10).toList();
        _isLoadingRecommendations = false;
        _recommendationError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingRecommendations = false;
        _recommendationError =
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawerScrimColor: Colors.black.withValues(
        alpha: 0.58,
      ),
      drawer: const AppDrawer(
        currentRoute: null,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                bottom: 105,
              ),
              physics:
                  const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(),
                  _buildMovieInfo(),
                  _buildContentSection(),
                  _buildDirectorSection(),
                  _buildCastSection(),
                  _buildRecommendations(),
                ],
              ),
            ),
            _buildTopBar(),
          ],
        ),
      ),
      bottomNavigationBar:
          const AppBottomNavigation(
        currentIndex: 0,
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 64,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(
                alpha: 0.58,
              ),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            _circleButton(
              icon:
                  Icons.arrow_back_rounded,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _movie.title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(
        alpha: 0.35,
      ),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder:
            const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHeroBanner() {
    return SizedBox(
      width: double.infinity,
      height: 405,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _movie.posterUrl ?? '',
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                decoration:
                    const BoxDecoration(
                  gradient: LinearGradient(
                    begin:
                        Alignment.topCenter,
                    end:
                        Alignment.bottomCenter,
                    colors: [
                      Color(0xFFBC4D8C),
                      AppTheme.darkGreen2,
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons
                        .movie_creation_outlined,
                    color: Colors.white30,
                    size: 90,
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin:
                    Alignment.topCenter,
                end:
                    Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  AppTheme.background
                      .withValues(
                    alpha: 0.18,
                  ),
                  AppTheme.background,
                ],
                stops: const [
                  0.35,
                  0.55,
                  0.82,
                  1,
                ],
              ),
            ),
          ),
          Positioned(
            top: 78,
            right: 18,
            child: _heroFloatingButton(
              icon: _isCheckingFavorite
                  ? Icons.hourglass_empty_rounded
                  : _isSaved
                      ? Icons.bookmark_rounded
                      : Icons
                          .bookmark_border_rounded,
              onTap:
                  _isCheckingFavorite ||
                          _isUpdatingFavorite
                      ? () {}
                      : _toggleFavorite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(
        alpha: 0.38,
      ),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder:
            const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: _isUpdatingFavorite
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOVIE INFO
  // ============================================================

  Widget _buildMovieInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            _movie.title,
            style: const TextStyle(
              color: AppTheme.black,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              fontFamily: 'Georgia',
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 13),
          _buildMetaInfo(),
          const SizedBox(height: 19),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 51,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _openVideoPlayer(
                        _movie,
                      );
                    },
                    icon: const Icon(
                      Icons
                          .play_arrow_rounded,
                      size: 24,
                    ),
                    label: const Text(
                      'Xem phim',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.darkGreen,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 51,
                height: 51,
                child: OutlinedButton(
                  onPressed: () {
                    _showMessage(
                      'Tùy chọn chia sẻ sẽ được kết nối sau.',
                    );
                  },
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        AppTheme.darkGreen,
                    side:
                        const BorderSide(
                      color:
                          AppTheme.darkGreen,
                      width: 1.2,
                    ),
                    padding:
                        EdgeInsets.zero,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons.share_rounded,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo() {
    return Row(
      children: [
        const Icon(
          Icons.star_rounded,
          color: AppTheme.yellow,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          '${_movie.averageRating.toStringAsFixed(1)} /10',
          style: const TextStyle(
            color: AppTheme.black,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        _metaDivider(),
        const Icon(
          Icons.schedule_rounded,
          color: AppTheme.grey,
          size: 17,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDuration(
            _movie.duration,
          ),
          style: const TextStyle(
            color: AppTheme.grey,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        _metaDivider(),
        Text(
          '${_movie.releaseYear ?? '----'}',
          style: const TextStyle(
            color: AppTheme.grey,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _metaDivider() {
    return const Padding(
      padding:
          EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child: Text(
        '•',
        style: TextStyle(
          color: AppTheme.grey,
          fontSize: 14,
        ),
      ),
    );
  }

  String _formatDuration(int? duration) {
    if (duration == null ||
        duration <= 0) {
      return '--';
    }

    final hours = duration ~/ 60;
    final minutes = duration % 60;

    if (hours == 0) {
      return '${minutes}m';
    }

    return minutes == 0
        ? '${hours}h'
        : '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        28,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Nội dung',
            style: TextStyle(
              color: AppTheme.black,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _movie.description ??
                'Chưa có mô tả cho bộ phim này.',
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIRECTOR + CATEGORY
  // ============================================================

  Widget _buildDirectorSection() {
    final categoryText =
        _movie.categories.isEmpty
            ? 'Chưa cập nhật'
            : _movie.categories
                .map(
                  (category) =>
                      category.name,
                )
                .join(' • ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        25,
        20,
        0,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Đạo diễn',
                  style: TextStyle(
                    color: AppTheme.grey,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Chưa cập nhật',
                  style: TextStyle(
                    color: AppTheme.black,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.lightGrey,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thể loại',
                  style: TextStyle(
                    color: AppTheme.grey,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  categoryText,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.black,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CAST
  // ============================================================

  Widget _buildCastSection() {
    if (_movie.actors.isEmpty) {
      return Padding(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          26,
          20,
          0,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Diễn viên',
              style: TextStyle(
                color: AppTheme.black,
                fontSize: 21,
                fontWeight:
                    FontWeight.w900,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có thông tin diễn viên.',
              style: TextStyle(
                color: AppTheme.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        26,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Diễn viên',
            style: TextStyle(
              color: AppTheme.black,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _movie.actors.map(
              (actor) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                    border: Border.all(
                      color: AppTheme.darkGreen
                          .withValues(
                        alpha: 0.10,
                      ),
                    ),
                  ),
                  child: Text(
                    actor.name,
                    style:
                        const TextStyle(
                      color:
                          AppTheme.black,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECOMMENDATIONS
  // ============================================================

  Widget _buildRecommendations() {
    return Padding(
      padding:
          const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Có thể bạn thích',
                    style: TextStyle(
                      color: AppTheme.black,
                      fontSize: 21,
                      fontWeight:
                          FontWeight.w900,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.search,
                    );
                  },
                  child: const Row(
                    children: [
                      Text(
                        'Xem thêm',
                        style: TextStyle(
                          color:
                              AppTheme.darkGreen,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons
                            .chevron_right_rounded,
                        color:
                            AppTheme.darkGreen,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildRecommendationContent(),
        ],
      ),
    );
  }

  Widget _buildRecommendationContent() {
    if (_isLoadingRecommendations) {
      return const SizedBox(
        height: 265,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_recommendationError != null) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Text(
          _recommendationError!,
          style: const TextStyle(
            color: AppTheme.grey,
            fontSize: 13,
          ),
        ),
      );
    }

    if (_recommendedMovies.isEmpty) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Text(
          'Chưa có phim đề xuất.',
          style: TextStyle(
            color: AppTheme.grey,
            fontSize: 13,
          ),
        ),
      );
    }

    return SizedBox(
      height: 265,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount:
            _recommendedMovies.length,
        separatorBuilder:
            (context, index) {
          return const SizedBox(
            width: 14,
          );
        },
        itemBuilder:
            (context, index) {
          final movie =
              _recommendedMovies[index];

          return MovieCard(
            movie: movie,
            onTap: () {
              _openMovieDetail(movie);
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openMovieDetail(
    Movie movie,
  ) {
    Navigator.pushNamed(
      context,
      AppRoutes.movieDetail,
      arguments: movie,
    );
  }

  void _openVideoPlayer(
    Movie movie,
  ) {
    Navigator.pushNamed(
      context,
      AppRoutes.player,
      arguments: movie,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        duration:
            const Duration(seconds: 2),
      ),
    );
  }
}