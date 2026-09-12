import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_drawer.dart';

class SupportScreen extends StatelessWidget {
const SupportScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppTheme.background,


  drawer: const AppDrawer(
    currentRoute: AppRoutes.support,
  ),

  appBar: _buildAppBar(context),

  body: SafeArea(
    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          _buildContactCard(),

          const SizedBox(height: 20),

          _buildSectionTitle('KÊNH HỖ TRỢ'),
          const SizedBox(height: 12),

          _buildSupportItem(
            icon: Icons.email_outlined,
            iconColor: Colors.deepPurple,
            title: 'Email hỗ trợ',
            subtitle: 'support@cinestream.vn',
            onTap: () {
              _showMessage(
                context,
                'Đang mở email hỗ trợ...',
              );
            },
          ),

          _buildSupportItem(
            icon: Icons.phone_outlined,
            iconColor: Colors.green,
            title: 'Điện thoại',
            subtitle: '1900 0000 • 08:00 - 22:00',
            onTap: () {
              _showMessage(
                context,
                'Đang kết nối tổng đài hỗ trợ...',
              );
            },
          ),

          _buildSupportItem(
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: Colors.blue,
            title: 'Chat trực tuyến',
            subtitle: 'Phản hồi nhanh trong giờ hỗ trợ',
            onTap: () {
              _showMessage(
                context,
                'Đang mở chat hỗ trợ...',
              );
            },
          ),

          const SizedBox(height: 20),

          _buildSectionTitle('CÂU HỎI THƯỜNG GẶP'),
          const SizedBox(height: 12),

          _buildFaqCard(
            'Làm thế nào để xem phim?',
            'Chọn một bộ phim, mở trang chi tiết và nhấn nút "Xem phim".',
          ),

          _buildFaqCard(
            'Tôi có thể cập nhật thông tin tài khoản không?',
            'Bạn có thể cập nhật thông tin hồ sơ từ trang Tài khoản.',
          ),

          _buildFaqCard(
            'Tôi gặp lỗi khi phát video thì sao?',
            'Hãy kiểm tra kết nối mạng và thử phát lại video. '
                'Nếu lỗi vẫn tiếp tục, liên hệ bộ phận hỗ trợ.',
          ),

          const SizedBox(height: 24),

          _buildFooter(),
        ],
      ),
    ),
  ),
);


}

PreferredSizeWidget _buildAppBar(BuildContext context) {
return AppBar(
backgroundColor: AppTheme.background,
surfaceTintColor: Colors.transparent,
elevation: 0,


  leading: IconButton(
    onPressed: () {
      Navigator.pop(context);
    },
    icon: const Icon(
      Icons.arrow_back_rounded,
      color: AppTheme.black,
      size: 27,
    ),
  ),

  centerTitle: true,

  title: const Text(
    'CineStream',
    style: TextStyle(
      color: AppTheme.black,
      fontSize: 23,
      fontWeight: FontWeight.w900,
      fontFamily: 'Georgia',
    ),
  ),
);


}

Widget _buildHeader() {
return const Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Liên hệ hỗ trợ',
style: TextStyle(
color: AppTheme.black,
fontSize: 32,
fontWeight: FontWeight.w900,
fontFamily: 'Georgia',
height: 1.05,
),
),


    SizedBox(height: 8),

    Text(
      'Chúng tôi luôn sẵn sàng hỗ trợ bạn trong quá trình sử dụng CineStream.',
      style: TextStyle(
        color: AppTheme.grey,
        fontSize: 13,
        height: 1.4,
      ),
    ),
  ],
);


}

Widget _buildContactCard() {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(22),
decoration: BoxDecoration(
color: AppTheme.darkGreen,
borderRadius: BorderRadius.circular(24),
),
child: Row(
children: [
Container(
width: 58,
height: 58,
decoration: BoxDecoration(
color: Colors.white.withValues(
alpha: 0.12,
),
borderRadius: BorderRadius.circular(17),
),
child: const Icon(
Icons.support_agent_rounded,
color: Colors.white,
size: 31,
),
),


      const SizedBox(width: 15),

      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn cần trợ giúp?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),

            SizedBox(height: 7),

            Text(
              'Liên hệ với đội ngũ CineStream để được hỗ trợ nhanh chóng.',
              style: TextStyle(
                color: Color(0xFFD9DDD8),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);


}

Widget _buildSectionTitle(String title) {
return Text(
title,
style: const TextStyle(
color: AppTheme.grey,
fontSize: 11,
fontWeight: FontWeight.w900,
letterSpacing: 1,
),
);
}

Widget _buildSupportItem({
required IconData icon,
required Color iconColor,
required String title,
required String subtitle,
required VoidCallback onTap,
}) {
return Container(
margin: const EdgeInsets.only(
bottom: 10,
),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
),
child: ListTile(
contentPadding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 6,
),


    onTap: onTap,

    leading: Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: iconColor.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 24,
      ),
    ),

    title: Text(
      title,
      style: const TextStyle(
        color: AppTheme.black,
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
      ),
    ),

    subtitle: Padding(
      padding: const EdgeInsets.only(
        top: 4,
      ),
      child: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.grey,
          fontSize: 11.5,
        ),
      ),
    ),

    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: AppTheme.grey,
    ),
  ),
);


}

Widget _buildFaqCard(
String question,
String answer,
) {
return Container(
margin: const EdgeInsets.only(
bottom: 10,
),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
),
child: ExpansionTile(
tilePadding: const EdgeInsets.symmetric(
horizontal: 16,
),


    childrenPadding: const EdgeInsets.fromLTRB(
      16,
      0,
      16,
      16,
    ),

    iconColor: AppTheme.darkGreen,
    collapsedIconColor: AppTheme.grey,

    title: Text(
      question,
      style: const TextStyle(
        color: AppTheme.black,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    ),

    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          answer,
          style: const TextStyle(
            color: AppTheme.grey,
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
      ),
    ],
  ),
);


}

Widget _buildFooter() {
return const Center(
child: Text(
'CineStream Support • Trải nghiệm điện ảnh đỉnh cao',
textAlign: TextAlign.center,
style: TextStyle(
color: AppTheme.grey,
fontSize: 11,
height: 1.5,
),
),
);
}

void _showMessage(
BuildContext context,
String message,
) {
ScaffoldMessenger.of(context).hideCurrentSnackBar();


ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(
      seconds: 2,
    ),
    margin: const EdgeInsets.fromLTRB(
      16,
      0,
      16,
      16,
    ),
  ),
);


}
}
