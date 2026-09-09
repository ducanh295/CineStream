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
              child: Stack(
                children: [
                  AspectRatio(
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

                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppTheme.yellow,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            movie.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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