import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  static const List<_CategoryItem> _categories = [
    _CategoryItem(
      name: 'Hành động',
      count: 124,
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF6B35),
    ),
    _CategoryItem(
      name: 'Tâm lý',
      count: 89,
      icon: Icons.psychology_rounded,
      color: Color(0xFF7C4DFF),
    ),
    _CategoryItem(
      name: 'Khoa học viễn tưởng',
      count: 67,
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFF2196F3),
    ),
    _CategoryItem(
      name: 'Lãng mạn',
      count: 93,
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFE91E63),
    ),
    _CategoryItem(
      name: 'Kinh dị',
      count: 58,
      icon: Icons.sentiment_very_dissatisfied_rounded,
      color: Color(0xFF673AB7),
    ),
    _CategoryItem(
      name: 'Phiêu lưu',
      count: 71,
      icon: Icons.map_rounded,
      color: Color(0xFF009688),
    ),
    _CategoryItem(
      name: 'Hoạt hình',
      count: 45,
      icon: Icons.palette_rounded,
      color: Color(0xFFFF9800),
    ),
    _CategoryItem(
      name: 'Tài liệu',
      count: 112,
      icon: Icons.videocam_rounded,
      color: Color(0xFF3F51B5),
    ),
  ];

  static final List<Movie> _movies = [
    Movie(
      id: 1,
      title: 'The Forgotten Meridian',
      description:
          'Một bí mật bị lãng quên giữa thành phố tương lai...',
      posterUrl:
          'https://images.unsplash.com/photo-1485846234645-a62644f84728',
      releaseYear: 2024,
      duration: 138,
      averageRating: 8.4,
      viewCount: 125000,
    ),
    Movie(
      id: 2,
      title: 'Neon Dharma',
      description:
          'Cuộc hành trình giữa thành phố tương lai và những bí mật bị che giấu...',
      posterUrl:
          'https://images.unsplash.com/photo-1519608487953-e999c86e7455',
      releaseYear: 2024,
      duration: 126,
      averageRating: 8.1,
      viewCount: 124000,
    ),
    Movie(
      id: 3,
      title: 'Cold Latitude',
      description:
          'Cuộc phiêu lưu giữa những dãy núi băng giá và vùng đất chưa được khám phá...',
      posterUrl:
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b',
      releaseYear: 2023,
      duration: 151,
      averageRating: 7.6,
      viewCount: 73000,
    ),
    Movie(
      id: 4,
      title: 'The Quiet Algorithm',
      description:
          'Một thuật toán tưởng như vô hại lại mở ra một bí mật nguy hiểm...',
      posterUrl:
          'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba',
      releaseYear: 2024,
      duration: 109,
      averageRating: 8.7,
      viewCount: 118000,
    ),
    Movie(
      id: 5,
      title: 'Marea',
      description:
          'Một câu chuyện tình yêu bắt đầu từ những ký ức tưởng như đã biến mất...',
      posterUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9',
      releaseYear: 2024,
      duration: 118,
      averageRating: 7.3,
      viewCount: 54000,
    ),
    Movie(
      id: 6,
      title: 'Ghost Protocol: Kyoto',
      description:
          'Một nhiệm vụ bí mật đưa đặc vụ trẻ đến thành phố Kyoto...',
      posterUrl:
          'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e',
      releaseYear: 2024,
      duration: 134,
      averageRating: 7.8,
      viewCount: 98000,
    ),
    Movie(
      id: 7,
      title: 'Saltwater Saints',
      description:
          'Những con người xa lạ gặp nhau bên bờ biển và thay đổi cuộc đời nhau...',
      posterUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
      releaseYear: 2023,
      duration: 123,
      averageRating: 8.0,
      viewCount: 69000,
    ),
  ];

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            bottom: 24,
          ),
          physics: const BouncingScrollPhysics(),
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
      ),
      bottomNavigationBar: const AppBottomNavigation(
        currentIndex: 2,
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

          // Dùng chiều cao cố định để tránh overflow.
          mainAxisExtent: 146,
        ),
        itemBuilder: (context, index) {
          return _buildCategoryCard(
            context,
            _categories[index],
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    _CategoryItem category,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          _showMessage(
            context,
            'Đang mở thể loại ${category.name}.',
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: category.color.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
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
                '${category.count} phim',
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
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        31,
        20,
        14,
      ),
      child: Text(
        'TẤT CẢ PHIM',
        style: TextStyle(
          color: AppTheme.black,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildMovieList(
    BuildContext context,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _movies.length,
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
          _movies[index],
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                        overflow: TextOverflow.ellipsis,
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
                            movie.averageRating.toStringAsFixed(1),
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
                          overflow: TextOverflow.ellipsis,
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
    switch (movie.id) {
      case 1:
        return 'Thriller • 2024 • 2h 18m';

      case 2:
        return 'Sci-Fi • 2024 • 2h 6m';

      case 3:
        return 'Adventure • 2023 • 2h 31m';

      case 4:
        return 'Thriller • 2024 • 1h 49m';

      case 5:
        return 'Romance • 2024 • 1h 58m';

      case 6:
        return 'Action • 2024 • 2h 14m';

      case 7:
        return 'Drama • 2023 • 2h 3m';

      default:
        return 'Movie • ${movie.releaseYear ?? '----'}';
    }
  }

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

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

class _CategoryItem {
  final String name;
  final int count;
  final IconData icon;
  final Color color;

  const _CategoryItem({
    required this.name,
    required this.count,
    required this.icon,
    required this.color,
  });
}