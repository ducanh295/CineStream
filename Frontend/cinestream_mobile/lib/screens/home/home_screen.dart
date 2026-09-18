import 'dart:async';

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
  final MovieService _movieService = MovieService.instance;

  List<Movie> _movies = const [];
  List<Movie> _featuredMovies = const [];

  int _currentHeroIndex = 0;
  late final PageController _heroPageController;
  Timer? _heroTimer;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
    _loadMovies();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  // Tự động xoay vòng banner phim nổi bật sau mỗi 5 giây
  void _startHeroTimer(int count) {
    _heroTimer?.cancel();
    if (count <= 1) {
      return;
    }

    _heroTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_heroPageController.hasClients || count <= 1) {
        return;
      }

      final nextIndex = (_currentHeroIndex + 1) % count;
      _heroPageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  // Tải đồng thời danh sách phim trang chủ và danh sách phim nổi bật cho banner
  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _movieService.getMovies(page: 1, pageSize: 10),
        _movieService.getFeaturedMovies(limit: 5),
      ]);

      if (!mounted) {
        return;
      }

      final allMovies = results[0];
      var featured = results[1];

      // Cơ chế dự phòng: nếu chưa có phim nào được gắn cờ nổi bật, sử dụng phim đầu tiên
      if (featured.isEmpty && allMovies.isNotEmpty) {
        featured = [allMovies.first];
      }

      setState(() {
        _movies = allMovies;
        _featuredMovies = featured;
        _currentHeroIndex = 0;
        _isLoading = false;
      });

      _startHeroTimer(_featuredMovies.length);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawerScrimColor: Colors.black.withValues(alpha: 0.58),
      drawer: const AppDrawer(
        currentRoute: AppRoutes.home,
      ),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMovies,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 24),
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
    );
  }

  Widget _buildGreeting() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chào buổi tối',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 100),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: AppTheme.grey,
              ),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMovies,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_movies.isEmpty && _featuredMovies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 80,
        ),
        child: Center(
          child: Text(
            'Chưa có phim nào.',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    final firstSection = _movies.take(4).toList();
    final secondSection = _movies.skip(4).take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCarousel(_featuredMovies),

        if (firstSection.isNotEmpty) ...[
          _buildSectionTitle(
            title: 'Phim mới',
            action: 'Xem thêm',
          ),
          _buildMovieCarousel(firstSection),
        ],

        if (secondSection.isNotEmpty) ...[
          _buildSectionTitle(
            title: 'Khám phá thêm',
            action: 'Xem thêm',
          ),
          _buildMovieCarousel(secondSection),
        ],

        _buildAiBanner(),
        const SizedBox(height: 10),
      ],
    );
  }

  // Khối băng chuyền Hero Banner hỗ trợ trượt cảm ứng và chấm chỉ báo trang
  Widget _buildHeroCarousel(List<Movie> featuredList) {
    if (featuredList.isEmpty) {
      return const SizedBox.shrink();
    }

    if (featuredList.length == 1) {
      return _buildHeroCard(featuredList.first);
    }

    return SizedBox(
      height: 395,
      child: Stack(
        children: [
          PageView.builder(
            controller: _heroPageController,
            itemCount: featuredList.length,
            onPageChanged: (index) {
              setState(() {
                _currentHeroIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildHeroCard(featuredList[index]);
            },
          ),
          Positioned(
            right: 38,
            bottom: 34,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                featuredList.length,
                (dotIndex) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentHeroIndex == dotIndex ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentHeroIndex == dotIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(Movie movie) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.darkGreen2,
                    child: const Center(
                      child: Icon(
                        Icons.movie_creation_outlined,
                        color: Colors.white30,
                        size: 85,
                      ),
                    ),
                  );
                },
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PHIM NỔI BẬT',
                      style: TextStyle(
                        color: Color(0xFF9CE89E),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Georgia',
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (movie.releaseYear != null)
                          Text(
                            movie.releaseYear.toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        if (movie.duration != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            '${movie.duration} phút',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _openMovieDetail(movie);
                        },
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          size: 21,
                        ),
                        label: const Text(
                          'Xem ngay',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
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
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.search,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.darkGreen,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Xem thêm',
                  style: TextStyle(
                    color: AppTheme.darkGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.darkGreen,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCarousel(List<Movie> movies) {
    return SizedBox(
      height: 268,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: movies.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 14);
        },
        itemBuilder: (context, index) {
          final movie = movies[index];

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

  Widget _buildAiBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Material(
        color: AppTheme.darkGreen,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.chatbot,
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              12,
              16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withValues(
                      alpha: 0.18,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.pinkAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trợ lý AI CineBot',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Hỏi tôi để tìm phim phù hợp với tâm trạng bạn',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF63A681),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
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
}
