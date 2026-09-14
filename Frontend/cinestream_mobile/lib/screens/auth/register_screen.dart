import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
  });

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final TextEditingController _usernameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController
      _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ================================================================
  // REGISTER
  // ================================================================

  Future<void> _register() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    final username =
        _usernameController.text.trim();

    final email =
        _emailController.text.trim();

    final password =
        _passwordController.text;

    final confirmPassword =
        _confirmPasswordController.text;

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage(
        'Vui lòng nhập đầy đủ thông tin.',
        isError: true,
      );
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage(
        'Email không hợp lệ.',
        isError: true,
      );
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Mật khẩu phải có ít nhất 6 ký tự.',
        isError: true,
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        'Mật khẩu xác nhận không khớp.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success =
          await context
              .read<AuthProvider>()
              .register(
                username: username,
                email: email,
                password: password,
              )
              .timeout(
                const Duration(seconds: 15),
              );

      if (!mounted) {
        return;
      }

      if (!success) {
        final message =
            context
                    .read<AuthProvider>()
                    .errorMessage ??
                'Đăng ký thất bại.';

        _showMessage(
          message,
          isError: true,
        );

        return;
      }

      _showMessage(
        'Đăng ký thành công. Hãy nhập mã OTP để xác minh email.',
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted) {
        return;
      }

      // Chuyển sang trang OTP riêng.
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.registrationOtp,
      );
    } on TimeoutException {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Đăng ký quá thời gian. Vui lòng thử lại.',
        isError: true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanErrorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ================================================================
  // VALIDATE EMAIL
  // ================================================================

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  // ================================================================
  // ERROR
  // ================================================================

  String _cleanErrorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }

  // ================================================================
  // MESSAGE
  // ================================================================

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
          content: Text(message),
          backgroundColor:
              isError
                  ? Colors.red
                  : AppTheme.darkGreen,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ================================================================
  // INPUT DECORATION
  // ================================================================

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
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            BorderSide.none,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            BorderSide.none,
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            const BorderSide(
          color: AppTheme.darkGreen,
          width: 1.2,
        ),
      ),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.background,
      appBar: AppBar(
        backgroundColor:
            AppTheme.background,
        surfaceTintColor:
            Colors.transparent,
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
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            24,
            16,
            24,
            32,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TITLE
              // ==================================================

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
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.grey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ==================================================
              // USERNAME
              // ==================================================

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
                controller:
                    _usernameController,
                enabled:
                    !_isSubmitting,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    _inputDecoration(
                  hintText:
                      'Nhập tên người dùng',
                  icon:
                      Icons.person_outline_rounded,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // EMAIL
              // ==================================================

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
                controller:
                    _emailController,
                enabled:
                    !_isSubmitting,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    _inputDecoration(
                  hintText: 'Nhập email',
                  icon:
                      Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // PASSWORD
              // ==================================================

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
                controller:
                    _passwordController,
                enabled:
                    !_isSubmitting,
                obscureText:
                    _obscurePassword,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    _inputDecoration(
                  hintText:
                      'Nhập mật khẩu',
                  icon:
                      Icons.lock_outline_rounded,
                  suffixIcon:
                      IconButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                    icon: Icon(
                      _obscurePassword
                          ? Icons
                              .visibility_outlined
                          : Icons
                              .visibility_off_outlined,
                      color:
                          AppTheme.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // CONFIRM PASSWORD
              // ==================================================

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
                controller:
                    _confirmPasswordController,
                enabled:
                    !_isSubmitting,
                obscureText:
                    _obscureConfirmPassword,
                textInputAction:
                    TextInputAction.done,
                onSubmitted: (_) {
                  _register();
                },
                decoration:
                    _inputDecoration(
                  hintText:
                      'Nhập lại mật khẩu',
                  icon:
                      Icons.lock_outline_rounded,
                  suffixIcon:
                      IconButton(
                    onPressed:
                        _isSubmitting
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
                      color:
                          AppTheme.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // REGISTER BUTTON
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 54,
                child:
                    ElevatedButton(
                  onPressed:
                      _isSubmitting
                          ? null
                          : _register,
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
                  child:
                      _isSubmitting
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
                              'Đăng ký',
                              style:
                                  TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // LOGIN
              // ==================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    'Đã có tài khoản? ',
                    style:
                        TextStyle(
                      color:
                          AppTheme.grey,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () {
                                Navigator
                                    .pushReplacementNamed(
                                  context,
                                  AppRoutes.login,
                                );
                              },
                    child:
                        const Text(
                      'Đăng nhập',
                      style:
                          TextStyle(
                        color:
                            AppTheme.darkGreen,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ==================================================
              // REGISTRATION OTP
              // ==================================================

              Center(
                child:
                    TextButton(
                  onPressed:
                      _isSubmitting
                          ? null
                          : () {
                              Navigator
                                  .pushNamed(
                                context,
                                AppRoutes
                                    .registrationOtp,
                              );
                            },
                  child:
                      const Text(
                    'Đã có tài khoản nhưng chưa xác minh email?',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          AppTheme.darkGreen,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
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

