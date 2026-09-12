import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../services/movie_service.dart';
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

final MovieService _movieService = MovieService.instance;

final List<String> _popularKeywords = [
'Action',
'Drama',
'Sci-Fi',
'Romance',
'Thriller',
'Animation',
];

List<Movie> _movies = const [];

bool _isLoading = true;
String? _errorMessage;

Timer? _searchDebounce;

@override
void initState() {
super.initState();


_searchController.addListener(_onSearchChanged);
_loadMovies();


}

@override
void dispose() {
_searchDebounce?.cancel();


_searchController
  ..removeListener(_onSearchChanged)
  ..dispose();

super.dispose();


}

void _onSearchChanged() {
_searchDebounce?.cancel();


final keyword = _searchController.text.trim();

_searchDebounce = Timer(
  const Duration(milliseconds: 400),
  () {
    _loadMovies(
      search: keyword.isEmpty ? null : keyword,
    );
  },
);

setState(() {});


}

Future<void> _loadMovies({
String? search,
}) async {
if (mounted) {
setState(() {
_isLoading = true;
_errorMessage = null;
});
}


try {
  final movies = await _movieService.getMovies(
    search: search,
    page: 1,
    pageSize: 50,
  );

  if (!mounted) {
    return;
  }

  setState(() {
    _movies = movies;
    _isLoading = false;
  });
} catch (e) {
  if (!mounted) {
    return;
  }

  setState(() {
    _errorMessage =
        e.toString().replaceFirst('Exception: ', '');
    _isLoading = false;
  });
}


}

void _selectKeyword(String keyword) {
_searchController.text = keyword;


_searchController.selection = TextSelection.fromPosition(
  TextPosition(
    offset: _searchController.text.length,
  ),
);


}

void _clearSearch() {
_searchController.clear();
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
child: RefreshIndicator(
onRefresh: () => _loadMovies(
search: _searchController.text.trim().isEmpty
? null
: _searchController.text.trim(),
),
child: SingleChildScrollView(
physics: const AlwaysScrollableScrollPhysics(
parent: BouncingScrollPhysics(),
),
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
),
],
),
),
bottomNavigationBar: const AppBottomNavigation(
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
textInputAction: TextInputAction.search,
onSubmitted: (value) {
_searchDebounce?.cancel();


      _loadMovies(
        search: value.trim().isEmpty
            ? null
            : value.trim(),
      );
    },
    decoration: InputDecoration(
      hintText: 'Tìm phim...',
      prefixIcon: const Icon(
        Icons.search_rounded,
        color: AppTheme.darkGreen,
        size: 25,
      ),
      suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              onPressed: _clearSearch,
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
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
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
'GỢI Ý TÌM KIẾM',
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
children: _popularKeywords.map(
(keyword) {
return GestureDetector(
onTap: () {
_selectKeyword(keyword);
},
child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 9,
),
decoration: BoxDecoration(
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
style: const TextStyle(
color: AppTheme.black,
fontSize: 12.5,
fontWeight: FontWeight.w600,
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
final keyword =
_searchController.text.trim();


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
      if (keyword.isNotEmpty)
        Text(
          '${_movies.length} phim',
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
if (_isLoading) {
return const Padding(
padding: EdgeInsets.symmetric(
vertical: 70,
),
child: Center(
child: CircularProgressIndicator(),
),
);
}


if (_errorMessage != null) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(
      20,
      20,
      20,
      60,
    ),
    child: _buildErrorState(),
  );
}

if (_movies.isEmpty) {
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
  physics: const NeverScrollableScrollPhysics(),
  itemCount: _movies.length,
  separatorBuilder: (context, index) {
    return const SizedBox(height: 12);
  },
  itemBuilder: (context, index) {
    return _buildMovieResultCard(
      _movies[index],
    );
  },
);


}

Widget _buildMovieResultCard(Movie movie) {
return Material(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
child: InkWell(
borderRadius: BorderRadius.circular(20),
onTap: () {
_openMovieDetail(movie);
},
child: Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
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
overflow:
TextOverflow.ellipsis,
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
overflow:
TextOverflow.ellipsis,
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
maxLines: 3,
overflow:
TextOverflow.ellipsis,
style: const TextStyle(
color: AppTheme.grey,
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

String _movieInfo(Movie movie) {
final parts = <String>[];


if (movie.releaseYear != null) {
  parts.add(movie.releaseYear.toString());
}

if (movie.duration != null) {
  parts.add('${movie.duration} phút');
}

parts.add(
  movie.isSeries ? 'Phim bộ' : 'Phim lẻ',
);

return parts.join(' • ');


}

Widget _buildErrorState() {
return Column(
children: [
const Icon(
Icons.cloud_off_rounded,
color: AppTheme.grey,
size: 52,
),
const SizedBox(height: 12),
Text(
_errorMessage!,
textAlign: TextAlign.center,
style: const TextStyle(
color: AppTheme.grey,
fontSize: 14,
),
),
const SizedBox(height: 14),
ElevatedButton(
onPressed: () {
_loadMovies(
search:
_searchController.text.trim().isEmpty
? null
: _searchController.text.trim(),
);
},
child: const Text('Thử lại'),
),
],
);
}
}
