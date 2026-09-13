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

bool _isLoadingCategories = true;
bool _isLoadingMovies = false;

String? _categoryError;
String? _movieError;

int _movieRequestId = 0;

@override
void initState() {
super.initState();
_loadCategories();
}

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
  });

  await _loadMovies(
    categoryId: _selectedCategoryId,
  );
} catch (e) {
  if (!mounted) {
    return;
  }

  setState(() {
    _categories = const [];
    _isLoadingCategories = false;
    _categoryError =
        _cleanErrorMessage(e);
  });
}


}

Future<void> _loadMovies({
int? categoryId,
}) async {
final requestId = ++_movieRequestId;


if (mounted) {
  setState(() {
    _isLoadingMovies = true;
    _movieError = null;
  });
}

try {
  final movies =
      await _movieService.getMovies(
    categoryId: categoryId,
    page: 1,
    pageSize: 50,
  );

  if (!mounted ||
      requestId != _movieRequestId) {
    return;
  }

  setState(() {
    _movies = movies;
    _isLoadingMovies = false;
  });
} catch (e) {
  if (!mounted ||
      requestId != _movieRequestId) {
    return;
  }

  setState(() {
    _movies = const [];
    _isLoadingMovies = false;
    _movieError =
        _cleanErrorMessage(e);
  });
}


}

Future<void> _selectCategory(
Category category,
) async {
final isSelected =
_selectedCategoryId ==
category.id;


final categoryId =
    isSelected ? null : category.id;

setState(() {
  _selectedCategoryId = categoryId;
});

await _loadMovies(
  categoryId: categoryId,
);


}

Future<void> _clearCategoryFilter() async {
if (_selectedCategoryId == null) {
return;
}


setState(() {
  _selectedCategoryId = null;
});

await _loadMovies();


}

Future<void> _refresh() async {
await _loadCategories();
}

void _openMovieDetail(Movie movie) {
Navigator.pushNamed(
context,
AppRoutes.movieDetail,
arguments: movie,
);
}

Category? _findSelectedCategory() {
final selectedId =
_selectedCategoryId;


if (selectedId == null) {
  return null;
}

for (final category in _categories) {
  if (category.id == selectedId) {
    return category;
  }
}

return null;


}

String _cleanErrorMessage(Object error) {
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
final selectedCategory =
_findSelectedCategory();


return Scaffold(
  backgroundColor: AppTheme.background,
  drawerScrimColor:
      Colors.black.withValues(
    alpha: 0.58,
  ),
  drawer: const AppDrawer(
    currentRoute: AppRoutes.category,
  ),
  appBar: _buildAppBar(),
  body: SafeArea(
    child: RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(
          parent:
              BouncingScrollPhysics(),
        ),
        padding:
            const EdgeInsets.only(
          bottom: 24,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildPageTitle(),
            _buildCategorySection(),
            _buildMoviesHeader(
              selectedCategory,
            ),
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

Widget _buildCategorySection() {
if (_isLoadingCategories) {
return const Padding(
padding: EdgeInsets.symmetric(
horizontal: 20,
),
child: SizedBox(
height: 120,
child: Center(
child:
CircularProgressIndicator(),
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
    child: _buildErrorCard(
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
    child: Text(
      'Chưa có danh mục nào.',
      style: TextStyle(
        color: AppTheme.grey,
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
  child: GridView.builder(
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
      return _buildCategoryCard(
        _categories[index],
      );
    },
  ),
);


}

Widget _buildCategoryCard(
Category category,
) {
final selected =
_selectedCategoryId ==
category.id;


return Material(
  color: selected
      ? AppTheme.darkGreen
      : Colors.white,
  borderRadius:
      BorderRadius.circular(16),
  child: InkWell(
    onTap: () {
      _selectCategory(category);
    },
    borderRadius:
        BorderRadius.circular(16),
    child: Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.darkGreen
            : Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppTheme.darkGreen
              : AppTheme.grey.withValues(
                  alpha: 0.18,
                ),
          width: selected ? 1.2 : 1,
        ),
      ),
      child: Text(
        category.name,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow:
            TextOverflow.ellipsis,
        style: TextStyle(
          color: selected
              ? Colors.white
              : AppTheme.black,
          fontSize: 15,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    ),
  ),
);


}

Widget _buildMoviesHeader(
Category? selectedCategory,
) {
final title =
selectedCategory == null
? 'TẤT CẢ PHIM'
: selectedCategory.name
.toUpperCase();


return Padding(
  padding:
      const EdgeInsets.fromLTRB(
    20,
    30,
    20,
    14,
  ),
  child: Row(
    children: [
      Expanded(
        child: Text(
          title,
          style:
              const TextStyle(
            color: AppTheme.black,
            fontSize: 15,
            fontWeight:
                FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      ),
      if (selectedCategory != null)
        TextButton(
          onPressed:
              _clearCategoryFilter,
          child:
              const Text('Bỏ lọc'),
        ),
    ],
  ),
);


}

Widget _buildMovieSection() {
if (_isLoadingMovies) {
return const Padding(
padding:
EdgeInsets.symmetric(
vertical: 70,
),
child: Center(
child:
CircularProgressIndicator(),
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
    child: _buildErrorCard(
      _movieError!,
      () {
        _loadMovies(
          categoryId:
              _selectedCategoryId,
        );
      },
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
    child: Center(
      child: Text(
        'Không có phim nào.',
        style: TextStyle(
          color: AppTheme.grey,
          fontSize: 14,
        ),
      ),
    ),
  );
}

return ListView.separated(
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
      _movies[index],
    );
  },
);


}

Widget _buildMovieCard(
Movie movie,
) {
final posterUrl =
movie.posterUrl?.trim();


return Material(
  color: Colors.white,
  borderRadius:
      BorderRadius.circular(20),
  child: InkWell(
    onTap: () {
      _openMovieDetail(movie);
    },
    borderRadius:
        BorderRadius.circular(20),
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
              height: 122,
              child:
                  posterUrl == null ||
                          posterUrl.isEmpty
                      ? _buildPosterPlaceholder()
                      : Image.network(
                          posterUrl,
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
                    style:
                        const TextStyle(
                      color:
                          AppTheme.black,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _movieInfo(movie),
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
                  if (movie.categories
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      movie.categories
                          .map(
                            (item) =>
                                item.name,
                          )
                          .join(' • '),
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            AppTheme
                                .darkGreen,
                        fontSize: 11.5,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Expanded(
                    child: Text(
                      movie.description
                              ?.trim()
                              .isNotEmpty ==
                          true
                          ? movie.description!
                          : 'Chưa có mô tả cho bộ phim này.',
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
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

Widget _buildPosterPlaceholder() {
return Container(
color: AppTheme.lightGrey,
alignment: Alignment.center,
child: const Icon(
Icons.movie_outlined,
color: AppTheme.grey,
size: 34,
),
);
}

String _movieInfo(Movie movie) {
final parts = <String>[];


if (movie.releaseYear != null) {
  parts.add(
    movie.releaseYear.toString(),
  );
}

if (movie.duration != null &&
    movie.duration! > 0) {
  parts.add(
    '${movie.duration} phút',
  );
}

parts.add(
  movie.isSeries
      ? 'Phim bộ'
      : 'Phim lẻ',
);

return parts.join(' • ');


}

Widget _buildErrorCard(
String message,
VoidCallback onRetry,
) {
return Container(
width: double.infinity,
padding:
const EdgeInsets.all(18),
decoration: BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(18),
),
child: Column(
children: [
const Icon(
Icons.cloud_off_rounded,
color: AppTheme.grey,
size: 42,
),
const SizedBox(height: 10),
Text(
message,
textAlign:
TextAlign.center,
style: const TextStyle(
color: AppTheme.grey,
fontSize: 13,
),
),
const SizedBox(height: 12),
ElevatedButton(
onPressed: onRetry,
child:
const Text('Thử lại'),
),
],
),
);
}
}
