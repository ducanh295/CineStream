import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    this.currentRoute,
  });

  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.80,
      backgroundColor: AppTheme.background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(authProvider),
            _buildAuthSection(
              context,
              authProvider,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              child: Divider(
                color: AppTheme.darkGreen.withValues(
                  alpha: 0.10,
                ),
                height: 1,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  4,
                  12,
                  20,
                ),
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_rounded,
                    iconColor: Colors.orange,
                    title: 'Trang chủ',
                    route: AppRoutes.home,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.search_rounded,
                    iconColor: Colors.deepPurple,
                    title: 'Tìm kiếm',
                    route: AppRoutes.search,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.folder_rounded,
                    iconColor: Colors.amber,
                    title: 'Danh mục',
                    route: AppRoutes.category,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.smart_toy_rounded,
                    iconColor: Colors.pinkAccent,
                    title: 'AI CineBot',
                    route: AppRoutes.chatbot,
                  ),
                  const SizedBox(height: 6),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_rounded,
                    iconColor: const Color(0xFF35305E),
                    title: 'Hồ sơ',
                    route: AppRoutes.profile,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.credit_card_rounded,
                    iconColor: Colors.blue,
                    title: 'Nâng cấp Premium',
                    onTap: () {
                      _closeDrawer(context);

                      _showMessage(
                        context,
                        'Tính năng Premium sẽ được kết nối sau.',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    AuthProvider authProvider,
  ) {
    final user = authProvider.user;

    final displayName =
        user?.profile?.displayName
                    ?.trim()
                    .isNotEmpty ==
                true
            ? user!.profile!.displayName!.trim()
            : user?.username ?? 'Khách';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        24,
        22,
        26,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.darkGreen,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            user == null
                ? 'CineStream'
                : displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 7),
          Text(
            user == null
                ? 'Trải nghiệm điện ảnh đỉnh cao'
                : user.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD9DDD8),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthSection(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    if (authProvider.isAuthenticated &&
        authProvider.user != null) {
      return _buildLoggedInSection(
        context,
        authProvider,
      );
    }

    return _buildGuestSection(context);
  }

  Widget _buildGuestSection(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  _closeDrawer(context);

                  Navigator.pushNamed(
                    context,
                    AppRoutes.login,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppTheme.darkGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                  ),
                ),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: () {
                  _closeDrawer(context);

                  Navigator.pushNamed(
                    context,
                    AppRoutes.register,
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      AppTheme.background,
                  foregroundColor:
                      AppTheme.darkGreen,
                  side: const BorderSide(
                    color: AppTheme.darkGreen,
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                  ),
                ),
                child: const Text(
                  'Đăng ký',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInSection(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final user = authProvider.user!;

    final displayName =
        user.profile?.displayName
                    ?.trim()
                    .isNotEmpty ==
                true
            ? user.profile!.displayName!.trim()
            : user.username;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        18,
        10,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.darkGreen.withValues(
              alpha: 0.10,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.black,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.grey,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: authProvider.isLoading
                    ? null
                    : () {
                        _logout(context);
                      },
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                ),
                label: authProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Đăng xuất',
                      ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(
                    color: Colors.redAccent.withValues(
                      alpha: 0.45,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? route,
    VoidCallback? onTap,
  }) {
    final selected =
        route != null && route == currentRoute;

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.darkGreen.withValues(
                alpha: 0.08,
              )
            : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 2,
        ),
        onTap: onTap ??
            () {
              if (route == null) {
                return;
              }

              _closeDrawer(context);

              if (route == currentRoute) {
                return;
              }

              Navigator.pushReplacementNamed(
                context,
                route,
              );
            },
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 23,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.black,
            fontSize: 14.5,
            fontWeight: selected
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
        trailing: selected
            ? const Icon(
                Icons.circle,
                color: AppTheme.darkGreen,
                size: 8,
              )
            : const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.grey,
                size: 20,
              ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
    );
  }

  Future<void> _logout(
    BuildContext context,
  ) async {
    final authProvider =
        context.read<AuthProvider>();

    try {
      await authProvider.logout();

      if (!context.mounted) {
        return;
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Đã đăng xuất tài khoản.',
            ),
            behavior:
                SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  void _closeDrawer(
    BuildContext context,
  ) {
    Navigator.pop(context);
  }

  void _showMessage(
    BuildContext context,
    String message,
  ) {
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
} 