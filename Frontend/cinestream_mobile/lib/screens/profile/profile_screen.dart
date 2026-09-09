import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
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
  bool notificationsEnabled = true;
  bool autoplayEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawerScrimColor: Colors.black.withValues(
        alpha: 0.55,
      ),
      drawer: const AppDrawer(
        currentRoute: AppRoutes.profile,
      ),
      appBar: AppBar(
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
                size: 28,
                color: AppTheme.black,
              ),
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.darkGreen,
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.movie_filter_rounded,
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
                fontWeight: FontWeight.w700,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 12,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {
                    _showMessage(
                      'Bạn không có thông báo mới.',
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.black,
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
                      color: AppTheme.darkGreen,
                      shape: BoxShape.circle,
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
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
                  fontWeight: FontWeight.w800,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 18),
              _ProfileCard(
                onEdit: () {
                  _showMessage(
                    'Chỉnh sửa hồ sơ sẽ được kết nối sau.',
                  );
                },
              ),
              const SizedBox(height: 18),
              const _StatisticsRow(),
              const SizedBox(height: 24),
              const Text(
                'Cài đặt',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 12),
              _SettingToggleCard(
                icon: Icons.notifications_rounded,
                iconColor: AppTheme.yellow,
                title: 'Thông báo',
                subtitle: 'Phim mới & cập nhật',
                value: notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    notificationsEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              _SettingToggleCard(
                icon: Icons.play_arrow_rounded,
                iconColor: AppTheme.darkGreen,
                title: 'Tự động phát',
                subtitle: 'Phát tập tiếp theo',
                value: autoplayEnabled,
                onChanged: (value) {
                  setState(() {
                    autoplayEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Quản lý & tiện ích',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 12),
              _AccountMenuItem(
                icon: Icons.bookmark_rounded,
                iconColor: AppTheme.darkGreen,
                title: 'Danh sách xem sau',
                subtitle: '12 phim',
                onTap: () {
                  _showMessage(
                    'Danh sách xem sau sẽ được kết nối sau.',
                  );
                },
              ),
              _AccountMenuItem(
                icon: Icons.history_rounded,
                iconColor: Colors.blueGrey,
                title: 'Lịch sử xem',
                subtitle: '47 phim đã xem',
                onTap: () {
                  _showMessage(
                    'Lịch sử xem sẽ được kết nối sau.',
                  );
                },
              ),
              _AccountMenuItem(
                icon: Icons.star_rounded,
                iconColor: AppTheme.yellow,
                title: 'Đánh giá của tôi',
                subtitle: '8 đánh giá',
                onTap: () {
                  _showMessage(
                    'Danh sách đánh giá sẽ được kết nối sau.',
                  );
                },
              ),
              _AccountMenuItem(
                icon: Icons.workspace_premium_rounded,
                iconColor: Colors.green,
                title: 'Gói đăng ký',
                subtitle: 'Premium · Gia hạn 15/10',
                onTap: () {
                  _showMessage(
                    'Quản lý Premium sẽ được kết nối sau.',
                  );
                },
              ),
              _AccountMenuItem(
                icon: Icons.language_rounded,
                iconColor: Colors.indigo,
                title: 'Ngôn ngữ',
                subtitle: 'Tiếng Việt',
                onTap: () {
                  _showMessage(
                    'Tùy chọn ngôn ngữ sẽ được kết nối sau.',
                  );
                },
              ),
              _AccountMenuItem(
                icon: Icons.help_rounded,
                iconColor: AppTheme.red,
                title: 'Trợ giúp & Hỗ trợ',
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
                icon: Icons.lock_rounded,
                iconColor: Colors.orange,
                title: 'Quyền riêng tư',
                subtitle:
                    'Quản lý dữ liệu và bảo mật',
                onTap: () {
                  _showMessage(
                    'Cài đặt quyền riêng tư sẽ được kết nối sau.',
                  );
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: AppTheme.pink,
                  borderRadius:
                      BorderRadius.circular(30),
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(30),
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      child: Center(
                        child: Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: AppTheme.red,
                            fontSize: 15,
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
      bottomNavigationBar:
          const AppBottomNavigation(
        currentIndex: 4,
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Bạn có chắc muốn đăng xuất khỏi tài khoản?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: AppTheme.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showMessage(
                  'Đã đăng xuất.',
                );
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: AppTheme.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(16),
            child: Image.network(
              'https://i.pravatar.cc/180?img=12',
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) {
                return Container(
                  width: 76,
                  height: 76,
                  color: AppTheme.lightGrey,
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppTheme.grey,
                    size: 38,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Nguyễn Minh Khoa',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'minhkhoa@email.com',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 10),
                _PremiumBadge(),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
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

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFBCE7C4),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: const Text(
        'Premium',
        style: TextStyle(
          color: AppTheme.darkGreen,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatisticsRow extends StatelessWidget {
  const _StatisticsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatisticCard(
            value: '47',
            label: 'Đã xem',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatisticCard(
            value: '12',
            label: 'Xem sau',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatisticCard(
            value: '8',
            label: 'Đánh giá',
          ),
        ),
      ],
    );
  }
}

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
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.darkGreen,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingToggleCard
    extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.13,
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.grey,
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
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

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
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(18),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(18),
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
                    color: iconColor.withValues(
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
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
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
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.grey,
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