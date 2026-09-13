import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/favorite.dart';
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

  List<Favorite> _favorites = const [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
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
        _favorites = const [];
        _isLoading = false;
        _errorMessage =
            _cleanErrorMessage(e);
      });
    }
  }

  void _openMovie(Favorite favorite) {
    Navigator.pushNamed(
      context,
      AppRoutes.movieDetail,
      arguments: favorite.toMovie(),
    ).then((_) {
      _loadFavorites();
    });
  }

  String _cleanErrorMessage(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.background,
      drawerScrimColor:
          Colors.black.withValues(
        alpha: 0.58,
      ),
      drawer: const AppDrawer(
        currentRoute: null,
      ),
      appBar: AppBar(
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
        title: const Text(
          'Phim yêu thích',
          style: TextStyle(
            color: AppTheme.black,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            fontFamily: 'Georgia',
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.darkGreen,
        onRefresh: _loadFavorites,
        child: _buildBody(),
      ),
      bottomNavigationBar:
          const AppBottomNavigation(
        currentIndex: 4,
      ),
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
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.cloud_off_rounded,
            color: AppTheme.grey,
            size: 48,
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
          Center(
            child: ElevatedButton(
              onPressed: _loadFavorites,
              child:
                  const Text('Thử lại'),
            ),
          ),
        ],
      );
    }

    if (_favorites.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.favorite_border_rounded,
            color: AppTheme.grey,
            size: 58,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có phim yêu thích',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.black,
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Nhấn biểu tượng trái tim ở trang chi tiết phim để lưu phim vào danh sách này.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        30,
      ),
      physics:
          const AlwaysScrollableScrollPhysics(
        parent:
            BouncingScrollPhysics(),
      ),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemCount: _favorites.length,
      itemBuilder:
          (context, index) {
        return _buildFavoriteCard(
          _favorites[index],
        );
      },
    );
  }

  Widget _buildFavoriteCard(
    Favorite favorite,
  ) {
    final posterUrl =
        favorite.posterUrl?.trim();

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          _openMovie(favorite);
        },
        borderRadius:
            BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.only(
                  topLeft:
                      Radius.circular(18),
                  topRight:
                      Radius.circular(18),
                ),
                child:
                    posterUrl == null ||
                            posterUrl.isEmpty
                        ? _buildPosterPlaceholder()
                        : Image.network(
                            posterUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return _buildPosterPlaceholder();
                            },
                          ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  10,
                  9,
                  10,
                  8,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite.title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            AppTheme.black,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _favoriteInfo(
                        favorite,
                      ),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            AppTheme.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterPlaceholder() {
    return Container(
      width: double.infinity,
      color: AppTheme.lightGrey,
      alignment: Alignment.center,
      child: const Icon(
        Icons.movie_outlined,
        color: AppTheme.grey,
        size: 42,
      ),
    );
  }

  String _favoriteInfo(
    Favorite favorite,
  ) {
    final parts = <String>[];

    if (favorite.releaseYear !=
        null) {
      parts.add(
        favorite.releaseYear!
            .toString(),
      );
    }

    if (favorite.duration !=
            null &&
        favorite.duration! > 0) {
      parts.add(
        '${favorite.duration} phút',
      );
    }

    return parts.join(' • ');
  }
}