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
  State<CategoryScreen> createState() =>
      _CategoryScreenState();
}

class _CategoryScreenState
    extends State<CategoryScreen> {
  final CategoryService _categoryService =
      CategoryService.instance;

  final MovieService _movieService =
      MovieService.instance;

  List<Category> _categories = const [];
  List<Movie> _movies = const [];

  int? _selectedCategoryId;

  // Trạng thái phân trang danh sách phim
  int _currentPage = 1;
  static const int _pageSize = 6;
  int _totalPages = 1;
  int _totalCount = 0;
  final ScrollController _scrollController = ScrollController();

  bool _isLoadingCategories = true;
  bool _isLoadingMovies = false;

  String? _categoryError;
  String? _movieError;

  @override
  void initState() {
    super.initState();

    _loadCategories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ================================================================
  // LOAD CATEGORIES
  // ================================================================

  Future<void> _loadCategories() async {
    if (mounted) {
      setState(() {
        _isLoadingCategories = true;
        _categoryError = null;
      });
    }

    try {
      final categories =
          await _categoryService.getCategories();

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;

        // Nếu category đang chọn không còn tồn tại
        // thì reset về tất cả phim.
        if (_selectedCategoryId != null &&
            !_categories.any(
              (category) =>
                  category.id ==
                  _selectedCategoryId,
            )) {
          _selectedCategoryId = null;
        }
      });

      await _loadMovies(
        categoryId: _selectedCategoryId,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _categoryError =
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                );
        _isLoadingCategories = false;
      });
    }
  }

  // ================================================================
  // LOAD MOVIES
  // ================================================================

  Future<void> _loadMovies({
    int? categoryId,
    int page = 1,
  }) async {
    if (mounted) {
      setState(() {
        _isLoadingMovies = true;
        _movieError = null;
        _currentPage = page;
      });
    }

    try {
      final pagedResult = await _movieService.getPagedMovies(
        categoryId: categoryId,
        page: page,
        pageSize: _pageSize,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _movies = pagedResult.items;
        _totalCount = pagedResult.totalCount;
        _totalPages = pagedResult.totalPages > 0 ? pagedResult.totalPages : 1;
        _currentPage = pagedResult.pageNumber;
        _isLoadingMovies = false;
      });

      // Cuộn mượt lên đầu danh sách phim khi chuyển trang
      if (page > 1 && _scrollController.hasClients) {
        _scrollController.animateTo(
          220,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _movieError =
            e.toString().replaceFirst('Exception: ', '');
        _isLoadingMovies = false;
      });
    }
  }

  // ================================================================
  // SELECT CATEGORY
  // ================================================================

  Future<void> _selectCategory(
    Category category,
  ) async {
    final isSelected =
        _selectedCategoryId ==
        category.id;

    final newCategoryId =
        isSelected
            ? null
            : category.id;

    setState(() {
      _selectedCategoryId =
          newCategoryId;
      _currentPage = 1;
    });

    await _loadMovies(
      categoryId:
          newCategoryId,
      page: 1,
    );
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> _refresh() async {
    await _loadCategories();
  }

  // ================================================================
  // BUILD
  // ================================================================

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
        currentRoute:
            AppRoutes.category,
      ),

      appBar:
          _buildAppBar(context),

      body: SafeArea(
        child:
            RefreshIndicator(
          color:
              AppTheme.darkGreen,
          onRefresh:
              _refresh,
          child:
              SingleChildScrollView(
            controller: _scrollController,
            physics:
                const AlwaysScrollableScrollPhysics(
              parent:
                  BouncingScrollPhysics(),
            ),
            padding:
                const EdgeInsets.only(
              bottom: 24,
            ),
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                _buildPageTitle(),
                _buildCategorySection(),
                _buildAllMoviesTitle(),
                _buildMovieSection(),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar:
          const AppBottomNavigation(
        currentIndex: 2,
      ),
    );
  }

  // ================================================================
  // APP BAR
  // ================================================================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
  ) {
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
              Scaffold.of(
                context,
              ).openDrawer();
            },
            icon:
                const Icon(
              Icons.menu_rounded,
              color:
                  AppTheme.black,
              size: 28,
            ),
          );
        },
      ),
      centerTitle: true,
      title:
          const Text(
        'CineStream',
        style:
            TextStyle(
          color:
              AppTheme.black,
          fontSize: 23,
          fontWeight:
              FontWeight.w900,
          fontFamily:
              'Georgia',
          letterSpacing:
              -0.4,
        ),
      ),
    );
  }

  // ================================================================
  // PAGE TITLE
  // ================================================================

  Widget _buildPageTitle() {
    return const Padding(
      padding:
          EdgeInsets.fromLTRB(
        20,
        12,
        20,
        22,
      ),
      child:
          Text(
        'Danh mục',
        style:
            TextStyle(
          color:
              AppTheme.black,
          fontSize: 32,
          fontWeight:
              FontWeight.w900,
          fontFamily:
              'Georgia',
          height: 1.05,
          letterSpacing:
              -0.5,
        ),
      ),
    );
  }

  // ================================================================
  // CATEGORY SECTION
  // ================================================================

  Widget _buildCategorySection() {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 120,
        child:
            Center(
          child:
              CircularProgressIndicator(
            color:
                AppTheme.darkGreen,
          ),
        ),
      );
    }

    if (_categoryError != null) {
      return Padding(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20,
        ),
        child:
            _buildErrorCard(
          _categoryError!,
          _loadCategories,
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Padding(
        padding:
            EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20,
        ),
        child:
            Text(
          'Chưa có thể loại nào.',
          style:
              TextStyle(
            color:
                AppTheme.grey,
            fontSize: 14,
          ),
        ),
      );
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child:
          GridView.builder(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        itemCount:
            _categories.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 72,
        ),
        itemBuilder:
            (context, index) {
          final category =
              _categories[index];

          return _buildCategoryCard(
            category,
          );
        },
      ),
    );
  }

  // ================================================================
  // CATEGORY CARD
  // ================================================================

  Widget _buildCategoryCard(
    Category category,
  ) {
    final selected =
        _selectedCategoryId ==
        category.id;

    return Material(
      color:
          selected
              ? AppTheme.darkGreen
                  .withValues(
                  alpha: 0.10,
                )
              : Colors.white,
      borderRadius:
          BorderRadius.circular(
        16,
      ),
      child:
          InkWell(
        onTap: () =>
            _selectCategory(
          category,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        child:
            Container(
          width:
              double.infinity,
          alignment:
              Alignment.center,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration:
              BoxDecoration(
            color:
                selected
                    ? AppTheme
                        .darkGreen
                        .withValues(
                        alpha: 0.10,
                      )
                    : Colors.white,
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            border:
                Border.all(
              color:
                  selected
                      ? AppTheme
                          .darkGreen
                      : AppTheme
                          .darkGreen
                          .withValues(
                        alpha: 0.10,
                      ),
              width:
                  selected
                      ? 1.2
                      : 1,
            ),
          ),
          child:
              Text(
            category.name,
            maxLines: 2,
            textAlign:
                TextAlign.center,
            overflow:
                TextOverflow.ellipsis,
            style:
                TextStyle(
              color:
                  selected
                      ? AppTheme
                          .darkGreen
                      : AppTheme
                          .black,
              fontSize: 14,
              fontWeight:
                  selected
                      ? FontWeight
                          .w800
                      : FontWeight
                          .w700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // MOVIES TITLE
  // ================================================================

  Widget _buildAllMoviesTitle() {
    final selectedCategory =
        _selectedCategoryId ==
                null
            ? null
            : _findSelectedCategory();

    final titleText = selectedCategory == null
        ? (_totalCount > 0 ? 'TẤT CẢ PHIM ($_totalCount)' : 'TẤT CẢ PHIM')
        : (_totalCount > 0
            ? '${selectedCategory.name.toUpperCase()} ($_totalCount)'
            : selectedCategory.name.toUpperCase());

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        31,
        20,
        14,
      ),
      child:
          Row(
        children: [
          Expanded(
            child:
                Text(
              titleText,
              style:
                  const TextStyle(
                color:
                    AppTheme.black,
                fontSize: 15,
                fontWeight:
                    FontWeight.w900,
                letterSpacing:
                    0.7,
              ),
            ),
          ),

          if (_selectedCategoryId !=
              null)
            TextButton(
              onPressed:
                  selectedCategory ==
                          null
                      ? null
                      : () {
                          _selectCategory(
                            selectedCategory,
                          );
                        },
              child:
                  const Text(
                'Bỏ lọc',
              ),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // MOVIE SECTION
  // ================================================================

  Widget _buildMovieSection() {
    if (_isLoadingMovies) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical: 70,
        ),
        child:
            Center(
          child:
              CircularProgressIndicator(
            color:
                AppTheme.darkGreen,
          ),
        ),
      );
    }

    if (_movieError != null) {
      return Padding(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20,
        ),
        child:
            _buildErrorCard(
          _movieError!,
          () => _loadMovies(
            categoryId:
                _selectedCategoryId,
          ),
        ),
      );
    }

    if (_movies.isEmpty) {
      return const Padding(
        padding:
            EdgeInsets.fromLTRB(
          20,
          0,
          20,
          40,
        ),
        child:
            Center(
          child:
              Text(
            'Không có phim nào.',
            style:
                TextStyle(
              color:
                  AppTheme.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.separated(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount:
              _movies.length,
          separatorBuilder:
              (context, index) {
            return const SizedBox(
              height: 12,
            );
          },
          itemBuilder:
              (context, index) {
            return _buildMovieCard(
              context,
              _movies[index],
            );
          },
        ),
        if (_totalPages > 1) _buildPaginationControls(),
      ],
    );
  }

  // ================================================================
  // PAGINATION CONTROLS
  // ================================================================

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Nút chuyển về trang trước
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _currentPage > 1 && !_isLoadingMovies
                  ? () => _loadMovies(
                        categoryId: _selectedCategoryId,
                        page: _currentPage - 1,
                      )
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _currentPage > 1
                      ? AppTheme.darkGreen.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: _currentPage > 1 ? AppTheme.darkGreen : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Trước',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _currentPage > 1 ? AppTheme.darkGreen : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hiển thị danh sách số trang
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_totalPages, (index) {
                final pageNumber = index + 1;
                final isSelected = pageNumber == _currentPage;

                // Giới hạn hiển thị nếu có quá nhiều trang
                if (_totalPages > 5) {
                  if (pageNumber != 1 &&
                      pageNumber != _totalPages &&
                      (pageNumber - _currentPage).abs() > 1) {
                    if (pageNumber == 2 || pageNumber == _totalPages - 1) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          '..',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                }

                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: !isSelected && !_isLoadingMovies
                      ? () => _loadMovies(
                            categoryId: _selectedCategoryId,
                            page: pageNumber,
                          )
                      : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.darkGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$pageNumber',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.black,
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Nút chuyển sang trang kế tiếp
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _currentPage < _totalPages && !_isLoadingMovies
                  ? () => _loadMovies(
                        categoryId: _selectedCategoryId,
                        page: _currentPage + 1,
                      )
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _currentPage < _totalPages
                      ? AppTheme.darkGreen.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      'Sau',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _currentPage < _totalPages ? AppTheme.darkGreen : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: _currentPage < _totalPages ? AppTheme.darkGreen : Colors.grey,
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

  // ================================================================
  // MOVIE CARD
  // ================================================================

  Widget _buildMovieCard(
    BuildContext context,
    Movie movie,
  ) {
    return Material(
      color:
          Colors.white,
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      child:
          InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.movieDetail,
            arguments:
                movie,
          );
        },
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        child:
            Container(
          padding:
              const EdgeInsets.all(
            10,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.white,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
          child:
              Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
                child:
                    SizedBox(
                  width:
                      92,
                  height:
                      122,
                  child:
                      Image.network(
                    movie.posterUrl ??
                        '',
                    fit:
                        BoxFit.cover,
                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Container(
                        color:
                            AppTheme
                                .lightGrey,
                        child:
                            const Center(
                          child:
                              Icon(
                            Icons
                                .movie_outlined,
                            color:
                                AppTheme
                                    .grey,
                            size:
                                34,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(
                width:
                    13,
              ),

              Expanded(
                child:
                    SizedBox(
                  height:
                      122,
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        movie.title,
                        maxLines:
                            2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AppTheme
                                  .black,
                          fontSize:
                              16,
                          fontWeight:
                              FontWeight
                                  .w900,
                        ),
                      ),

                      const SizedBox(
                        height:
                            7,
                      ),

                      Text(
                        _movieInfo(
                          movie,
                        ),
                        maxLines:
                            1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AppTheme
                                  .grey,
                          fontSize:
                              11.5,
                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      if (movie
                          .categories
                          .isNotEmpty)
                        Text(
                          movie
                              .categories
                              .map(
                                (
                                  item,
                                ) =>
                                    item.name,
                              )
                              .join(
                                ' • ',
                              ),
                          maxLines:
                              1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                AppTheme
                                    .darkGreen,
                            fontSize:
                                11.5,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),

                      const SizedBox(
                        height:
                            7,
                      ),

                      Expanded(
                        child:
                            Text(
                          movie.description ??
                              'Chưa có mô tả...',
                          maxLines:
                              2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                AppTheme
                                    .grey,
                            fontSize:
                                11,
                            height:
                                1.35,
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

  // ================================================================
  // MOVIE INFO
  // ================================================================

  String _movieInfo(
    Movie movie,
  ) {
    final parts =
        <String>[];

    if (movie.releaseYear !=
        null) {
      parts.add(
        movie.releaseYear
            .toString(),
      );
    }

    if (movie.duration !=
        null) {
      parts.add(
        '${movie.duration} phút',
      );
    }

    parts.add(
      movie.isSeries
          ? 'Phim bộ'
          : 'Phim lẻ',
    );

    return parts.join(
      ' • ',
    );
  }

  // ================================================================
  // FIND SELECTED CATEGORY
  // ================================================================

  Category? _findSelectedCategory() {
    for (final category
        in _categories) {
      if (category.id ==
          _selectedCategoryId) {
        return category;
      }
    }

    return null;
  }

  // ================================================================
  // ERROR CARD
  // ================================================================

  Widget _buildErrorCard(
    String message,
    VoidCallback onRetry,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child:
          Column(
        children: [
          const Icon(
            Icons
                .cloud_off_rounded,
            color:
                AppTheme.grey,
            size:
                42,
          ),

          const SizedBox(
            height:
                10,
          ),

          Text(
            message,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  AppTheme.grey,
              fontSize:
                  13,
            ),
          ),

          const SizedBox(
            height:
                12,
          ),

          ElevatedButton(
            onPressed:
                onRetry,
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  AppTheme
                      .darkGreen,
              foregroundColor:
                  Colors.white,
            ),
            child:
                const Text(
              'Thử lại',
            ),
          ),
        ],
      ),
    );
  }
}

