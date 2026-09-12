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
final CategoryService _categoryService = CategoryService.instance;
final MovieService _movieService = MovieService.instance;

List<Category> _categories = const [];
List<Movie> _movies = const [];

int? _selectedCategoryId;

bool _isLoadingCategories = true;
bool _isLoadingMovies = false;

String? _categoryError;
String? _movieError;

static const List<IconData> _icons = [
Icons.local_fire_department_rounded,
Icons.psychology_rounded,
Icons.rocket_launch_rounded,
Icons.auto_awesome_rounded,
Icons.sentiment_very_dissatisfied_rounded,
Icons.map_rounded,
Icons.palette_rounded,
Icons.videocam_rounded,
];

static const List<Color> _colors = [
Color(0xFFFF6B35),
Color(0xFF7C4DFF),
Color(0xFF2196F3),
Color(0xFFE91E63),
Color(0xFF673AB7),
Color(0xFF009688),
Color(0xFFFF9800),
Color(0xFF3F51B5),
];

@override
void initState() {
super.initState();
_loadCategories();
}

Future<void> _loadCategories() async {
setState(() {
_isLoadingCategories = true;
_categoryError = null;
});

try {
  final categories = await _categoryService.getCategories();

  if (!mounted) {
    return;
  }

  setState(() {
    _categories = categories;
    _isLoadingCategories = false;
  });

  await _loadMovies();
} catch (e) {
  if (!mounted) {
    return;
  }

  setState(() {
    _categoryError =
        e.toString().replaceFirst('Exception: ', '');
    _isLoadingCategories = false;
  });
}


}

Future<void> _loadMovies({int? categoryId}) async {
setState(() {
_isLoadingMovies = true;
_movieError = null;
});


try {
  final movies = await _movieService.getMovies(
    categoryId: categoryId,
    page: 1,
    pageSize: 50,
  );

  if (!mounted) {
    return;
  }

  setState(() {
    _movies = movies;
    _isLoadingMovies = false;
  });
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

Future<void> _selectCategory(Category category) async {
final isSelected = _selectedCategoryId == category.id;


setState(() {
  _selectedCategoryId = isSelected ? null : category.id;
});

await _loadMovies(
  categoryId: isSelected ? null : category.id,
);


}

Future<void> _refresh() async {
await _loadCategories();
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppTheme.background,
drawerScrimColor: Colors.black.withValues(alpha: 0.58),
drawer: const AppDrawer(
currentRoute: AppRoutes.category,
),
appBar: _buildAppBar(context),
body: SafeArea(
child: RefreshIndicator(
onRefresh: _refresh,
child: SingleChildScrollView(
physics: const AlwaysScrollableScrollPhysics(
parent: BouncingScrollPhysics(),
),
padding: const EdgeInsets.only(bottom: 24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
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
bottomNavigationBar: const AppBottomNavigation(
currentIndex: 2,
),
);
}

PreferredSizeWidget _buildAppBar(BuildContext context) {
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
);
}

Widget _buildPageTitle() {
return const Padding(
padding: EdgeInsets.fromLTRB(20, 12, 20, 22),
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
return const SizedBox(
height: 170,
child: Center(
child: CircularProgressIndicator(),
),
);
}


if (_categoryError != null) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: _buildErrorCard(
      _categoryError!,
      _loadCategories,
    ),
  );
}

if (_categories.isEmpty) {
  return const Padding(
    padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: Text(
      'Chưa có thể loại nào.',
      style: TextStyle(
        color: AppTheme.grey,
        fontSize: 14,
      ),
    ),
  );
}

return Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
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
        category,
        index,
      );
    },
  ),
);


}

Widget _buildCategoryCard(
Category category,
int index,
) {
final icon = _icons[index % _icons.length];
final color = _colors[index % _colors.length];
final selected = _selectedCategoryId == category.id;


return Material(
  color: selected
      ? AppTheme.darkGreen.withValues(alpha: 0.08)
      : Colors.white,
  borderRadius: BorderRadius.circular(20),
  child: InkWell(
    onTap: () => _selectCategory(category),
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.darkGreen.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: selected
            ? Border.all(
                color: AppTheme.darkGreen,
                width: 1.2,
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
              color: color.withValues(alpha: 0.12),
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
            selected ? 'Đang chọn' : 'Xem phim',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected
                  ? AppTheme.darkGreen
                  : AppTheme.grey,
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
final selectedCategory = _selectedCategoryId == null
? null
: _findSelectedCategory();


return Padding(
  padding: const EdgeInsets.fromLTRB(20, 31, 20, 14),
  child: Row(
    children: [
      Expanded(
        child: Text(
          selectedCategory == null
              ? 'TẤT CẢ PHIM'
              : selectedCategory.name.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.black,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      ),
      if (_selectedCategoryId != null)
        TextButton(
          onPressed: () {
            _selectCategory(selectedCategory!);
          },
          child: const Text('Bỏ lọc'),
        ),
    ],
  ),
);


}

Widget _buildMovieSection() {
if (_isLoadingMovies) {
return const Padding(
padding: EdgeInsets.symmetric(vertical: 70),
child: Center(
child: CircularProgressIndicator(),
),
);
}


if (_movieError != null) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: _buildErrorCard(
      _movieError!,
      () => _loadMovies(
        categoryId: _selectedCategoryId,
      ),
    ),
  );
}

if (_movies.isEmpty) {
  return const Padding(
    padding: EdgeInsets.fromLTRB(20, 0, 20, 40),
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
  padding: const EdgeInsets.symmetric(horizontal: 20),
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: _movies.length,
  separatorBuilder: (context, index) {
    return const SizedBox(height: 12);
  },
  itemBuilder: (context, index) {
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
if (movie.categories.isNotEmpty)
Text(
movie.categories
.map((item) => item.name)
.join(' • '),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: AppTheme.darkGreen,
fontSize: 11.5,
fontWeight: FontWeight.w700,
),
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
final parts = <String>[];


if (movie.releaseYear != null) {
  parts.add(movie.releaseYear.toString());
}

if (movie.duration != null) {
  parts.add('${movie.duration} phút');
}

parts.add(movie.isSeries ? 'Phim bộ' : 'Phim lẻ');

return parts.join(' • ');


}

Category? _findSelectedCategory() {
for (final category in _categories) {
if (category.id == _selectedCategoryId) {
return category;
}
}


return null;


}

Widget _buildErrorCard(
String message,
VoidCallback onRetry,
) {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
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
textAlign: TextAlign.center,
style: const TextStyle(
color: AppTheme.grey,
fontSize: 13,
),
),
const SizedBox(height: 12),
ElevatedButton(
onPressed: onRetry,
child: const Text('Thử lại'),
),
],
),
);
}
}
