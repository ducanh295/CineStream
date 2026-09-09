import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final List<String> _popularKeywords = [
    'Thriller',
    'Sci-Fi',
    '2024',
    'Oscar',
    'Drama',
    'Animation',
  ];

  final List<Movie> _movies = [
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
      title: 'Ember & Ash',
      description:
          'Một câu chuyện đầy cảm xúc về những con người đang tìm kiếm nhau...',
      posterUrl:
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23',
      releaseYear: 2024,
      duration: 116,
      averageRating: 7.9,
      viewCount: 105000,
    ),
    Movie(
      id: 3,
      title: 'Neon Dharma',
      description:
          'Cuộc hành trình giữa thành phố tương lai và những bí mật bị che giấu...',
      posterUrl:
          'https://images.unsplash.com/photo-1519608487953-e999c86e7455',
      releaseYear: 2024,
      duration: 121,
      averageRating: 8.1,
      viewCount: 124000,
    ),
    Movie(
      id: 4,
      title: 'Cold Latitude',
      description:
          'Cuộc phiêu lưu giữa những dãy núi băng giá và vùng đất chưa được khám phá...',
      posterUrl:
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b',
      releaseYear: 2023,
      duration: 124,
      averageRating: 7.6,
      viewCount: 73000,
    ),
    Movie(
      id: 5,
      title: 'The Quiet Algorithm',
      description:
          'Một thuật toán tưởng như vô hại lại mở ra một bí mật nguy hiểm...',
      posterUrl:
          'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba',
      releaseYear: 2024,
      duration: 118,
      averageRating: 8.7,
      viewCount: 118000,
    ),
    Movie(
      id: 6,
      title: 'Marea',
      description:
          'Một câu chuyện tình yêu bắt đầu từ những ký ức tưởng như đã biến mất...',
      posterUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9',
      releaseYear: 2024,
      duration: 105,
      averageRating: 7.3,
      viewCount: 54000,
    ),
    Movie(
      id: 7,
      title: 'Ghost Protocol: Kyoto',
      description:
          'Một nhiệm vụ bí mật đưa đặc vụ trẻ đến thành phố Kyoto...',
      posterUrl:
          'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e',
      releaseYear: 2024,
      duration: 127,
      averageRating: 8.5,
      viewCount: 143000,
    ),
    Movie(
      id: 8,
      title: 'Saltwater Saints',
      description:
          'Những con người xa lạ gặp nhau bên bờ biển và thay đổi cuộc đời nhau...',
      posterUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
      releaseYear: 2023,
      duration: 110,
      averageRating: 7.8,
      viewCount: 69000,
    ),
  ];

  List<Movie> _filteredMovies = [];

  @override
  void initState() {
    super.initState();

    _filteredMovies = List<Movie>.from(_movies);

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    final keyword =
        _searchController.text.trim().toLowerCase();

    setState(() {
      if (keyword.isEmpty) {
        _filteredMovies =
            List<Movie>.from(_movies);
      } else {
        _filteredMovies = _movies.where((movie) {
          final title =
              movie.title.toLowerCase();

          final description =
              movie.description?.toLowerCase() ?? '';

          return title.contains(keyword) ||
              description.contains(keyword);
        }).toList();
      }
    });
  }

  void _selectKeyword(String keyword) {
    _searchController.text = keyword;

    _searchController.selection =
        TextSelection.fromPosition(
      TextPosition(
        offset: _searchController.text.length,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawerScrimColor: Colors.black.withValues(
        alpha: 0.58,
      ),
      drawer: const AppDrawer(
        currentRoute: AppRoutes.search,
      ),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  bottom: 24,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    _buildSearchBox(),
                    _buildPopularSearches(),
                    _buildResultsHeader(),
                    _buildResultsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const AppBottomNavigation(
        currentIndex: 1,
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

  Widget _buildTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        18,
      ),
      child: Text(
        'Tìm kiếm',
        style: TextStyle(
          color: AppTheme.black,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          fontFamily: 'Georgia',
          height: 1.05,
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: TextField(
        controller: _searchController,
        textInputAction:
            TextInputAction.search,
        decoration: InputDecoration(
          hintText:
              'Tìm phim, đạo diễn, diễn viên...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.darkGreen,
            size: 25,
          ),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.grey,
                      ),
                    )
                  : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppTheme.darkGreen,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularSearches() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        26,
        20,
        6,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'TÌM KIẾM PHỔ BIẾN',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 9,
            children:
                _popularKeywords.map(
              (keyword) {
                return GestureDetector(
                  onTap: () {
                    _selectKeyword(keyword);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(30),
                      border: Border.all(
                        color: AppTheme.darkGreen
                            .withValues(
                          alpha: 0.14,
                        ),
                      ),
                    ),
                    child: Text(
                      keyword,
                      style:
                          const TextStyle(
                        color: AppTheme.black,
                        fontSize: 12.5,
                        fontWeight:
                            FontWeight.w600,
                      ),
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

  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        27,
        20,
        13,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'KẾT QUẢ PHIM',
              style: TextStyle(
                color: AppTheme.black,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '${_filteredMovies.length} phim',
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_filteredMovies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          40,
          20,
          60,
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.movie_outlined,
                size: 55,
                color: AppTheme.grey.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Không tìm thấy phim phù hợp',
                style: TextStyle(
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
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: _filteredMovies.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final movie = _filteredMovies[index];

        return _buildMovieResultCard(movie);
      },
    );
  }

  Widget _buildMovieResultCard(Movie movie) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: () {
          _openMovieDetail(movie);
        },
        child: Container(
          padding:
              const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(20),
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
                  height: 128,
                  child: Image.network(
                    movie.posterUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) {
                      return Container(
                        color:
                            AppTheme.lightGrey,
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
              const SizedBox(width: 13),
              Expanded(
                child: SizedBox(
                  height: 128,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
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
                      const SizedBox(
                          height: 7),
                      Text(
                        'Thriller • '
                        '${movie.releaseYear ?? '----'} • '
                        '${movie.duration ?? '--'} phút',
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
                      const SizedBox(
                          height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color:
                                AppTheme.yellow,
                            size: 16,
                          ),
                          const SizedBox(
                              width: 3),
                          Text(
                            movie.averageRating
                                .toStringAsFixed(
                              1,
                            ),
                            style:
                                const TextStyle(
                              color:
                                  AppTheme.black,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                          height: 7),
                      Expanded(
                        child: Text(
                          movie.description ??
                              'Chưa có mô tả...',
                          maxLines: 3,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color:
                                AppTheme.grey,
                            fontSize: 11.5,
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}