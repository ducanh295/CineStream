import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';

class FeaturedScreen extends StatelessWidget {
  const FeaturedScreen({super.key});

  static final List<Movie> _featuredMovies = [
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
    ),
    Movie(
      id: 2,
      title: 'The Quiet Algorithm',
      description:
          'Một thuật toán tưởng như vô hại lại mở ra một bí mật nguy hiểm.',
      posterUrl:
          'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba',
      releaseYear: 2024,
      duration: 118,
      averageRating: 8.7,
      viewCount: 118000,
    ),
    Movie(
      id: 3,
      title: 'Ghost Protocol: Kyoto',
      description:
          'Một nhiệm vụ bí mật đưa đặc vụ trẻ đến thành phố Kyoto.',
      posterUrl:
          'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e',
      releaseYear: 2024,
      duration: 127,
      averageRating: 8.5,
      viewCount: 143000,
    ),
    Movie(
      id: 4,
      title: 'Neon Dharma',
      description:
          'Cuộc hành trình giữa thành phố tương lai và những bí mật bị che giấu.',
      posterUrl:
          'https://images.unsplash.com/photo-1519608487953-e999c86e7455',
      releaseYear: 2024,
      duration: 121,
      averageRating: 8.1,
      viewCount: 124000,
    ),
    Movie(
      id: 5,
      title: 'Ember & Ash',
      description:
          'Một câu chuyện đầy cảm xúc về những con người đang tìm kiếm nhau.',
      posterUrl:
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23',
      releaseYear: 2024,
      duration: 116,
      averageRating: 7.9,
      viewCount: 105000,
    ),
    Movie(
      id: 6,
      title: 'Cold Latitude',
      description:
          'Cuộc phiêu lưu giữa những dãy núi băng giá và vùng đất chưa được khám phá.',
      posterUrl:
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b',
      releaseYear: 2023,
      duration: 124,
      averageRating: 7.6,
      viewCount: 73000,
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
        currentRoute: AppRoutes.featured,
      ),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 22),
              _buildHeroCard(
                context,
                _featuredMovies.first,
              ),
              const SizedBox(height: 30),
              const Text(
                'PHIM ĐANG ĐƯỢC QUAN TÂM',
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              _buildMovieGrid(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(
        currentIndex: 0,
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

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nổi bật',
          style: TextStyle(
            color: AppTheme.black,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            fontFamily: 'Georgia',
            height: 1.05,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Những bộ phim đang được yêu thích trên CineStream.',
          style: TextStyle(
            color: AppTheme.grey,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    Movie movie,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          _openMovieDetail(
            context,
            movie,
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 230,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppTheme.darkGreen,
            image: DecorationImage(
              image: NetworkImage(
                movie.posterUrl ?? '',
              ),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(
                  alpha: 0.48,
                ),
                BlendMode.darken,
              ),
              onError: (exception, stackTrace) {},
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.16,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'TOP 1 NỔI BẬT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 7),
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
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${movie.releaseYear ?? '----'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${movie.duration ?? '--'} phút',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovieGrid(
    BuildContext context,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: _featuredMovies.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        return _buildMovieCard(
          context,
          _featuredMovies[index],
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          _openMovieDetail(
            context,
            movie,
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(14),
                  child: SizedBox(
                    width: double.infinity,
                    child: Image.network(
                      movie.posterUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.lightGrey,
                          child: const Center(
                            child: Icon(
                              Icons.movie_outlined,
                              color: AppTheme.grey,
                              size: 35,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.black,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppTheme.yellow,
                    size: 15,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    movie.averageRating
                        .toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppTheme.black,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMovieDetail(
    BuildContext context,
    Movie movie,
  ) {
    Navigator.pushNamed(
      context,
      AppRoutes.movieDetail,
      arguments: movie,
    );
  }

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}