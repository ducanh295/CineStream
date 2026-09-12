import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../services/movie_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/movie_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MovieService _movieService = MovieService();

  List<Movie> _movies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    try {
      final movies = await _movieService.getMovies();

      if (!mounted) return;

      setState(() {
        _movies = movies;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawerScrimColor: Colors.black.withValues(
        alpha: 0.58,
      ),
      drawer: const AppDrawer(
        currentRoute: AppRoutes.home,
      ),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMovies,
          color: AppTheme.darkGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(
        currentIndex: 0,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 80,
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          40,
          20,
          40,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 60,
              color: AppTheme.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải dữ liệu phim',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.black,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadMovies,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_movies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 80,
        ),
        child: Center(
          child: Text(
            'Chưa có dữ liệu phim.',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    final Movie featuredMovie = _movies.first;

    final List<Movie> newReleaseMovies =
        List<Movie>.from(_movies)
          ..sort(
            (a, b) =>
                (b.releaseYear ?? 0).compareTo(
                  a.releaseYear ?? 0,
                ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(featuredMovie),
        _buildSectionTitle(
          title: 'Đang thịnh hành',
          action: 'Xem thêm',
          onTap: () {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.search,
            );
          },
        ),
        _buildMovieCarousel(_movies),
        _buildSectionTitle(
          title: 'Mới ra mắt',
          action: 'Xem thêm',
          onTap: () {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.search,
            );
          },
        ),
        _buildMovieCarousel(newReleaseMovies),
        _buildAiBanner(),
        const SizedBox(height: 10),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) {
          return IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(
              Icons.menu_rounded,
              color: AppTheme.black,
              size: 28,
            ),
          );
        },
      ),
      centerTitle: true,
      title: const Text(
        'CineStream',
        style: TextStyle(
          color: AppTheme.black,
          fontSize: 23,
          fontWeight: FontWeight.w900,
          fontFamily: 'Georgia',
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            _showMessage(
              'Bạn không có thông báo mới.',
            );
          },
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppTheme.black,
            size: 26,
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Chào buổi tối',
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '🌙',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Tối nay xem gì?',
            style: TextStyle(
              color: AppTheme.black,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              fontFamily: 'Georgia',
              height: 1.08,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(Movie movie) {
    final String categoryName =
        movie.categories.isNotEmpty
            ? movie.categories.first.name
            : 'Phim';

    final String durationText =
        movie.duration != null
            ? '${movie.duration} phút'
            : 'Đang cập nhật';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 395,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                movie.posterUrl ?? '',
                fit: BoxFit.cover,
                loadingBuilder:
                    (
                      context,
                      child,
                      loadingProgress,
                    ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return Container(
                    decoration:
                        const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFBC4E91),
                          AppTheme.darkGreen2,
                        ],
                      ),
                    ),
                    child: const Center(
                      child:
                          CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                errorBuilder:
                    (
                      context,
                      error,
                      stackTrace,
                    ) {
                  return Container(
                    decoration:
                        const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFBC4E91),
                          AppTheme.darkGreen2,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons
                            .movie_creation_outlined,
                        color: Colors.white30,
                        size: 85,
                      ),
                    ),
                  );
                },
              ),

              Container(
                decoration: BoxDecoration(
                  gradient:
                      LinearGradient(
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,
                    colors: [
                      const Color(
                        0xFFFF4FA3,
                      ).withValues(
                        alpha: 0.18,
                      ),
                      Colors.transparent,
                      const Color(
                        0xFF7C286E,
                      ).withValues(
                        alpha: 0.24,
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                decoration:
                    const BoxDecoration(
                  gradient: LinearGradient(
                    begin:
                        Alignment.topCenter,
                    end:
                        Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x25174D3C),
                      Color(0xF2174D3C),
                    ],
                    stops: [
                      0.20,
                      0.48,
                      1.0,
                    ],
                  ),
                ),
              ),

              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NỔI BẬT HÔM NAY',
                      style: TextStyle(
                        color:
                            Color(0xFF9CE89E),
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight:
                            FontWeight.w900,
                        fontFamily: 'Georgia',
                        height: 1.05,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Row(
                      children: [
                        Text(
                          categoryName,
                          style:
                              const TextStyle(
                            color:
                                Colors.white70,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Text(
                          durationText,
                          style:
                              const TextStyle(
                            color:
                                Colors.white70,
                            fontSize: 12,
                          ),
                        ),

                        if (movie.averageRating >
                            0) ...[
                          const SizedBox(
                            width: 12,
                          ),
                          const Icon(
                            Icons
                                .star_rounded,
                            color:
                                AppTheme
                                    .yellow,
                            size: 16,
                          ),
                          const SizedBox(
                            width: 3,
                          ),
                          Text(
                            movie
                                .averageRating
                                .toStringAsFixed(
                              1,
                            ),
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    SizedBox(
                      height: 45,
                      child:
                          ElevatedButton.icon(
                        onPressed: () {
                          _openMovieDetail(
                            movie,
                          );
                        },
                        icon: const Icon(
                          Icons
                              .play_arrow_rounded,
                          size: 21,
                        ),
                        label: const Text(
                          'Xem ngay',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Colors.white,
                          foregroundColor:
                              AppTheme.black,
                          elevation: 0,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 18,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String action,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        29,
        20,
        14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.black,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor:
                  AppTheme.darkGreen,
              padding: EdgeInsets.zero,
              minimumSize:
                  const Size(0, 36),
              tapTargetSize:
                  MaterialTapTargetSize
                      .shrinkWrap,
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  action,
                  style:
                      const TextStyle(
                    color:
                        AppTheme.darkGreen,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  width: 3,
                ),
                const Icon(
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
    );
  }

  Widget _buildMovieCarousel(
    List<Movie> movies,
  ) {
    return SizedBox(
      height: 268,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount: movies.length,
        separatorBuilder:
            (context, index) {
          return const SizedBox(
            width: 14,
          );
        },
        itemBuilder:
            (context, index) {
          final movie =
              movies[index];

          return MovieCard(
            movie: movie,
            onTap: () {
              _openMovieDetail(
                movie,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAiBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        26,
        20,
        0,
      ),
      child: Material(
        color: AppTheme.darkGreen,
        borderRadius:
            BorderRadius.circular(22),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(22),
          onTap: () {
            Navigator
                .pushReplacementNamed(
              context,
              AppRoutes.chatbot,
            );
          },
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              12,
              16,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                22,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration:
                      BoxDecoration(
                    color: Colors
                        .pinkAccent
                        .withValues(
                      alpha: 0.18,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .smart_toy_rounded,
                    color:
                        Colors.pinkAccent,
                    size: 28,
                  ),
                ),

                const SizedBox(
                  width: 13,
                ),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Trợ lý AI CineBot',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize: 15,
                          fontWeight:
                              FontWeight
                                  .w900,
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Hỏi tôi để tìm phim phù hợp với tâm trạng bạn',
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Container(
                  width: 40,
                  height: 40,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFF63A681,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .arrow_forward_rounded,
                    color:
                        Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openMovieDetail(Movie movie) {
    Navigator.pushNamed(
      context,
      AppRoutes.movieDetail,
      arguments: movie,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}