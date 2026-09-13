import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingSession = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  // ============================================================
  // SESSION
  // ============================================================

  Future<void> _checkSession() async {
    final authProvider =
        context.read<AuthProvider>();

    try {
      await authProvider.checkLoginStatus();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSession = false;
        });
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final authProvider =
        context.read<AuthProvider>();

    try {
      await authProvider.logout();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Đã đăng xuất thành công.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanErrorMessage(e),
        isError: true,
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppTheme.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: const Text(
            'Bạn có chắc muốn đăng xuất khỏi tài khoản?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color:
                      AppTheme.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color:
                      AppTheme.red,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true &&
        mounted) {
      await _logout();
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  void _showLogin() {
    Navigator.pushNamed(
      context,
      AppRoutes.login,
    );
  }

  // ============================================================
  // FAVORITES
  // ============================================================

  void _openFavorites() {
    final authProvider =
        context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      _showLogin();
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.favorites,
    );
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  Future<void> _openEditProfile() async {
    final authProvider =
        context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      _showLogin();
      return;
    }

    final result =
        await Navigator.pushNamed(
      context,
      AppRoutes.editProfile,
    );

    if (!mounted) {
      return;
    }

    if (result is User) {
      authProvider.setUserFromExternalSource(
        result,
      );
      return;
    }

    await authProvider.checkLoginStatus();
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  void _openChangePassword() {
    final authProvider =
        context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      _showLogin();
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.changePassword,
    );
  }

  // ============================================================
  // AI CHATBOT
  // ============================================================

  void _openChatbot() {
    Navigator.pushNamed(
      context,
      AppRoutes.chatbot,
    );
  }

  // ============================================================
  // PREMIUM
  // ============================================================

  void _openPremium() {
    final authProvider =
        context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      _showLogin();
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.premium,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              isError
                  ? AppTheme.red
                  : AppTheme.darkGreen,
        ),
      );
  }

  String _cleanErrorMessage(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final authProvider =
        context.watch<AuthProvider>();

    final user =
        authProvider.user;

    final isAuthenticated =
        authProvider.isAuthenticated;

    return Scaffold(
      backgroundColor:
          AppTheme.background,
      drawerScrimColor:
          Colors.black.withValues(
        alpha: 0.55,
      ),
      drawer: const AppDrawer(
        currentRoute:
            AppRoutes.profile,
      ),
      appBar:
          _buildAppBar(),
      body: SafeArea(
        top: false,
        child: _isLoadingSession
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color:
                      AppTheme.darkGreen,
                ),
              )
            : RefreshIndicator(
                color:
                    AppTheme.darkGreen,
                onRefresh:
                    _checkSession,
                child:
                    SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(
                    parent:
                        BouncingScrollPhysics(),
                  ),
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tài khoản',
                        style:
                            TextStyle(
                          fontFamily:
                              'serif',
                          fontSize:
                              34,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              AppTheme.black,
                        ),
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      _ProfileCard(
                        user:
                            user,
                        isAuthenticated:
                            isAuthenticated,
                      ),
                      const SizedBox(
                        height: 24,
                      ),

                      // ==================================================
                      // ACCOUNT
                      // ==================================================

                      if (isAuthenticated) ...[
                        const Text(
                          'Tài khoản',
                          style:
                              TextStyle(
                            fontFamily:
                                'serif',
                            fontSize:
                                24,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                AppTheme.black,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),

                        _AccountMenuItem(
                          icon:
                              Icons
                                  .edit_rounded,
                          iconColor:
                              AppTheme.darkGreen,
                          title:
                              'Chỉnh sửa hồ sơ',
                          subtitle:
                              'Cập nhật tên hiển thị và thông tin cá nhân',
                          onTap:
                              _openEditProfile,
                        ),

                        _AccountMenuItem(
                          icon:
                              Icons
                                  .lock_outline_rounded,
                          iconColor:
                              Colors.orange,
                          title:
                              'Đổi mật khẩu',
                          subtitle:
                              'Thay đổi mật khẩu đăng nhập của bạn',
                          onTap:
                              _openChangePassword,
                        ),

                        const SizedBox(
                          height: 12,
                        ),
                      ],

                      // ==================================================
                      // FEATURES
                      // ==================================================

                      const Text(
                        'Tính năng',
                        style:
                            TextStyle(
                          fontFamily:
                              'serif',
                          fontSize:
                              24,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              AppTheme.black,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),

                      _AccountMenuItem(
                        icon:
                            Icons
                                .favorite_rounded,
                        iconColor:
                            Colors.redAccent,
                        title:
                            'Phim yêu thích',
                        subtitle:
                            isAuthenticated
                                ? 'Danh sách phim bạn đã yêu thích'
                                : 'Đăng nhập để sử dụng tính năng này',
                        onTap:
                            _openFavorites,
                      ),

                      _AccountMenuItem(
                        icon:
                            Icons
                                .smart_toy_rounded,
                        iconColor:
                            Colors.pinkAccent,
                        title:
                            'AI CineBot',
                        subtitle:
                            'Tư vấn và gợi ý phim bằng AI',
                        onTap:
                            _openChatbot,
                      ),

                      _PremiumMenuItem(
                        user:
                            user,
                        isAuthenticated:
                            isAuthenticated,
                        onTap:
                            _openPremium,
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      _buildAuthButton(
                        isAuthenticated,
                      ),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar:
          const AppBottomNavigation(
        currentIndex: 4,
      ),
    );
  }

  // ============================================================
  // AUTH BUTTON
  // ============================================================

  Widget _buildAuthButton(
    bool isAuthenticated,
  ) {
    return SizedBox(
      width:
          double.infinity,
      child:
          Material(
        color:
            isAuthenticated
                ? AppTheme.pink
                : AppTheme.darkGreen,
        borderRadius:
            BorderRadius.circular(30),
        child:
            InkWell(
          borderRadius:
              BorderRadius.circular(30),
          onTap:
              isAuthenticated
                  ? _showLogoutDialog
                  : _showLogin,
          child:
              Padding(
            padding:
                const EdgeInsets.symmetric(
              vertical: 15,
            ),
            child:
                Center(
              child:
                  Text(
                isAuthenticated
                    ? 'Đăng xuất'
                    : 'Đăng nhập',
                style:
                    TextStyle(
                  color:
                      isAuthenticated
                          ? AppTheme.red
                          : Colors.white,
                  fontSize:
                      15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor:
          AppTheme.background,
      surfaceTintColor:
          Colors.transparent,
      elevation:
          0,
      leading:
          Builder(
        builder:
            (context) {
          return IconButton(
            onPressed:
                () {
              Scaffold.of(context)
                  .openDrawer();
            },
            icon:
                const Icon(
              Icons.menu_rounded,
              size:
                  28,
              color:
                  AppTheme.black,
            ),
          );
        },
      ),
      centerTitle:
          true,
      title:
          Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width:
                34,
            height:
                34,
            decoration:
                BoxDecoration(
              color:
                  AppTheme.darkGreen,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child:
                const Icon(
              Icons
                  .movie_filter_rounded,
              color:
                  Colors.white,
              size:
                  20,
            ),
          ),
          const SizedBox(
            width:
                8,
          ),
          const Text(
            'CineStream',
            style:
                TextStyle(
              color:
                  AppTheme.black,
              fontSize:
                  20,
              fontWeight:
                  FontWeight.w700,
              fontFamily:
                  'serif',
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed:
              () {
            _showMessage(
              'Backend hiện chưa có API thông báo.',
            );
          },
          icon:
              const Icon(
            Icons
                .notifications_none_rounded,
            color:
                AppTheme.black,
            size:
                27,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PROFILE CARD
// ============================================================================

class _ProfileCard
    extends StatelessWidget {
  final User? user;
  final bool isAuthenticated;

  const _ProfileCard({
    required this.user,
    required this.isAuthenticated,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final displayName =
        user?.profile?.displayName
                    ?.trim()
                    .isNotEmpty ==
                true
            ? user!
                .profile!
                .displayName!
                .trim()
            : user?.username ??
                'Khách';

    final email =
        user?.email ??
            'Chưa đăng nhập';

    final isPremium =
        user?.premiumActive == true;

    final roleLabel =
        !isAuthenticated
            ? 'Chưa đăng nhập'
            : user!.isAdmin
                ? 'Admin'
                : isPremium
                    ? 'Premium'
                    : 'CineStream';

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            AppTheme.darkGreen,
        borderRadius:
            BorderRadius.circular(24),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Expanded(
                child:
                    Text(
                  isAuthenticated
                      ? displayName
                      : 'Khách',
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        22,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              if (isAuthenticated)
                Icon(
                  user?.isAdmin == true
                      ? Icons
                          .admin_panel_settings_rounded
                      : isPremium
                          ? Icons
                              .workspace_premium_rounded
                          : Icons
                              .verified_user_rounded,
                  color:
                      Colors.white70,
                  size:
                      22,
                ),
            ],
          ),
          const SizedBox(
            height:
                7,
          ),
          Text(
            isAuthenticated
                ? email
                : 'Đăng nhập để xem thông tin tài khoản',
            maxLines:
                2,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color:
                  Colors.white70,
              fontSize:
                  12.5,
              height:
                  1.4,
            ),
          ),
          const SizedBox(
            height:
                15,
          ),
          _AccountBadge(
            text:
                roleLabel,
            isPremium:
                isPremium,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACCOUNT BADGE
// ============================================================================

class _AccountBadge
    extends StatelessWidget {
  final String text;
  final bool isPremium;

  const _AccountBadge({
    required this.text,
    this.isPremium = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            10,
        vertical:
            5,
      ),
      decoration:
          BoxDecoration(
        color:
            isPremium
                ? const Color(
                    0xFFFFE7A3,
                  )
                : const Color(
                    0xFFBCE7C4,
                  ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child:
          Text(
        text,
        style:
            TextStyle(
          color:
              isPremium
                  ? const Color(
                      0xFF7A5A00,
                    )
                  : AppTheme.darkGreen,
          fontSize:
              11,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================================
// PREMIUM MENU ITEM
// ============================================================================

class _PremiumMenuItem
    extends StatelessWidget {
  final User? user;
  final bool isAuthenticated;
  final VoidCallback onTap;

  const _PremiumMenuItem({
    required this.user,
    required this.isAuthenticated,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final premiumActive =
        user?.premiumActive == true;

    final title =
        premiumActive
            ? 'Premium'
            : 'Premium';

    final subtitle =
        !isAuthenticated
            ? 'Đăng nhập để sử dụng tính năng này'
            : premiumActive
                ? 'Tài khoản Premium đang hoạt động'
                : 'Nâng cấp tài khoản và thanh toán';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom:
            10,
      ),
      decoration:
          BoxDecoration(
        color:
            AppTheme.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child:
          Material(
        color:
            Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        child:
            InkWell(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          onTap:
              onTap,
          child:
              Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  14,
              vertical:
                  13,
            ),
            child:
                Row(
              children: [
                Container(
                  width:
                      44,
                  height:
                      44,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.green.withValues(
                      alpha:
                          0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child:
                      Icon(
                    Icons
                        .workspace_premium_rounded,
                    color:
                        premiumActive
                            ? Colors
                                .green
                            : Colors
                                .green,
                    size:
                        22,
                  ),
                ),
                const SizedBox(
                  width:
                      13,
                ),
                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            const TextStyle(
                          color:
                              AppTheme.black,
                          fontSize:
                              15,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height:
                            3,
                      ),
                      Text(
                        subtitle,
                        maxLines:
                            2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AppTheme.grey,
                          fontSize:
                              12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  premiumActive
                      ? Icons
                          .check_circle_rounded
                      : Icons
                          .chevron_right_rounded,
                  color:
                      premiumActive
                          ? Colors.green
                          : AppTheme.grey,
                  size:
                      24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ACCOUNT MENU ITEM
// ============================================================================

class _AccountMenuItem
    extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom:
            10,
      ),
      decoration:
          BoxDecoration(
        color:
            AppTheme.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child:
          Material(
        color:
            Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        child:
            InkWell(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          onTap:
              onTap,
          child:
              Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  14,
              vertical:
                  13,
            ),
            child:
                Row(
              children: [
                Container(
                  width:
                      44,
                  height:
                      44,
                  decoration:
                      BoxDecoration(
                    color:
                        iconColor.withValues(
                      alpha:
                          0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child:
                      Icon(
                    icon,
                    color:
                        iconColor,
                    size:
                        22,
                  ),
                ),
                const SizedBox(
                  width:
                      13,
                ),
                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            const TextStyle(
                          color:
                              AppTheme.black,
                          fontSize:
                              15,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height:
                            3,
                      ),
                      Text(
                        subtitle,
                        maxLines:
                            2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AppTheme.grey,
                          fontSize:
                              12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      AppTheme.grey,
                  size:
                      24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}