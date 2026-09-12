import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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

  final AuthService _authService =
      AuthService.instance;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) {
      return;
    }

    final username =
        _usernameController.text.trim();

    final email =
        _emailController.text.trim();

    final password =
        _passwordController.text;

    final confirmPassword =
        _confirmPasswordController.text;

    // ----------------------------------------------------------
    // KIỂM TRA RỖNG
    // ----------------------------------------------------------

    if (username.isEmpty &&
        email.isEmpty &&
        password.isEmpty &&
        confirmPassword.isEmpty) {
      _showMessage(
        'Vui lòng nhập đầy đủ thông tin.',
      );
      return;
    }

    if (username.isEmpty) {
      _showMessage(
        'Vui lòng nhập tên người dùng.',
      );
      return;
    }

    if (email.isEmpty) {
      _showMessage(
        'Vui lòng nhập email.',
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        'Vui lòng nhập mật khẩu.',
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage(
        'Vui lòng xác nhận mật khẩu.',
      );
      return;
    }

    // ----------------------------------------------------------
    // USERNAME
    // Backend yêu cầu từ 3 đến 50 ký tự
    // ----------------------------------------------------------

    if (username.length < 3 ||
        username.length > 50) {
      _showMessage(
        'Tên người dùng phải từ 3 đến 50 ký tự.',
      );
      return;
    }

    // ----------------------------------------------------------
    // EMAIL
    // ----------------------------------------------------------

    if (!_isValidEmail(email)) {
      _showMessage(
        'Định dạng email không hợp lệ.',
      );
      return;
    }

    // ----------------------------------------------------------
    // PASSWORD
    // Backend yêu cầu tối thiểu 6 ký tự
    // ----------------------------------------------------------

    if (password.length < 6) {
      _showMessage(
        'Mật khẩu phải có ít nhất 6 ký tự.',
      );
      return;
    }

    // ----------------------------------------------------------
    // CONFIRM PASSWORD
    // ----------------------------------------------------------

    if (password != confirmPassword) {
      _showMessage(
        'Mật khẩu xác nhận không khớp.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // --------------------------------------------------------
      // GỌI API ĐĂNG KÝ
      // --------------------------------------------------------

      await _authService.register(
        username: username,
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // CHUYỂN SANG XÁC THỰC EMAIL
      // --------------------------------------------------------

      _showMessage(
        'Đăng ký thành công. Mã xác thực đã được gửi đến email của bạn.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.verifyEmail,
        (route) => false,
        arguments: email,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(email);
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
            const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
          onPressed: _isLoading
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
                    color:
                        AppTheme.black,
                    fontSize: 32,
                    fontWeight:
                        FontWeight.w900,
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
                    color:
                        AppTheme.grey,
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
                  color:
                      AppTheme.black,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    _usernameController,
                enabled: !_isLoading,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    InputDecoration(
                  hintText:
                      'Nhập tên người dùng',
                  prefixIcon:
                      const Icon(
                    Icons
                        .person_outline_rounded,
                    color:
                        AppTheme.darkGreen,
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          AppTheme.darkGreen,
                      width: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // EMAIL
              // ==================================================

              const Text(
                'Email',
                style: TextStyle(
                  color:
                      AppTheme.black,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    _emailController,
                enabled: !_isLoading,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    InputDecoration(
                  hintText:
                      'Nhập email',
                  prefixIcon:
                      const Icon(
                    Icons.email_outlined,
                    color:
                        AppTheme.darkGreen,
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          AppTheme.darkGreen,
                      width: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // PASSWORD
              // ==================================================

              const Text(
                'Mật khẩu',
                style: TextStyle(
                  color:
                      AppTheme.black,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    _passwordController,
                enabled: !_isLoading,
                obscureText:
                    _obscurePassword,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    InputDecoration(
                  hintText:
                      'Nhập mật khẩu',
                  prefixIcon:
                      const Icon(
                    Icons
                        .lock_outline_rounded,
                    color:
                        AppTheme.darkGreen,
                  ),
                  suffixIcon:
                      IconButton(
                    onPressed:
                        _isLoading
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
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          AppTheme.darkGreen,
                      width: 1.2,
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
                  color:
                      AppTheme.black,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    _confirmPasswordController,
                enabled: !_isLoading,
                obscureText:
                    _obscureConfirmPassword,
                textInputAction:
                    TextInputAction.done,
                onSubmitted: (_) {
                  _register();
                },
                decoration:
                    InputDecoration(
                  hintText:
                      'Nhập lại mật khẩu',
                  prefixIcon:
                      const Icon(
                    Icons
                        .lock_outline_rounded,
                    color:
                        AppTheme.darkGreen,
                  ),
                  suffixIcon:
                      IconButton(
                    onPressed:
                        _isLoading
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
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          AppTheme.darkGreen,
                      width: 1.2,
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
                      _isLoading
                          ? null
                          : _register,
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        AppTheme.darkGreen,
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        AppTheme.darkGreen
                            .withValues(
                      alpha: 0.55,
                    ),
                    disabledForegroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2.2,
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
                    style: TextStyle(
                      color:
                          AppTheme.grey,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _isLoading
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