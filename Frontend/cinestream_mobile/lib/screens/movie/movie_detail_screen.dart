import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../providers/auth_provider.dart';
import '../../services/favorite_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';

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
      FavoriteService.instance;

  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  bool _isUpdatingFavorite = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFavoriteStatus();
    });
  }

  Future<void> _checkFavoriteStatus() async {
    final movie = widget.movie;

    if (movie == null) {
      return;
    }

    final authProvider =
        context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isFavorite = false;
        _isCheckingFavorite = false;
      });

      return;
    }

    try {
      final isFavorite =
          await _favoriteService.checkFavorite(
        movie.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isFavorite = isFavorite;
        _isCheckingFavorite = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final movie = widget.movie;

    if (movie == null ||
        _isUpdatingFavorite) {
      return;
    }

    final authProvider =
        context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      _showMessage(
        'Bạn cần đăng nhập để sử dụng Phim yêu thích.',
      );

      Navigator.pushNamed(
        context,
        AppRoutes.login,
      );

      return;
    }

    setState(() {
      _isUpdatingFavorite = true;
    });

    try {
      if (_isFavorite) {
        await _favoriteService.removeFavorite(
          movie.id,
        );
      } else {
        await _favoriteService.addFavorite(
          movie.id,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isFavorite = !_isFavorite;
        _isUpdatingFavorite = false;
      });

      _showMessage(
        _isFavorite
            ? 'Đã thêm vào phim yêu thích.'
            : 'Đã bỏ khỏi phim yêu thích.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingFavorite = false;
      });

      _showMessage(
        _cleanErrorMessage(e),
      );
    }
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
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
  Widget build(
    BuildContext context,
  ) {
    final currentMovie = widget.movie;

    if (currentMovie == null) {
      return Scaffold(
        backgroundColor:
            AppTheme.background,
        appBar: AppBar(
          backgroundColor:
              AppTheme.background,
          elevation: 0,
          title: const Text(
            'Chi tiết phim',
          ),
        ),
        body: const Center(
          child: Text(
            'Không tìm thấy thông tin phim.',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

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
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding:
                  const EdgeInsets.only(
                bottom: 105,
              ),
              physics:
                  const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(
                    currentMovie,
                  ),
                  _buildMovieInfo(
                    context,
                    currentMovie,
                  ),
                  _buildContentSection(
                    currentMovie,
                  ),
                  _buildMovieMetadata(
                    currentMovie,
                  ),
                ],
              ),
            ),
            _buildTopBar(
              context,
              currentMovie,
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const AppBottomNavigation(
        currentIndex: 0,
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    Movie currentMovie,
  ) {
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
          gradient:
              LinearGradient(
            begin:
                Alignment.topCenter,
            end:
                Alignment.bottomCenter,
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
                currentMovie.title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
            _circleButton(
              icon: _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              iconColor: _isFavorite
                  ? Colors.pinkAccent
                  : Colors.white,
              onTap:
                  _toggleFavorite,
              isLoading:
                  _isCheckingFavorite ||
                      _isUpdatingFavorite,
            ),
            const SizedBox(width: 8),
            Builder(
              builder:
                  (scaffoldContext) {
                return _circleButton(
                  icon:
                      Icons.menu_rounded,
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
    Color iconColor = Colors.white,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.black.withValues(
        alpha: 0.35,
      ),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder:
            const CircleBorder(),
        onTap: isLoading ? null : onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: isLoading
              ? const Padding(
                  padding:
                      EdgeInsets.all(11),
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(
    Movie currentMovie,
  ) {
    final posterUrl =
        currentMovie.posterUrl?.trim();

    return SizedBox(
      width: double.infinity,
      height: 405,
      child: Stack(
        fit: StackFit.expand,
        children: [
          posterUrl == null ||
                  posterUrl.isEmpty
              ? _buildHeroPlaceholder()
              : Image.network(
                  posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return _buildHeroPlaceholder();
                  },
                ),
          Container(
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(
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
                  1.0,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPlaceholder() {
    return Container(
      decoration:
          const BoxDecoration(
        gradient:
            LinearGradient(
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
          Icons.movie_creation_outlined,
          color: Colors.white30,
          size: 90,
        ),
      ),
    );
  }

  Widget _buildMovieInfo(
    BuildContext context,
    Movie currentMovie,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
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
            currentMovie.title,
            style:
                const TextStyle(
              color: AppTheme.black,
              fontSize: 31,
              fontWeight:
                  FontWeight.w900,
              fontFamily: 'Georgia',
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 13),
          _buildMetaInfo(
            currentMovie,
          ),
          const SizedBox(height: 19),
          SizedBox(
            width: double.infinity,
            height: 51,
            child:
                ElevatedButton.icon(
              onPressed:
                  currentMovie.videoStatus ==
                          1
                      ? () {
                          _openVideoPlayer(
                            context,
                            currentMovie,
                          );
                        }
                      : null,
              icon:
                  const Icon(
                Icons.play_arrow_rounded,
                size: 24,
              ),
              label: Text(
                currentMovie.videoStatus ==
                        1
                    ? 'Xem phim'
                    : 'Video chưa sẵn sàng',
                style:
                    const TextStyle(
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
                disabledBackgroundColor:
                    AppTheme.lightGrey,
                disabledForegroundColor:
                    AppTheme.grey,
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
        ],
      ),
    );
  }

  Widget _buildMetaInfo(
    Movie currentMovie,
  ) {
    final items =
        <Widget>[];

    if (currentMovie.duration !=
        null) {
      items.add(
        _metaItem(
          Icons.schedule_rounded,
          _formatDuration(
            currentMovie.duration,
          ),
        ),
      );
    }

    if (currentMovie.releaseYear !=
        null) {
      items.add(
        _metaText(
          currentMovie.releaseYear!
              .toString(),
        ),
      );
    }

    items.add(
      _metaText(
        currentMovie.isSeries
            ? 'Phim bộ'
            : 'Phim lẻ',
      ),
    );

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment:
          WrapCrossAlignment.center,
      children: items,
    );
  }

  Widget _metaItem(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppTheme.grey,
          size: 17,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style:
              const TextStyle(
            color: AppTheme.grey,
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _metaText(
    String text,
  ) {
    return Text(
      text,
      style:
          const TextStyle(
        color: AppTheme.grey,
        fontSize: 13,
        fontWeight:
            FontWeight.w600,
      ),
    );
  }

  Widget _buildContentSection(
    Movie currentMovie,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
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
            style:
                TextStyle(
              color: AppTheme.black,
              fontSize: 21,
              fontWeight:
                  FontWeight.w900,
              fontFamily:
                  'Georgia',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currentMovie.description ??
                'Chưa có mô tả cho bộ phim này.',
            style:
                const TextStyle(
              color: AppTheme.grey,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieMetadata(
    Movie currentMovie,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
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
            'Thông tin',
            style:
                TextStyle(
              color: AppTheme.black,
              fontSize: 21,
              fontWeight:
                  FontWeight.w900,
              fontFamily:
                  'Georgia',
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          if (currentMovie.categories
              .isNotEmpty)
            _buildInfoRow(
              'Thể loại',
              currentMovie.categories
                  .map(
                    (category) =>
                        category.name,
                  )
                  .join(', '),
            ),
          _buildInfoRow(
            'Loại',
            currentMovie.isSeries
                ? 'Phim bộ'
                : 'Phim lẻ',
          ),
          _buildInfoRow(
            'Video',
            currentMovie.videoStatus ==
                    1
                ? 'Sẵn sàng'
                : 'Chưa có video',
          ),
          if (currentMovie
                      .streamType
                      .isNotEmpty &&
                  currentMovie
                          .streamType !=
                      'NONE')
            _buildInfoRow(
              'Kiểu phát',
              currentMovie.streamType,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style:
                  const TextStyle(
                color: AppTheme.grey,
                fontSize: 12.5,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                color: AppTheme.black,
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(
    int? duration,
  ) {
    if (duration == null ||
        duration <= 0) {
      return '--';
    }

    final hours =
        duration ~/ 60;
    final minutes =
        duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }

    return '${minutes}m';
  }

  void _openVideoPlayer(
    BuildContext context,
    Movie currentMovie,
  ) {
    Navigator.pushNamed(
      context,
      AppRoutes.player,
      arguments: currentMovie,
    );
  }
}