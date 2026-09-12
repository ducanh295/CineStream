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

Future<void> _checkSession() async {
if (!mounted) {
return;
}


final authProvider =
    context.read<AuthProvider>();

await authProvider.checkLoginStatus();

if (!mounted) {
  return;
}

setState(() {
  _isLoadingSession = false;
});


}

Future<void> _logout() async {
final authProvider =
context.read<AuthProvider>();


await authProvider.logout();

if (!mounted) {
  return;
}

_showMessage(
  'Đã đăng xuất thành công.',
);


}

void _showLogin() {
Navigator.pushNamed(
context,
AppRoutes.login,
);
}

void _showMessage(String message) {
if (!mounted) {
return;
}


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

@override
Widget build(BuildContext context) {
final authProvider =
context.watch<AuthProvider>();


final user = authProvider.user;
final isAuthenticated =
    authProvider.isAuthenticated;

return Scaffold(
  backgroundColor: AppTheme.background,
  drawerScrimColor:
      Colors.black.withValues(alpha: 0.55),
  drawer: const AppDrawer(
    currentRoute: AppRoutes.profile,
  ),
  appBar: _buildAppBar(),
  body: SafeArea(
    top: false,
    child: _isLoadingSession
        ? const Center(
            child:
                CircularProgressIndicator(
              color: AppTheme.darkGreen,
            ),
          )
        : SingleChildScrollView(
            physics:
                const BouncingScrollPhysics(),
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
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 18),

                _ProfileCard(
                  user: user,
                  isAuthenticated:
                      isAuthenticated,
                  onEdit: isAuthenticated
                      ? () {
                          _showMessage(
                            'Chỉnh sửa hồ sơ chưa được Backend cung cấp API.',
                          );
                        }
                      : null,
                ),

                const SizedBox(height: 24),

                const Text(
                  'Tính năng',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w800,
                    color: AppTheme.black,
                  ),
                ),

                const SizedBox(height: 12),

                _AccountMenuItem(
                  icon:
                      Icons.favorite_rounded,
                  iconColor:
                      Colors.redAccent,
                  title: 'Phim yêu thích',
                  subtitle:
                      isAuthenticated
                          ? 'Danh sách phim bạn đã yêu thích'
                          : 'Đăng nhập để sử dụng tính năng này',
                  onTap:
                      isAuthenticated
                          ? () {
                              _showMessage(
                                'Danh sách yêu thích sẽ được kết nối với API Favorites.',
                              );
                            }
                          : _showLogin,
                ),

                _AccountMenuItem(
                  icon:
                      Icons.smart_toy_rounded,
                  iconColor:
                      Colors.pinkAccent,
                  title: 'AI CineBot',
                  subtitle:
                      'Tư vấn và gợi ý phim bằng AI',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chatbot,
                    );
                  },
                ),

                _AccountMenuItem(
                  icon: Icons
                      .workspace_premium_rounded,
                  iconColor: Colors.green,
                  title: 'Premium',
                  subtitle:
                      'Nâng cấp tài khoản và thanh toán',
                  onTap:
                      isAuthenticated
                          ? () {
                              _showMessage(
                                'Thanh toán Premium sẽ được kết nối với API Payments.',
                              );
                            }
                          : _showLogin,
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: isAuthenticated
                        ? AppTheme.pink
                        : AppTheme.darkGreen,
                    borderRadius:
                        BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(30),
                      onTap: _isLoadingSession
                          ? null
                          : isAuthenticated
                              ? _showLogoutDialog
                              : _showLogin,
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 15,
                        ),
                        child: Center(
                          child: Text(
                            isAuthenticated
                                ? 'Đăng xuất'
                                : 'Đăng nhập',
                            style: TextStyle(
                              color:
                                  isAuthenticated
                                      ? AppTheme.red
                                      : Colors.white,
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

PreferredSizeWidget _buildAppBar() {
return AppBar(
backgroundColor: AppTheme.background,
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
centerTitle: true,
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
actions: [
IconButton(
onPressed: () {
_showMessage(
'Backend hiện chưa có API thông báo.',
);
},
icon: const Icon(
Icons.notifications_none_rounded,
color: AppTheme.black,
size: 27,
),
),
],
);
}

void _showLogoutDialog() {
showDialog<void>(
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
}

class _ProfileCard extends StatelessWidget {
final User? user;
final bool isAuthenticated;
final VoidCallback? onEdit;

const _ProfileCard({
required this.user,
required this.isAuthenticated,
required this.onEdit,
});

@override
Widget build(BuildContext context) {
final displayName =
user?.profile?.displayName
?.trim()
.isNotEmpty ==
true
? user!.profile!.displayName!
: user?.username ?? 'Khách';


final email =
    user?.email ?? 'Chưa đăng nhập';

return Container(
  width: double.infinity,
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: AppTheme.darkGreen,
    borderRadius:
        BorderRadius.circular(24),
  ),
  child: Row(
    children: [
      Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white
              .withValues(alpha: 0.12),
          borderRadius:
              BorderRadius.circular(16),
          image: user?.profile?.avatarUrl
                      ?.trim()
                      .isNotEmpty ==
                  true
              ? DecorationImage(
                  image: NetworkImage(
                    user!.profile!.avatarUrl!,
                  ),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: user?.profile?.avatarUrl
                    ?.trim()
                    .isNotEmpty ==
                true
            ? null
            : const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 40,
              ),
      ),
      const SizedBox(width: 15),
      Expanded(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              isAuthenticated
                  ? displayName
                  : 'Khách',
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAuthenticated
                  ? email
                  : 'Đăng nhập để xem thông tin tài khoản',
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            _AccountBadge(
              text: isAuthenticated
                  ? user!.isAdmin
                      ? 'Admin'
                      : 'CineStream'
                  : 'Chưa đăng nhập',
            ),
          ],
        ),
      ),
      if (isAuthenticated)
        const SizedBox(width: 10),
      if (isAuthenticated)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white
                .withValues(alpha: 0.12),
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

class _AccountBadge
extends StatelessWidget {
final String text;

const _AccountBadge({
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
decoration: BoxDecoration(
color:
const Color(0xFFBCE7C4),
borderRadius:
BorderRadius.circular(20),
),
child: Text(
text,
style: const TextStyle(
color: AppTheme.darkGreen,
fontSize: 11,
fontWeight:
FontWeight.w800,
),
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
margin:
const EdgeInsets.only(bottom: 10),
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
color: iconColor
.withValues(alpha: 0.12),
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
const SizedBox(
height: 3,
),
Text(
subtitle,
maxLines: 2,
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
Icons
.chevron_right_rounded,
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
