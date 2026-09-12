import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final AuthService _authService =
      AuthService.instance;

  User? _user;

  bool _isLoading = true;
  bool _isLoggingOut = false;

  bool notificationsEnabled = true;
  bool autoplayEnabled = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD CURRENT USER
  // ============================================================

  Future<void> _loadProfile() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user =
          await _authService.getCurrentUser();

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      drawerScrimColor:
          Colors.black.withValues(
        alpha: 0.55,
      ),

      drawer: const AppDrawer(
        currentRoute: AppRoutes.profile,
      ),

      appBar: AppBar(
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
                size: 28,
                color: AppTheme.black,
              ),
            );
          },
        ),

        title: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration:
                  BoxDecoration(
                color:
                    AppTheme.darkGreen,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child: const Icon(
                Icons
                    .movie_filter_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'CineStream',
              style: TextStyle(
                color: AppTheme.black,
                fontSize: 20,
                fontWeight:
                    FontWeight.w700,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),

        centerTitle: true,

        actions: [
          IconButton(
            onPressed: _loadProfile,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.black,
              size: 25,
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.only(
              right: 8,
            ),
            child: Stack(
              clipBehavior:
                  Clip.none,
              children: [
                IconButton(
                  onPressed: () {
                    _showMessage(
                      'Bạn không có thông báo mới.',
                    );
                  },
                  icon: const Icon(
                    Icons
                        .notifications_none_rounded,
                    color:
                        AppTheme.black,
                    size: 27,
                  ),
                ),

                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration:
                        const BoxDecoration(
                      color:
                          AppTheme.darkGreen,
                      shape:
                          BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadProfile,
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
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 34,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppTheme.black,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // ==================================================
                // PROFILE
                // ==================================================

                if (_isLoading)
                  const _ProfileLoadingCard()
                else if (_errorMessage != null)
                  _ProfileErrorCard(
                    message:
                        _errorMessage!,
                    onRetry:
                        _loadProfile,
                  )
                else
                  _ProfileCard(
                    user: _user,
                    onEdit: () {
                      _showMessage(
                        'Chức năng chỉnh sửa hồ sơ sẽ được kết nối sau.',
                      );
                    },
                  ),

                const SizedBox(
                  height: 18,
                ),

                // ==================================================
                // STATISTICS
                // ==================================================

                const _StatisticsRow(),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // SETTINGS
                // ==================================================

                const Text(
                  'Cài đặt',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppTheme.black,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _SettingToggleCard(
                  icon: Icons
                      .notifications_rounded,
                  iconColor:
                      AppTheme.yellow,
                  title: 'Thông báo',
                  subtitle:
                      'Phim mới & cập nhật',
                  value:
                      notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled =
                          value;
                    });
                  },
                ),

                const SizedBox(
                  height: 10,
                ),

                _SettingToggleCard(
                  icon: Icons
                      .play_arrow_rounded,
                  iconColor:
                      AppTheme.darkGreen,
                  title:
                      'Tự động phát',
                  subtitle:
                      'Phát tập tiếp theo',
                  value:
                      autoplayEnabled,
                  onChanged: (value) {
                    setState(() {
                      autoplayEnabled =
                          value;
                    });
                  },
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // ACCOUNT / UTILITIES
                // ==================================================

                const Text(
                  'Quản lý & tiện ích',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
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
                      Icons.bookmark_rounded,
                  iconColor:
                      AppTheme.darkGreen,
                  title:
                      'Danh sách xem sau',
                  subtitle:
                      'Chưa kết nối dữ liệu',
                  onTap: () {
                    _showMessage(
                      'Danh sách xem sau chưa được kết nối.',
                    );
                  },
                ),

                _AccountMenuItem(
                  icon:
                      Icons.history_rounded,
                  iconColor:
                      Colors.blueGrey,
                  title:
                      'Lịch sử xem',
                  subtitle:
                      'Chưa kết nối dữ liệu',
                  onTap: () {
                    _showMessage(
                      'Lịch sử xem chưa được kết nối.',
                    );
                  },
                ),

                _AccountMenuItem(
                  icon:
                      Icons.star_rounded,
                  iconColor:
                      AppTheme.yellow,
                  title:
                      'Đánh giá của tôi',
                  subtitle:
                      'Chưa kết nối dữ liệu',
                  onTap: () {
                    _showMessage(
                      'Danh sách đánh giá chưa được kết nối.',
                    );
                  },
                ),

                _AccountMenuItem(
                  icon: Icons
                      .workspace_premium_rounded,
                  iconColor:
                      Colors.green,
                  title:
                      'Gói đăng ký',
                  subtitle:
                      _getRoleText(),
                  onTap: () {
                    _showMessage(
                      'Quản lý Premium sẽ được kết nối sau.',
                    );
                  },
                ),

                _AccountMenuItem(
                  icon:
                      Icons.language_rounded,
                  iconColor:
                      Colors.indigo,
                  title: 'Ngôn ngữ',
                  subtitle:
                      'Tiếng Việt',
                  onTap: () {
                    _showMessage(
                      'Tùy chọn ngôn ngữ sẽ được kết nối sau.',
                    );
                  },
                ),

                _AccountMenuItem(
                  icon:
                      Icons.help_rounded,
                  iconColor:
                      AppTheme.red,
                  title:
                      'Trợ giúp & Hỗ trợ',
                  subtitle:
                      'Giải đáp các vấn đề thường gặp',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.support,
                    );
                  },
                ),

                _AccountMenuItem(
                  icon:
                      Icons.lock_rounded,
                  iconColor:
                      Colors.orange,
                  title:
                      'Quyền riêng tư',
                  subtitle:
                      'Quản lý dữ liệu và bảo mật',
                  onTap: () {
                    _showMessage(
                      'Cài đặt quyền riêng tư chưa được kết nối.',
                    );
                  },
                ),

                const SizedBox(
                  height: 22,
                ),

                // ==================================================
                // LOGOUT
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,
                  child: Material(
                    color:
                        AppTheme.pink,
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(
                        30,
                      ),
                      onTap:
                          _isLoggingOut
                              ? null
                              : () {
                                  _showLogoutDialog(
                                    context,
                                  );
                                },
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 15,
                        ),
                        child: Center(
                          child:
                              _isLoggingOut
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                        color:
                                            AppTheme.red,
                                      ),
                                    )
                                  : const Text(
                                      'Đăng xuất',
                                      style:
                                          TextStyle(
                                        color:
                                            AppTheme.red,
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
  // ROLE
  // ============================================================

  String _getRoleText() {
    if (_user == null) {
      return 'Chưa xác định';
    }

    if (_user!.role == 1) {
      return 'Quản trị viên';
    }

    return 'Tài khoản người dùng';
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  void _showLogoutDialog(
    BuildContext context,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
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
          title: const Text(
            'Đăng xuất',
            style: TextStyle(
              color:
                  AppTheme.black,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: const Text(
            'Bạn có chắc muốn đăng xuất khỏi tài khoản?',
            style: TextStyle(
              color: AppTheme.grey,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: AppTheme.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                await _logout();
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: AppTheme.red,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoggingOut = false;
      });

      _showMessage(
        'Đăng xuất thất bại. Vui lòng thử lại.',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        duration:
            const Duration(
          seconds: 2,
        ),
      ),
    );
  }
}

// ============================================================================
// PROFILE CARD
// ============================================================================

class _ProfileCard
    extends StatelessWidget {
  final User? user;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.user,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final username =
        user?.username ?? 'Người dùng';

    final email =
        user?.email ??
            'Chưa cập nhật email';

    final role =
        user?.role == 1
            ? 'Quản trị viên'
            : 'Người dùng';

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            AppTheme.darkGreen,
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  email,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                _AccountRoleBadge(
                  text: role,
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding:
                  EdgeInsets.zero,
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ROLE BADGE
// ============================================================================

class _AccountRoleBadge
    extends StatelessWidget {
  final String text;

  const _AccountRoleBadge({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFBCE7C4),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          color:
              AppTheme.darkGreen,
          fontSize: 11,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================================
// LOADING
// ============================================================================

class _ProfileLoadingCard
    extends StatelessWidget {
  const _ProfileLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 130,
      decoration:
          BoxDecoration(
        color:
            AppTheme.darkGreen,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      child:
          const Center(
        child:
            CircularProgressIndicator(
          color:
              Colors.white,
        ),
      ),
    );
  }
}

// ============================================================================
// ERROR
// ============================================================================

class _ProfileErrorCard
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            AppTheme.white,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons
                .error_outline_rounded,
            color:
                AppTheme.red,
            size: 42,
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            message,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  AppTheme.grey,
              fontSize: 14,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          ElevatedButton(
            onPressed:
                onRetry,
            child:
                const Text(
              'Thử lại',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATISTICS
// ============================================================================

class _StatisticsRow
    extends StatelessWidget {
  const _StatisticsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child:
              _StatisticCard(
            value: '-',
            label: 'Đã xem',
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Expanded(
          child:
              _StatisticCard(
            value: '-',
            label: 'Xem sau',
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Expanded(
          child:
              _StatisticCard(
            value: '-',
            label: 'Đánh giá',
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// STATISTIC CARD
// ============================================================================

class _StatisticCard
    extends StatelessWidget {
  final String value;
  final String label;

  const _StatisticCard({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 16,
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
      child: Column(
        children: [
          Text(
            value,
            style:
                const TextStyle(
              color:
                  AppTheme.darkGreen,
              fontSize: 24,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            label,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  AppTheme.grey,
              fontSize: 12,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SETTING TOGGLE
// ============================================================================

class _SettingToggleCard
    extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>
      onChanged;

  const _SettingToggleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color:
                  iconColor.withValues(
                alpha: 0.13,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        AppTheme.black,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    color:
                        AppTheme.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Switch.adaptive(
            value: value,
            activeThumbColor:
                AppTheme.darkGreen,
            onChanged:
                onChanged,
          ),
        ],
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
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
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
      child: Material(
        color:
            Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration:
                      BoxDecoration(
                    color:
                        iconColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),

                const SizedBox(
                  width: 13,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
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
                              FontWeight
                                  .w700,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
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
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}