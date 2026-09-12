import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/movie.dart';

class MovieCard extends StatelessWidget {
final Movie movie;
final VoidCallback? onTap;

const MovieCard({
super.key,
required this.movie,
this.onTap,
});

@override
Widget build(BuildContext context) {
return GestureDetector(
onTap: onTap,
child: SizedBox(
width: 145,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
ClipRRect(
borderRadius: BorderRadius.circular(18),
child: AspectRatio(
aspectRatio: 0.68,
child: Image.network(
movie.posterUrl ?? '',
fit: BoxFit.cover,
errorBuilder: (context, error, stackTrace) {
return Container(
color: AppTheme.lightGrey,
alignment: Alignment.center,
child: const Icon(
Icons.movie_outlined,
size: 40,
color: AppTheme.grey,
),
);
},
),
),
),
const SizedBox(height: 9),
Text(
movie.title,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: AppTheme.black,
fontSize: 15,
fontWeight: FontWeight.w700,
),
),
const SizedBox(height: 4),
Text(
'${movie.releaseYear ?? '----'} • ${movie.duration ?? '--'} phút',
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: AppTheme.grey,
fontSize: 12,
),
),
],
),
),
);
}
}
