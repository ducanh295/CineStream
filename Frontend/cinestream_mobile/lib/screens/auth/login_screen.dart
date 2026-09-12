import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
const LoginScreen({super.key});

@override
State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
final TextEditingController _usernameOrEmailController =
TextEditingController();

final TextEditingController _passwordController =
TextEditingController();

final TextEditingController _forgotEmailController =
TextEditingController();

bool _obscurePassword = true;
bool _isSubmitting = false;

@override
void dispose() {
_usernameOrEmailController.dispose();
_passwordController.dispose();
_forgotEmailController.dispose();
super.dispose();
}

Future<void> _login() async {
if (_isSubmitting) {
return;
}


FocusScope.of(context).unfocus();

final usernameOrEmail =
    _usernameOrEmailController.text.trim();
final password = _passwordController.text;

if (usernameOrEmail.isEmpty || password.isEmpty) {
  _showMessage(
    'Vui lòng nhập đầy đủ thông tin.',
  );
  return;
}

setState(() {
  _isSubmitting = true;
});

final success =
    await context.read<AuthProvider>().login(
          usernameOrEmail: usernameOrEmail,
          password: password,
        );

if (!mounted) {
  return;
}

setState(() {
  _isSubmitting = false;
});

if (!success) {
  final message =
      context.read<AuthProvider>().errorMessage ??
          'Đăng nhập thất bại.';

  _showMessage(message);
  return;
}

_showMessage(
  'Đăng nhập thành công.',
);

await Future<void>.delayed(
  const Duration(milliseconds: 300),
);

if (!mounted) {
  return;
}

Navigator.pushNamedAndRemoveUntil(
  context,
  AppRoutes.home,
  (route) => false,
);


}

Future<void> _showForgotPasswordDialog() async {
_forgotEmailController.clear();


final authProvider = context.read<AuthProvider>();

await showDialog<void>(
  context: context,
  builder: (dialogContext) {
    bool isLoading = false;

    Future<void> submit() async {
      if (isLoading) {
        return;
      }

      final email =
          _forgotEmailController.text.trim();

      if (email.isEmpty) {
        _showMessage('Vui lòng nhập email.');
        return;
      }

      if (!_isValidEmail(email)) {
        _showMessage('Email không hợp lệ.');
        return;
      }

      setState(() {
        isLoading = true;
      });

      final success =
          await authProvider.forgotPassword(
        email: email,
      );

      if (!mounted) {
        return;
      }

      if (!success) {
        setState(() {
          isLoading = false;
        });

        final message =
            authProvider.errorMessage ??
                'Không thể gửi mã đặt lại mật khẩu.';

        _showMessage(message);
        return;
      }

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      _showMessage(
        'Mã đặt lại mật khẩu đã được gửi đến email của bạn.',
      );
    }

    return StatefulBuilder(
      builder: (context, setDialogState) {
        void updateLoading(bool value) {
          setDialogState(() {
            isLoading = value;
          });
        }

        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: const Text(
            'Quên mật khẩu',
            style: TextStyle(
              color: AppTheme.black,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: _forgotEmailController,
            enabled: !isLoading,
            keyboardType:
                TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Nhập email của bạn',
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppTheme.darkGreen,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
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
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      updateLoading(true);
                      await submit();
                    },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppTheme.darkGreen,
                foregroundColor:
                    Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Gửi mã',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  },
);


}

bool _isValidEmail(String email) {
return RegExp(
r'^[^@\s]+@[^@\s]+.[^@\s]+$',
).hasMatch(email);
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

InputDecoration _inputDecoration({
required String hintText,
required IconData icon,
Widget? suffixIcon,
}) {
return InputDecoration(
hintText: hintText,
prefixIcon: Icon(
icon,
color: AppTheme.darkGreen,
),
suffixIcon: suffixIcon,
filled: true,
fillColor: Colors.white,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: BorderSide.none,
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: BorderSide.none,
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: AppTheme.darkGreen,
width: 1.2,
),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppTheme.background,
appBar: AppBar(
backgroundColor: AppTheme.background,
surfaceTintColor: Colors.transparent,
elevation: 0,
leading: IconButton(
onPressed: _isSubmitting
? null
: () {
Navigator.pop(context);
},
icon: const Icon(
Icons.arrow_back_rounded,
color: AppTheme.black,
),
),
),
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.fromLTRB(
24,
20,
24,
32,
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Center(
child: Container(
width: 72,
height: 72,
decoration: BoxDecoration(
color: AppTheme.darkGreen,
borderRadius:
BorderRadius.circular(20),
),
child: const Icon(
Icons.movie_creation_outlined,
color: Colors.white,
size: 38,
),
),
),
const SizedBox(height: 24),
const Center(
child: Text(
'Đăng nhập',
style: TextStyle(
color: AppTheme.black,
fontSize: 32,
fontWeight: FontWeight.w900,
fontFamily: 'Georgia',
),
),
),
const SizedBox(height: 8),
const Center(
child: Text(
'Đăng nhập để tiếp tục trải nghiệm CineStream',
textAlign: TextAlign.center,
style: TextStyle(
color: AppTheme.grey,
fontSize: 13,
height: 1.4,
),
),
),
const SizedBox(height: 34),
const Text(
'Email hoặc tên người dùng',
style: TextStyle(
color: AppTheme.black,
fontSize: 14,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 8),
TextField(
controller:
_usernameOrEmailController,
enabled: !_isSubmitting,
keyboardType:
TextInputType.emailAddress,
textInputAction:
TextInputAction.next,
decoration: _inputDecoration(
hintText:
'Nhập email hoặc tên người dùng',
icon:
Icons.person_outline_rounded,
),
),
const SizedBox(height: 20),
const Text(
'Mật khẩu',
style: TextStyle(
color: AppTheme.black,
fontSize: 14,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 8),
TextField(
controller: _passwordController,
enabled: !_isSubmitting,
obscureText: _obscurePassword,
textInputAction:
TextInputAction.done,
onSubmitted: (value) {
_login();
},
decoration: _inputDecoration(
hintText: 'Nhập mật khẩu',
icon:
Icons.lock_outline_rounded,
suffixIcon: IconButton(
onPressed: _isSubmitting
? null
: () {
setState(() {
_obscurePassword =
!_obscurePassword;
});
},
icon: Icon(
_obscurePassword
? Icons.visibility_outlined
: Icons
.visibility_off_outlined,
color: AppTheme.grey,
),
),
),
),
const SizedBox(height: 12),
Align(
alignment:
Alignment.centerRight,
child: TextButton(
onPressed: _isSubmitting
? null
: _showForgotPasswordDialog,
child: const Text(
'Quên mật khẩu?',
style: TextStyle(
color: AppTheme.darkGreen,
fontWeight: FontWeight.w700,
),
),
),
),
const SizedBox(height: 14),
SizedBox(
width: double.infinity,
height: 54,
child: ElevatedButton(
onPressed:
_isSubmitting ? null : _login,
style:
ElevatedButton.styleFrom(
backgroundColor:
AppTheme.darkGreen,
foregroundColor:
Colors.white,
disabledBackgroundColor:
AppTheme.darkGreen
.withValues(alpha: 0.5),
elevation: 0,
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(16),
),
),
child: _isSubmitting
? const SizedBox(
width: 22,
height: 22,
child:
CircularProgressIndicator(
strokeWidth: 2.2,
color: Colors.white,
),
)
: const Text(
'Đăng nhập',
style: TextStyle(
fontSize: 15,
fontWeight:
FontWeight.w800,
),
),
),
),
const SizedBox(height: 24),
Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
const Text(
'Chưa có tài khoản? ',
style: TextStyle(
color: AppTheme.grey,
fontSize: 13,
),
),
TextButton(
onPressed: _isSubmitting
? null
: () {
Navigator.pushNamed(
context,
AppRoutes.register,
);
},
child: const Text(
'Đăng ký',
style: TextStyle(
color:
AppTheme.darkGreen,
fontWeight:
FontWeight.w800,
),
),
),
],
),
],
),
),
),
);
}
}
