import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService.instance;

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _codeController =
      TextEditingController();

  final TextEditingController _newPasswordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSendingCode = false;
  bool _isResettingPassword = false;

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  Future<void> _sendCode() async {
    if (_isSendingCode || _isResettingPassword) {
      return;
    }

    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Vui lòng nhập email.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('Email không hợp lệ.');
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      final message = await _authService.forgotPassword(
        email: email,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _codeSent = true;
        _isSendingCode = false;
      });

      _showMessage(message);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSendingCode = false;
      });

      _showMessage(_cleanErrorMessage(e));
    }
  }

  Future<void> _resetPassword() async {
    if (_isResettingPassword || _isSendingCode) {
      return;
    }

    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword =
        _confirmPasswordController.text;

    if (email.isEmpty) {
      _showMessage('Vui lòng nhập email.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('Email không hợp lệ.');
      return;
    }

    if (code.isEmpty) {
      _showMessage('Vui lòng nhập mã OTP.');
      return;
    }

    if (code.length != 6) {
      _showMessage('Mã OTP phải gồm 6 chữ số.');
      return;
    }

    if (newPassword.isEmpty) {
      _showMessage('Vui lòng nhập mật khẩu mới.');
      return;
    }

    if (newPassword.length < 6) {
      _showMessage(
        'Mật khẩu mới phải có ít nhất 6 ký tự.',
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage(
        'Vui lòng xác nhận mật khẩu mới.',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage(
        'Mật khẩu xác nhận không khớp.',
      );
      return;
    }

    setState(() {
      _isResettingPassword = true;
    });

    try {
      final message = await _authService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isResettingPassword = false;
      });

      _showMessage(message);

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isResettingPassword = false;
      });

      _showMessage(_cleanErrorMessage(e));
    }
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
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
    final isBusy =
        _isSendingCode || _isResettingPassword;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: isBusy
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
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Center(
                child: Text(
                  'Quên mật khẩu',
                  style: TextStyle(
                    color: AppTheme.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'Nhập email để nhận mã OTP khôi phục mật khẩu',
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
                enabled: !isBusy,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
                decoration: _inputDecoration(
                  hintText:
                      'Nhập email tài khoản',
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isBusy
                      ? null
                      : _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppTheme.darkGreen,
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        AppTheme.darkGreen.withValues(
                      alpha: 0.5,
                    ),
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSendingCode
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _codeSent
                              ? 'Gửi lại mã OTP'
                              : 'Gửi mã OTP',
                          style:
                              const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                ),
              ),

              if (_codeSent) ...[
                const SizedBox(height: 28),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.darkGreen.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.mark_email_read_outlined,
                        color: AppTheme.darkGreen,
                        size: 21,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mã OTP đã được gửi đến email. Mã có hiệu lực trong 15 phút.',
                          style: TextStyle(
                            color:
                                AppTheme.black,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

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
                  controller: _codeController,
                  enabled: !isBusy,
                  keyboardType:
                      TextInputType.number,
                  maxLength: 6,
                  textInputAction:
                      TextInputAction.next,
                  decoration: _inputDecoration(
                    hintText:
                        'Nhập mã OTP 6 số',
                    icon:
                        Icons.password_rounded,
                  ).copyWith(
                    counterText: '',
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Mật khẩu mới',
                  style: TextStyle(
                    color: AppTheme.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller:
                      _newPasswordController,
                  enabled: !isBusy,
                  obscureText:
                      _obscureNewPassword,
                  textInputAction:
                      TextInputAction.next,
                  decoration: _inputDecoration(
                    hintText:
                        'Nhập mật khẩu mới',
                    icon:
                        Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      onPressed: isBusy
                          ? null
                          : () {
                              setState(() {
                                _obscureNewPassword =
                                    !_obscureNewPassword;
                              });
                            },
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons
                                .visibility_outlined
                            : Icons
                                .visibility_off_outlined,
                        color: AppTheme.grey,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Xác nhận mật khẩu mới',
                  style: TextStyle(
                    color: AppTheme.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller:
                      _confirmPasswordController,
                  enabled: !isBusy,
                  obscureText:
                      _obscureConfirmPassword,
                  textInputAction:
                      TextInputAction.done,
                  onSubmitted: (_) {
                    _resetPassword();
                  },
                  decoration: _inputDecoration(
                    hintText:
                        'Nhập lại mật khẩu mới',
                    icon:
                        Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      onPressed: isBusy
                          ? null
                          : () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons
                                .visibility_outlined
                            : Icons
                                .visibility_off_outlined,
                        color: AppTheme.grey,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isBusy
                        ? null
                        : _resetPassword,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.darkGreen,
                      foregroundColor:
                          Colors.white,
                      disabledBackgroundColor:
                          AppTheme.darkGreen
                              .withValues(
                        alpha: 0.5,
                      ),
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),
                    child: _isResettingPassword
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Text(
                            'Đặt lại mật khẩu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: isBusy
                      ? null
                      : () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.login,
                            (route) => false,
                          );
                        },
                  child: const Text(
                    'Quay lại đăng nhập',
                    style: TextStyle(
                      color: AppTheme.darkGreen,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

