import 'package:flutter/material.dart';

import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  void _onDestinationSelected(
    BuildContext context,
    int index,
  ) {
    if (index == currentIndex) {
      return;
    }

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.home,
        );
        break;

      case 1:
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.search,
        );
        break;

      case 2:
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.category,
        );
        break;

      case 3:
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.chatbot,
        );
        break;

      case 4:
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.profile,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        _onDestinationSelected(
          context,
          index,
        );
      },
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      indicatorColor: AppTheme.darkGreen.withValues(
        alpha: 0.12,
      ),
      elevation: 8,
      height: 72,
      destinations: const [
        NavigationDestination(
          icon: Icon(
            Icons.home_outlined,
            color: AppTheme.grey,
          ),
          selectedIcon: Icon(
            Icons.home_rounded,
            color: AppTheme.darkGreen,
          ),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.search_rounded,
            color: AppTheme.grey,
          ),
          selectedIcon: Icon(
            Icons.search_rounded,
            color: AppTheme.darkGreen,
          ),
          label: 'Tìm kiếm',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.grid_view_rounded,
            color: AppTheme.grey,
          ),
          selectedIcon: Icon(
            Icons.grid_view_rounded,
            color: AppTheme.darkGreen,
          ),
          label: 'Danh mục',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppTheme.grey,
          ),
          selectedIcon: Icon(
            Icons.chat_bubble_rounded,
            color: AppTheme.darkGreen,
          ),
          label: 'AI Chat',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.person_outline_rounded,
            color: AppTheme.grey,
          ),
          selectedIcon: Icon(
            Icons.person_rounded,
            color: AppTheme.darkGreen,
          ),
          label: 'Tôi',
        ),
      ],
    );
  }
}