import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final TextEditingController
      _usernameController =
      TextEditingController();

  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _passwordController =
      TextEditingController();

  final TextEditingController
      _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController
        .dispose();

    super.dispose();
  }

  void _register() {
    FocusScope.of(context).unfocus();

    final username =
        _usernameController.text.trim();
    final email =
        _emailController.text.trim();
    final password =
        _passwordController.text.trim();
    final confirmPassword =
        _confirmPasswordController
            .text
            .trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage(
        'Vui lòng nhập đầy đủ thông tin.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        'Mật khẩu xác nhận không khớp.',
      );
      return;
    }

    _showMessage(
      'Giao diện đăng ký đã sẵn sàng.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

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
          onPressed: () {
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
                        BorderRadius
                            .circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

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
                keyboardType:
                    TextInputType.emailAddress,
                decoration:
                    InputDecoration(
                  hintText:
                      'Nhập email',
                  prefixIcon:
                      const Icon(
                    Icons
                        .email_outlined,
                    color:
                        AppTheme.darkGreen,
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

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
                obscureText:
                    _obscurePassword,
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
                    onPressed: () {
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
                        BorderRadius
                            .circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

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
                obscureText:
                    _obscureConfirmPassword,
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
                    onPressed: () {
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
                        BorderRadius
                            .circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _register,
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        AppTheme.darkGreen,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Đăng ký',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
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
                    onPressed: () {
                      Navigator
                          .pushReplacementNamed(
                        context,
                        AppRoutes.login,
                      );
                    },
                    child: const Text(
                      'Đăng nhập',
                      style:
                          TextStyle(
                        color:
                            AppTheme
                                .darkGreen,
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