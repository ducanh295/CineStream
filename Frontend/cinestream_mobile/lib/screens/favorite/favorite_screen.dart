import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category.dart';
import '../../models/favorite.dart';
import '../../models/movie.dart';
import '../../services/auth_service.dart';
import '../../services/favorite_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() =>
      _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final FavoriteService _favoriteService =
      FavoriteService();

  final AuthService _authService =
      AuthService.instance;

  List<Favorite> _favorites = [];

  bool _isLoading = true;
  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // ============================================================
  // LOAD FAVORITES
  // ============================================================

  Future<void> _loadFavorites() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _authService.getToken();

      if (!mounted) {
        return;
      }

      if (token == null || token.trim().isEmpty) {
        setState(() {
          _token = null;
          _favorites = [];
          _isLoading = false;
          _error =
              'Bạn cần đăng nhập để xem danh sách yêu thích.';
        });

        return;
      }

      final favorites =
          await _favoriteService.getFavorites(
        token,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _token = token;
        _favorites = favorites;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst(
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
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar:
          const AppBottomNavigation(
        currentIndex: 3,
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
          onPressed: _loadFavorites,
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppTheme.black,
            size: 25,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_favorites.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          30,
        ),
        physics:
            const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _favorites.length + 1,
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
          if (index == 0) {
            return _buildPageHeader();
          }

          final favorite =
              _favorites[index - 1];

          return _buildFavoriteCard(
            favorite,
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách yêu thích',
          style: TextStyle(
            color: AppTheme.black,
            fontSize: 31,
            fontWeight: FontWeight.w900,
            fontFamily: 'Georgia',
            height: 1.05,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_favorites.length} phim',
          style: const TextStyle(
            color: AppTheme.grey,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FAVORITE CARD
  // ============================================================

  Widget _buildFavoriteCard(
    Favorite favorite,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          _openMovieDetail(favorite);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(10),
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
                    favorite.posterUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Container(
                        color:
                            AppTheme.lightGrey,
                        child: const Center(
                          child: Icon(
                            Icons.movie_outlined,
                            color:
                                AppTheme.grey,
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
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              favorite.title,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    AppTheme.black,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          GestureDetector(
                            onTap: () {
                              _removeFavorite(
                                favorite,
                              );
                            },
                            child: const Padding(
                              padding:
                                  EdgeInsets.all(2),
                              child: Icon(
                                Icons
                                    .bookmark_rounded,
                                color:
                                    AppTheme.darkGreen,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _buildMovieInfo(
                          favorite,
                        ),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AppTheme.grey,
                          fontSize: 11.5,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          favorite.description ??
                              'Chưa có mô tả...',
                          maxLines: 3,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color:
                                AppTheme.grey,
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

  // ============================================================
  // MOVIE INFO
  // ============================================================

  String _buildMovieInfo(
    Favorite favorite,
  ) {
    final parts = <String>[];

    if (favorite.categories.isNotEmpty) {
      parts.add(
        favorite.categories
            .take(2)
            .join(' • '),
      );
    } else {
      parts.add('Movie');
    }

    if (favorite.releaseYear != null) {
      parts.add(
        favorite.releaseYear.toString(),
      );
    }

    if (favorite.duration != null &&
        favorite.duration! > 0) {
      final hours =
          favorite.duration! ~/ 60;
      final minutes =
          favorite.duration! % 60;

      if (hours > 0) {
        parts.add(
          minutes > 0
              ? '${hours}h ${minutes}m'
              : '${hours}h',
        );
      } else {
        parts.add(
          '${minutes}m',
        );
      }
    }

    return parts.join(' • ');
  }

  // ============================================================
  // REMOVE FAVORITE
  // ============================================================

  Future<void> _removeFavorite(
    Favorite favorite,
  ) async {
    final token = _token;

    if (token == null ||
        token.trim().isEmpty) {
      _showMessage(
        'Phiên đăng nhập không hợp lệ.',
      );
      return;
    }

    try {
      await _favoriteService.removeFavorite(
        token,
        favorite.movieId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _favorites.removeWhere(
          (item) =>
              item.movieId ==
              favorite.movieId,
        );
      });

      _showMessage(
        'Đã bỏ phim khỏi danh sách yêu thích.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ============================================================
  // OPEN MOVIE DETAIL
  // ============================================================

  void _openMovieDetail(
    Favorite favorite,
  ) {
    final categories =
        favorite.categories
            .map(
              (name) => Category(
                id: 0,
                name: name,
              ),
            )
            .toList();

    final movie = Movie(
      id: favorite.movieId,
      title: favorite.title,
      description: favorite.description,
      posterUrl: favorite.posterUrl,
      trailerUrl: favorite.trailerUrl,
      duration: favorite.duration,
      releaseYear: favorite.releaseYear,
      categories: categories,
    );

    Navigator.pushNamed(
      context,
      AppRoutes.movieDetail,
      arguments: movie,
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppTheme.darkGreen
                    .withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .bookmark_border_rounded,
                color:
                    AppTheme.darkGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Danh sách đang trống',
              style: TextStyle(
                color: AppTheme.black,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Những bộ phim bạn lưu sẽ xuất hiện ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.grey,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.home,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppTheme.darkGreen,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    25,
                  ),
                ),
              ),
              child: const Text(
                'Khám phá phim',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

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
              size: 50,
            ),
            const SizedBox(height: 14),
            const Text(
              'Không thể tải danh sách',
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
              onPressed: _loadFavorites,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
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