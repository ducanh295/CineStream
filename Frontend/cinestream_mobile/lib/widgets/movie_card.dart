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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
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

                    // Nhãn Sắp chiếu cho các bộ phim Coming Soon
                    if (movie.isComingSoon)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white24,
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            'SẮP CHIẾU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
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
