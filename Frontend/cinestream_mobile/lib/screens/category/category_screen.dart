import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category.dart';
import '../../models/movie.dart';
import '../../services/category_service.dart';
import '../../services/movie_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryService _categoryService = CategoryService();
  final MovieService _movieService = MovieService();

  List<Category> _categories = [];
  List<Movie> _movies = [];

  Category? _selectedCategory;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _categoryService.getCategories(),
        _movieService.getMovies(),
      ]);

      final categories = results[0] as List<Category>;
      final movies = results[1] as List<Movie>;

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _movies = movies;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Movie> get _filteredMovies {
    if (_selectedCategory == null) {
      return _movies;
    }

    return _movies.where((movie) {
      return movie.categories.any(
        (category) => category.id == _selectedCategory!.id,
      );
    }).toList();
  }

  int _getMovieCount(Category category) {
    return _movies.where((movie) {
      return movie.categories.any(
        (movieCategory) => movieCategory.id == category.id,
      );
    }).length;
  }

  Color _getCategoryColor(String name) {
    final normalizedName = name.toLowerCase();

    if (normalizedName.contains('hành động')) {
      return const Color(0xFFFF6B35);
    }

    if (normalizedName.contains('tâm lý')) {
      return const Color(0xFF7C4DFF);
    }

    if (normalizedName.contains('khoa học') ||
        normalizedName.contains('viễn tưởng') ||
        normalizedName.contains('sci')) {
      return const Color(0xFF2196F3);
    }

    if (normalizedName.contains('lãng mạn') ||
        normalizedName.contains('tình cảm') ||
        normalizedName.contains('romance')) {
      return const Color(0xFFE91E63);
    }

    if (normalizedName.contains('kinh dị') ||
        normalizedName.contains('horror')) {
      return const Color(0xFF673AB7);
    }

    if (normalizedName.contains('phiêu lưu') ||
        normalizedName.contains('adventure')) {
      return const Color(0xFF009688);
    }

    if (normalizedName.contains('hoạt hình') ||
        normalizedName.contains('animation')) {
      return const Color(0xFFFF9800);
    }

    if (normalizedName.contains('tài liệu') ||
        normalizedName.contains('documentary')) {
      return const Color(0xFF3F51B5);
    }

    if (normalizedName.contains('hài')) {
      return const Color(0xFFFFC107);
    }

    if (normalizedName.contains('gia đình')) {
      return const Color(0xFF00ACC1);
    }

    if (normalizedName.contains('âm nhạc')) {
      return const Color(0xFFEC407A);
    }

    if (normalizedName.contains('bí ẩn') ||
        normalizedName.contains('mystery')) {
      return const Color(0xFF5E35B1);
    }

    return const Color(0xFF607D8B);
  }

  IconData _getCategoryIcon(String name) {
    final normalizedName = name.toLowerCase();

    if (normalizedName.contains('hành động')) {
      return Icons.local_fire_department_rounded;
    }

    if (normalizedName.contains('tâm lý')) {
      return Icons.psychology_rounded;
    }

    if (normalizedName.contains('khoa học') ||
        normalizedName.contains('viễn tưởng') ||
        normalizedName.contains('sci')) {
      return Icons.rocket_launch_rounded;
    }

    if (normalizedName.contains('lãng mạn') ||
        normalizedName.contains('tình cảm') ||
        normalizedName.contains('romance')) {
      return Icons.auto_awesome_rounded;
    }

    if (normalizedName.contains('kinh dị') ||
        normalizedName.contains('horror')) {
      return Icons.sentiment_very_dissatisfied_rounded;
    }

    if (normalizedName.contains('phiêu lưu') ||
        normalizedName.contains('adventure')) {
      return Icons.map_rounded;
    }

    if (normalizedName.contains('hoạt hình') ||
        normalizedName.contains('animation')) {
      return Icons.palette_rounded;
    }

    if (normalizedName.contains('tài liệu') ||
        normalizedName.contains('documentary')) {
      return Icons.videocam_rounded;
    }

    if (normalizedName.contains('hài')) {
      return Icons.mood_rounded;
    }

    if (normalizedName.contains('gia đình')) {
      return Icons.family_restroom_rounded;
    }

    if (normalizedName.contains('âm nhạc')) {
      return Icons.music_note_rounded;
    }

    if (normalizedName.contains('bí ẩn') ||
        normalizedName.contains('mystery')) {
      return Icons.visibility_rounded;
    }

    return Icons.movie_filter_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawerScrimColor: Colors.black.withValues(
        alpha: 0.58,
      ),
      drawer: const AppDrawer(
        currentRoute: AppRoutes.category,
      ),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: _buildBody(context),
      ),
      bottomNavigationBar: const AppBottomNavigation(
        currentIndex: 2,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_categories.isEmpty && _movies.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          bottom: 24,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageTitle(),
            _buildCategoryGrid(context),
            _buildAllMoviesTitle(),
            _buildMovieList(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
  ) {
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
              context,
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

  Widget _buildPageTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        22,
      ),
      child: Text(
        'Danh mục',
        style: TextStyle(
          color: AppTheme.black,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          fontFamily: 'Georgia',
          height: 1.05,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categories.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 146,
        ),
        itemBuilder: (context, index) {
          final category = _categories[index];

          return _buildCategoryCard(
            context,
            category,
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Category category,
  ) {
    final color = _getCategoryColor(category.name);
    final icon = _getCategoryIcon(category.name);
    final count = _getMovieCount(category);
    final isSelected = _selectedCategory?.id == category.id;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedCategory = null;
            } else {
              _selectedCategory = category;
            }
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(
                    color: color,
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$count phim',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.grey,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllMoviesTitle() {
    final title = _selectedCategory == null
        ? 'TẤT CẢ PHIM'
        : _selectedCategory!.name.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        31,
        20,
        14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.black,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ),
          if (_selectedCategory != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(
                  0,
                  0,
                ),
                tapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Xóa lọc',
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMovieList(
    BuildContext context,
  ) {
    final movies = _filteredMovies;

    if (movies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          40,
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.movie_filter_outlined,
                color: AppTheme.grey,
                size: 48,
              ),
              const SizedBox(height: 10),
              Text(
                _selectedCategory == null
                    ? 'Chưa có phim nào.'
                    : 'Danh mục này chưa có phim.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movies.length,
      separatorBuilder: (
        context,
        index,
      ) {
        return const SizedBox(
          height: 12,
        );
      },
      itemBuilder: (
        context,
        index,
      ) {
        return _buildMovieCard(
          context,
          movies[index],
        );
      },
    );
  }

  Widget _buildMovieCard(
    BuildContext context,
    Movie movie,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.movieDetail,
            arguments: movie,
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(15),
                child: SizedBox(
                  width: 92,
                  height: 122,
                  child: Image.network(
                    movie.posterUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Container(
                        color: AppTheme.lightGrey,
                        child: const Center(
                          child: Icon(
                            Icons.movie_outlined,
                            color: AppTheme.grey,
                            size: 34,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: SizedBox(
                  height: 122,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _movieInfo(movie),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.grey,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.yellow,
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            movie.averageRating
                                .toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppTheme.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Expanded(
                        child: Text(
                          movie.description ??
                              'Chưa có mô tả...',
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _movieInfo(Movie movie) {
    final parts = <String>[];

    if (movie.categories.isNotEmpty) {
      parts.add(
        movie.categories
            .take(2)
            .map((category) => category.name)
            .join(' • '),
      );
    } else {
      parts.add('Movie');
    }

    if (movie.releaseYear != null) {
      parts.add(movie.releaseYear.toString());
    }

    if (movie.duration != null &&
        movie.duration! > 0) {
      final hours = movie.duration! ~/ 60;
      final minutes = movie.duration! % 60;

      if (hours > 0) {
        parts.add(
          minutes > 0
              ? '${hours}h ${minutes}m'
              : '${hours}h',
        );
      } else {
        parts.add('${minutes}m');
      }
    }

    return parts.join(' • ');
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 52,
            ),
            const SizedBox(height: 14),
            const Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                color: AppTheme.black,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Đã xảy ra lỗi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Chưa có dữ liệu danh mục và phim.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.grey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(
          seconds: 2,
        ),
      ),
    );
  }
}