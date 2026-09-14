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
            _buildHeader(),

            // ========================================================
            // THÔNG TIN TÀI KHOẢN
            // ========================================================

            Consumer<AuthProvider>(
              builder: (
                context,
                authProvider,
                child,
              ) {
                return _buildAuthSection(
                  context,
                  authProvider,
                );
              },
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              child: Divider(
                color:
                    AppTheme.darkGreen.withValues(
                  alpha: 0.10,
                ),
                height: 1,
              ),
            ),

            // ========================================================
            // MENU
            // ========================================================

            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  4,
                  12,
                  20,
                ),
                children: [
                  _buildDrawerItem(
                    context,
                    icon:
                        Icons.home_rounded,
                    iconColor:
                        Colors.orange,
                    title:
                        'Trang chủ',
                    route:
                        AppRoutes.home,
                  ),

                  _buildDrawerItem(
                    context,
                    icon:
                        Icons.search_rounded,
                    iconColor:
                        Colors.deepPurple,
                    title:
                        'Tìm kiếm',
                    route:
                        AppRoutes.search,
                  ),

                  _buildDrawerItem(
                    context,
                    icon:
                        Icons.folder_rounded,
                    iconColor:
                        Colors.amber,
                    title:
                        'Danh mục',
                    route:
                        AppRoutes.category,
                  ),

                  _buildDrawerItem(
                    context,
                    icon:
                        Icons.smart_toy_rounded,
                    iconColor:
                        Colors.pinkAccent,
                    title:
                        'AI CineBot',
                    route:
                        AppRoutes.chatbot,
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  _buildDrawerItem(
                    context,
                    icon:
                        Icons.person_rounded,
                    iconColor:
                        const Color(
                      0xFF35305E,
                    ),
                    title:
                        'Hồ sơ',
                    route:
                        AppRoutes.profile,
                  ),

                  // ==================================================
                  // FAVORITES
                  // ==================================================

                  _buildDrawerItem(
                    context,
                    icon:
                        Icons.favorite_rounded,
                    iconColor:
                        Colors.redAccent,
                    title:
                        'Phim yêu thích',
                    route:
                        AppRoutes.favorites,
                  ),

                  // ==================================================
                  // PREMIUM
                  // ==================================================

                  _buildDrawerItem(
                    context,
                    icon:
                        Icons.workspace_premium_rounded,
                    iconColor:
                        Colors.amber.shade700,
                    title:
                        'Nâng cấp Premium',
                    route:
                        AppRoutes.payment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HEADER CINESTREAM
  // ================================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        22,
        24,
        22,
        26,
      ),
      decoration:
          const BoxDecoration(
        color:
            AppTheme.darkGreen,
        borderRadius:
            BorderRadius.only(
          bottomRight:
              Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
                BoxDecoration(
              color:
                  Colors.white.withValues(
                alpha: 0.14,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons.movie_creation_outlined,
              color:
                  Color(0xFFD7CBE5),
              size: 30,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          const Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'CineStream',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 25,
                    fontWeight:
                        FontWeight.w800,
                    fontFamily:
                        'Georgia',
                  ),
                ),
                SizedBox(
                  height: 7,
                ),
                Text(
                  'Trải nghiệm điện ảnh đỉnh cao',
                  style:
                      TextStyle(
                    color:
                        Color(0xFFD9DDD8),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // THÔNG TIN TÀI KHOẢN
  // ================================================================

  Widget _buildAuthSection(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final isAuthenticated =
        authProvider.isAuthenticated;

    final isLoading =
        authProvider.isLoading;

    final user =
        authProvider.user;

    final isPremium =
        user?.premiumActive == true;

    // Ưu tiên displayName trong profile.
    // Nếu không có thì lấy username.
    final displayName =
        user?.profile?.displayName
                    ?.trim()
                    .isNotEmpty ==
                true
            ? user!.profile!.displayName!
            : user?.username ?? '';

    final email =
        user?.email ?? '';

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        10,
      ),
      child: Column(
        children: [
          // ==========================================================
          // ĐÃ ĐĂNG NHẬP
          // ==========================================================

          if (isAuthenticated) ...[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(
                15,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppTheme.darkGreen.withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                border:
                    Border.all(
                  color:
                      AppTheme.darkGreen.withValues(
                    alpha: 0.10,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Chỉ dùng icon tài khoản,
                  // không dùng ảnh/avatar người dùng.
                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                        BoxDecoration(
                      color:
                          isPremium
                              ? Colors.amber.shade700
                              : AppTheme.darkGreen,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child:
                        Icon(
                      isPremium
                          ? Icons.workspace_premium_rounded
                          : Icons.person_rounded,
                      color:
                          Colors.white,
                      size: 25,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.isNotEmpty
                              ? displayName
                              : 'Người dùng',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color:
                                AppTheme.black,
                            fontSize:
                                15,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          email.isNotEmpty
                              ? email
                              : 'Chưa có email',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color:
                                AppTheme.grey,
                            fontSize:
                                11.5,
                          ),
                        ),

                        if (isPremium) ...[
                          const SizedBox(
                            height: 7,
                          ),
                          _PremiumAccountBadge(
                            expiresAt:
                                user?.premiumExpiresAt,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // Chỉ hiển thị Đăng xuất
            // khi đã đăng nhập.
            SizedBox(
              width: double.infinity,
              height: 46,
              child:
                  OutlinedButton.icon(
                onPressed:
                    isLoading
                        ? null
                        : () =>
                            _handleLogout(
                              context,
                            ),
                icon:
                    isLoading
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.red,
                            ),
                          )
                        : const Icon(
                            Icons.logout_rounded,
                            size: 19,
                          ),
                label:
                    Text(
                  isLoading
                      ? 'Đang đăng xuất...'
                      : 'Đăng xuất',
                  style:
                      const TextStyle(
                    fontSize:
                        13,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                style:
                    OutlinedButton.styleFrom(
                  backgroundColor:
                      Colors.red.withValues(
                    alpha: 0.04,
                  ),
                  foregroundColor:
                      Colors.red,
                  side:
                      BorderSide(
                    color:
                        Colors.red.withValues(
                      alpha: 0.55,
                    ),
                  ),
                  padding:
                      EdgeInsets.zero,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                  ),
                ),
              ),
            ),
          ]

          // ==========================================================
          // CHƯA ĐĂNG NHẬP
          // ==========================================================

          else ...[
            Row(
              children: [
                Expanded(
                  child:
                      SizedBox(
                    height: 46,
                    child:
                        ElevatedButton(
                      onPressed: () {
                        _closeDrawer(
                          context,
                        );

                        Navigator.pushNamed(
                          context,
                          AppRoutes.login,
                        );
                      },
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.darkGreen,
                        foregroundColor:
                            Colors.white,
                        elevation:
                            0,
                        padding:
                            EdgeInsets.zero,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            30,
                          ),
                        ),
                      ),
                      child:
                          const Text(
                        'Đăng nhập',
                        style:
                            TextStyle(
                          fontSize:
                              13,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      SizedBox(
                    height: 46,
                    child:
                        OutlinedButton(
                      onPressed: () {
                        _closeDrawer(
                          context,
                        );

                        Navigator.pushNamed(
                          context,
                          AppRoutes.register,
                        );
                      },
                      style:
                          OutlinedButton.styleFrom(
                        backgroundColor:
                            AppTheme.background,
                        foregroundColor:
                            AppTheme.darkGreen,
                        side:
                            const BorderSide(
                          color:
                              AppTheme.darkGreen,
                        ),
                        padding:
                            EdgeInsets.zero,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            30,
                          ),
                        ),
                      ),
                      child:
                          const Text(
                        'Đăng ký',
                        style:
                            TextStyle(
                          fontSize:
                              13,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // LOGOUT
  // ================================================================

  Future<void> _handleLogout(
    BuildContext context,
  ) async {
    final authProvider =
        context.read<AuthProvider>();

    final shouldLogout =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppTheme.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
          ),
          title:
              const Text(
            'Đăng xuất',
            style:
                TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content:
              const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi CineStream không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text(
                'Hủy',
                style:
                    TextStyle(
                  color:
                      AppTheme.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Đăng xuất',
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await authProvider.logout();

    if (!context.mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  // ================================================================
  // DRAWER ITEM
  // ================================================================

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? route,
    VoidCallback? onTap,
  }) {
    final selected =
        route != null &&
        route == currentRoute;

    return Container(
      margin:
          const EdgeInsets.symmetric(
        vertical: 3,
      ),
      decoration:
          BoxDecoration(
        color:
            selected
                ? AppTheme.darkGreen.withValues(
                    alpha: 0.08,
                  )
                : Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          15,
        ),
      ),
      child:
          ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 2,
        ),
        onTap:
            onTap ??
            () {
              if (route == null) {
                return;
              }

              _closeDrawer(
                context,
              );

              if (route ==
                  currentRoute) {
                return;
              }

              Navigator.pushReplacementNamed(
                context,
                route,
              );
            },
        leading:
            Container(
          width: 42,
          height: 42,
          decoration:
              BoxDecoration(
            color:
                iconColor.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),
          child:
              Icon(
            icon,
            color:
                iconColor,
            size: 23,
          ),
        ),
        title:
            Text(
          title,
          style:
              TextStyle(
            color:
                AppTheme.black,
            fontSize:
                14.5,
            fontWeight:
                selected
                    ? FontWeight.w800
                    : FontWeight.w600,
          ),
        ),
        trailing:
            selected
                ? const Icon(
                    Icons.circle,
                    color:
                        AppTheme.darkGreen,
                    size: 8,
                  )
                : const Icon(
                    Icons.chevron_right_rounded,
                    color:
                        AppTheme.grey,
                    size: 20,
                  ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  void _closeDrawer(
    BuildContext context,
  ) {
    Navigator.pop(context);
  }
}

// ==================================================================
// PREMIUM ACCOUNT BADGE
// ==================================================================

class _PremiumAccountBadge
    extends StatelessWidget {
  final DateTime? expiresAt;

  const _PremiumAccountBadge({
    required this.expiresAt,
  });

  @override
  Widget build(BuildContext context) {
    final expiryText =
        expiresAt != null
            ? 'Premium • Hết hạn ${_formatDate(expiresAt!)}'
            : 'Premium đang hoạt động';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.amber.withValues(
          alpha: 0.16,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color:
                Colors.amber.shade800,
            size: 13,
          ),
          const SizedBox(
            width: 4,
          ),
          Flexible(
            child:
                Text(
              expiryText,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  TextStyle(
                color:
                    Colors.amber.shade900,
                fontSize:
                    9.5,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(
    DateTime date,
  ) {
    final local =
        date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}

