import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
const RegisterScreen({super.key});

@override
State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
final TextEditingController _usernameController =
TextEditingController();

final TextEditingController _emailController =
TextEditingController();

final TextEditingController _passwordController =
TextEditingController();

final TextEditingController _confirmPasswordController =
TextEditingController();

final TextEditingController _otpController =
TextEditingController();

bool _obscurePassword = true;
bool _obscureConfirmPassword = true;
bool _isVerificationStep = false;
bool _isSubmitting = false;

@override
void dispose() {
_usernameController.dispose();
_emailController.dispose();
_passwordController.dispose();
_confirmPasswordController.dispose();
_otpController.dispose();
super.dispose();
}

Future<void> _register() async {
if (_isSubmitting) {
return;
}


FocusScope.of(context).unfocus();

final username = _usernameController.text.trim();
final email = _emailController.text.trim();
final password = _passwordController.text;
final confirmPassword = _confirmPasswordController.text;

if (username.isEmpty ||
    email.isEmpty ||
    password.isEmpty ||
    confirmPassword.isEmpty) {
  _showMessage('Vui lòng nhập đầy đủ thông tin.');
  return;
}

if (!_isValidEmail(email)) {
  _showMessage('Email không hợp lệ.');
  return;
}

if (password.length < 6) {
  _showMessage('Mật khẩu phải có ít nhất 6 ký tự.');
  return;
}

if (password != confirmPassword) {
  _showMessage('Mật khẩu xác nhận không khớp.');
  return;
}

setState(() {
  _isSubmitting = true;
});

final success = await context.read<AuthProvider>().register(
      username: username,
      email: email,
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
          'Đăng ký thất bại.';

  _showMessage(message);
  return;
}

setState(() {
  _isVerificationStep = true;
});

_showMessage(
  'Đăng ký thành công. Mã OTP đã được gửi đến email của bạn.',
);


}

Future<void> _verifyEmail() async {
if (_isSubmitting) {
return;
}


FocusScope.of(context).unfocus();

final email = _emailController.text.trim();
final code = _otpController.text.trim();

if (email.isEmpty) {
  _showMessage('Không tìm thấy email đăng ký.');
  return;
}

if (code.isEmpty) {
  _showMessage('Vui lòng nhập mã OTP.');
  return;
}

if (code.length < 4) {
  _showMessage('Mã OTP không hợp lệ.');
  return;
}

setState(() {
  _isSubmitting = true;
});

final success =
    await context.read<AuthProvider>().verifyEmail(
          email: email,
          code: code,
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
          'Xác minh email thất bại.';

  _showMessage(message);
  return;
}

_showMessage(
  'Xác minh email thành công. Vui lòng đăng nhập.',
);

await Future<void>.delayed(
  const Duration(milliseconds: 700),
);

if (!mounted) {
  return;
}

Navigator.pushReplacementNamed(
  context,
  AppRoutes.login,
);


}

Future<void> _resendOtp() async {
if (_isSubmitting) {
return;
}


FocusScope.of(context).unfocus();

final email = _emailController.text.trim();

if (email.isEmpty) {
  _showMessage('Không tìm thấy email đăng ký.');
  return;
}

setState(() {
  _isSubmitting = true;
});

final success = await context
    .read<AuthProvider>()
    .resendVerification(
      email: email,
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
          'Không thể gửi lại mã OTP.';

  _showMessage(message);
  return;
}

_showMessage(
  'Mã OTP mới đã được gửi đến email của bạn.',
);


}

void _backToRegister() {
if (_isSubmitting) {
return;
}


setState(() {
  _isVerificationStep = false;
  _otpController.clear();
});


}

bool _isValidEmail(String email) {
return RegExp(
r'^[^@\s]+@[^@\s]+.[^@\s]+$',
).hasMatch(email);
}

void _showMessage(String message) {
ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(message),
behavior: SnackBarBehavior.floating,
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
if (_isVerificationStep) {
_backToRegister();
return;
}


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
        16,
        24,
        32,
      ),
      child: _isVerificationStep
          ? _buildVerificationForm()
          : _buildRegisterForm(),
    ),
  ),
);


}

Widget _buildRegisterForm() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Center(
child: Text(
'Tạo tài khoản',
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
'Tham gia CineStream và bắt đầu khám phá thế giới điện ảnh',
textAlign: TextAlign.center,
style: TextStyle(
color: AppTheme.grey,
fontSize: 13,
height: 1.4,
),
),
),
const SizedBox(height: 32),
const Text(
'Tên người dùng',
style: TextStyle(
color: AppTheme.black,
fontSize: 14,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 8),
TextField(
controller: _usernameController,
enabled: !_isSubmitting,
textInputAction: TextInputAction.next,
decoration: _inputDecoration(
hintText: 'Nhập tên người dùng',
icon: Icons.person_outline_rounded,
),
),
const SizedBox(height: 18),
const Text(
'Email',
style: TextStyle(
color: AppTheme.black,
fontSize: 14,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 8),
TextField(
controller: _emailController,
enabled: !_isSubmitting,
keyboardType: TextInputType.emailAddress,
textInputAction: TextInputAction.next,
decoration: _inputDecoration(
hintText: 'Nhập email',
icon: Icons.email_outlined,
),
),
const SizedBox(height: 18),
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
textInputAction: TextInputAction.next,
decoration: _inputDecoration(
hintText: 'Nhập mật khẩu',
icon: Icons.lock_outline_rounded,
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
: Icons.visibility_off_outlined,
color: AppTheme.grey,
),
),
),
),
const SizedBox(height: 18),
const Text(
'Xác nhận mật khẩu',
style: TextStyle(
color: AppTheme.black,
fontSize: 14,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 8),
TextField(
controller: _confirmPasswordController,
enabled: !_isSubmitting,
obscureText: _obscureConfirmPassword,
textInputAction: TextInputAction.done,
onSubmitted: (value) {
_register();
},
decoration: _inputDecoration(
hintText: 'Nhập lại mật khẩu',
icon: Icons.lock_outline_rounded,
suffixIcon: IconButton(
onPressed: _isSubmitting
? null
: () {
setState(() {
_obscureConfirmPassword =
!_obscureConfirmPassword;
});
},
icon: Icon(
_obscureConfirmPassword
? Icons.visibility_outlined
: Icons.visibility_off_outlined,
color: AppTheme.grey,
),
),
),
),
const SizedBox(height: 28),
SizedBox(
width: double.infinity,
height: 54,
child: ElevatedButton(
onPressed: _isSubmitting ? null : _register,
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.darkGreen,
foregroundColor: Colors.white,
disabledBackgroundColor:
AppTheme.darkGreen.withValues(alpha: 0.5),
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
),
child: _isSubmitting
? const SizedBox(
width: 22,
height: 22,
child: CircularProgressIndicator(
strokeWidth: 2.2,
color: Colors.white,
),
)
: const Text(
'Đăng ký',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.w800,
),
),
),
),
const SizedBox(height: 20),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Text(
'Đã có tài khoản? ',
style: TextStyle(
color: AppTheme.grey,
fontSize: 13,
),
),
TextButton(
onPressed: _isSubmitting
? null
: () {
Navigator.pushReplacementNamed(
context,
AppRoutes.login,
);
},
child: const Text(
'Đăng nhập',
style: TextStyle(
color: AppTheme.darkGreen,
fontWeight: FontWeight.w800,
),
),
),
],
),
],
);
}

Widget _buildVerificationForm() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Center(
child: Icon(
Icons.mark_email_read_outlined,
size: 72,
color: AppTheme.darkGreen,
),
),
const SizedBox(height: 20),
const Center(
child: Text(
'Xác minh email',
style: TextStyle(
color: AppTheme.black,
fontSize: 30,
fontWeight: FontWeight.w900,
fontFamily: 'Georgia',
),
),
),
const SizedBox(height: 10),
Text(
'Nhập mã OTP đã được gửi đến\n'
'${_emailController.text.trim()}',
textAlign: TextAlign.center,
style: const TextStyle(
color: AppTheme.grey,
fontSize: 14,
height: 1.5,
),
),
const SizedBox(height: 32),
const Text(
'Mã OTP',
style: TextStyle(
color: AppTheme.black,
fontSize: 14,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 8),
TextField(
controller: _otpController,
enabled: !_isSubmitting,
keyboardType: TextInputType.number,
textInputAction: TextInputAction.done,
textAlign: TextAlign.center,
maxLength: 6,
onSubmitted: (value) {
_verifyEmail();
},
decoration: _inputDecoration(
hintText: 'Nhập mã OTP',
icon: Icons.pin_outlined,
).copyWith(
counterText: '',
),
style: const TextStyle(
fontSize: 22,
fontWeight: FontWeight.w800,
letterSpacing: 6,
),
),
const SizedBox(height: 24),
SizedBox(
width: double.infinity,
height: 54,
child: ElevatedButton(
onPressed:
_isSubmitting ? null : _verifyEmail,
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.darkGreen,
foregroundColor: Colors.white,
disabledBackgroundColor:
AppTheme.darkGreen.withValues(alpha: 0.5),
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
),
child: _isSubmitting
? const SizedBox(
width: 22,
height: 22,
child: CircularProgressIndicator(
strokeWidth: 2.2,
color: Colors.white,
),
)
: const Text(
'Xác minh email',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.w800,
),
),
),
),
const SizedBox(height: 12),
SizedBox(
width: double.infinity,
height: 50,
child: OutlinedButton(
onPressed:
_isSubmitting ? null : _resendOtp,
style: OutlinedButton.styleFrom(
foregroundColor: AppTheme.darkGreen,
side: const BorderSide(
color: AppTheme.darkGreen,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
),
child: const Text(
'Gửi lại mã OTP',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w800,
),
),
),
),
const SizedBox(height: 12),
Center(
child: TextButton(
onPressed:
_isSubmitting ? null : _backToRegister,
child: const Text(
'Quay lại chỉnh sửa thông tin',
style: TextStyle(
color: AppTheme.darkGreen,
fontWeight: FontWeight.w700,
),
),
),
),
],
);
}
}
