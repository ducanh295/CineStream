import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/favorite.dart';
import '../../models/movie.dart';
import '../../services/favorite_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() =>
      _FavoritesScreenState();
}

class _FavoritesScreenState
    extends State<FavoritesScreen> {
  final FavoriteService _favoriteService =
      FavoriteService.instance;

  bool _isLoading = true;
  String? _errorMessage;
  List<Favorite> _favorites = [];

  @override
  void initState() {
    super.initState();

    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final favorites =
          await _favoriteService.getFavorites();

      if (!mounted) {
        return;
      }

      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  Future<void> _removeFavorite(
    Favorite favorite,
  ) async {
    final movieId = favorite.movieId;

    // Cập nhật UI ngay.
    setState(() {
      _favorites.removeWhere(
        (item) => item.movieId == movieId,
      );
    });

    try {
      final isFavorite =
          await _favoriteService
              .toggleFavorite(movieId);

      if (!mounted) {
        return;
      }

      // Nếu Backend vẫn báo true,
      // tải lại danh sách để đồng bộ chính xác.
      if (isFavorite) {
        await _loadFavorites();
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Đã bỏ khỏi danh sách yêu thích.',
              ),
              behavior:
                  SnackBarBehavior.floating,
            ),
          );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      // Lỗi thì tải lại danh sách
      // để trả UI về trạng thái Backend.
      await _loadFavorites();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst(
                'Exception: ',
                '',
              ),
            ),
            behavior:
                SnackBarBehavior.floating,
          ),
        );
    }
  }

  Movie _favoriteToMovie(
    Favorite favorite,
  ) {
    return Movie(
      id: favorite.movieId,
      title: favorite.title,
      description: favorite.description,
      posterUrl: favorite.posterUrl,
      trailerUrl: favorite.trailerUrl,
      duration: favorite.duration,
      releaseYear: favorite.releaseYear,
      categories: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.background,
      drawerScrimColor:
          Colors.black.withValues(
        alpha: 0.55,
      ),
      drawer: const AppDrawer(
        currentRoute:
            AppRoutes.favorites,
      ),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar:
          const AppBottomNavigation(
        currentIndex: 4,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor:
          AppTheme.background,
      surfaceTintColor:
          Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) {
          return IconButton(
            onPressed: () {
              Scaffold.of(context)
                  .openDrawer();
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
      title: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                BoxDecoration(
              color:
                  AppTheme.darkGreen,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Yêu thích',
            style: TextStyle(
              color: AppTheme.black,
              fontSize: 20,
              fontWeight:
                  FontWeight.w700,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip:
              'Tải lại',
          onPressed:
              _isLoading
                  ? null
                  : _loadFavorites,
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppTheme.black,
            size: 26,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: AppTheme.darkGreen,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_favorites.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppTheme.darkGreen,
      onRefresh: _loadFavorites,
      child: GridView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(
          parent:
              BouncingScrollPhysics(),
        ),
        padding:
            const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          30,
        ),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.57,
        ),
        itemCount:
            _favorites.length,
        itemBuilder:
            (context, index) {
          final favorite =
              _favorites[index];

          return _FavoriteMovieCard(
            favorite: favorite,
            onTap: () async {
              final movie =
                  _favoriteToMovie(
                favorite,
              );

              await Navigator.pushNamed(
                context,
                AppRoutes.movieDetail,
                arguments: movie,
              );

              if (mounted) {
                await _loadFavorites();
              }
            },
            onFavoriteTap: () {
              _removeFavorite(
                favorite,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration:
                  BoxDecoration(
                color:
                    AppTheme.darkGreen
                        .withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .favorite_border_rounded,
                color:
                    AppTheme.darkGreen,
                size: 44,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Chưa có phim yêu thích',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    AppTheme.black,
                fontSize: 21,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy thêm những bộ phim bạn yêu thích để xem lại nhanh hơn.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    AppTheme.grey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.home,
                );
              },
              icon: const Icon(
                Icons.movie_filter_rounded,
              ),
              label: const Text(
                'Khám phá phim',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppTheme.darkGreen,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration:
                  BoxDecoration(
                color:
                    Colors.red.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .error_outline_rounded,
                color: Colors.red,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Không tải được Favorites',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    AppTheme.black,
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'Đã xảy ra lỗi.',
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color:
                    AppTheme.grey,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed:
                  _loadFavorites,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Thử lại',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppTheme.darkGreen,
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteMovieCard
    extends StatelessWidget {
  final Favorite favorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _FavoriteMovieCard({
    required this.favorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child:
                        _buildPoster(),
                  ),

                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black
                          .withValues(
                        alpha: 0.55,
                      ),
                      shape:
                          const CircleBorder(),
                      child: InkWell(
                        customBorder:
                            const CircleBorder(),
                        onTap:
                            onFavoriteTap,
                        child:
                            const Padding(
                          padding:
                              EdgeInsets.all(
                            9,
                          ),
                          child: Icon(
                            Icons
                                .favorite_rounded,
                            color:
                                Colors.redAccent,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 9),

            Text(
              favorite.title,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color:
                    AppTheme.black,
                fontSize: 14,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                if (favorite.releaseYear !=
                    null)
                  Text(
                    favorite.releaseYear
                        .toString(),
                    style:
                        const TextStyle(
                      color:
                          AppTheme.grey,
                      fontSize: 11,
                    ),
                  ),
                if (favorite.releaseYear !=
                        null &&
                    favorite.duration !=
                        null)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 5,
                    ),
                    child: Text(
                      '•',
                      style:
                          TextStyle(
                        color:
                            AppTheme.grey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (favorite.duration !=
                    null)
                  Text(
                    '${favorite.duration} phút',
                    style:
                        const TextStyle(
                      color:
                          AppTheme.grey,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster() {
    final posterUrl =
        favorite.posterUrl
            ?.trim();

    if (posterUrl == null ||
        posterUrl.isEmpty) {
      return Container(
        decoration:
            BoxDecoration(
          color:
              AppTheme.darkGreen,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.movie_rounded,
            color: Colors.white,
            size: 42,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(18),
      child: Image.network(
        posterUrl,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stack) {
          return Container(
            color:
                AppTheme.darkGreen,
            child: const Center(
              child: Icon(
                Icons
                    .broken_image_rounded,
                color:
                    Colors.white,
                size: 40,
              ),
            ),
          );
        },
        loadingBuilder:
            (context, child, progress) {
          if (progress == null) {
            return child;
          }

          return Container(
            color:
                AppTheme.darkGreen
                    .withValues(
              alpha: 0.12,
            ),
            child:
                const Center(
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color:
                    AppTheme.darkGreen,
              ),
            ),
          );
        },
      ),
    );
  }
}

