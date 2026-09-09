import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _passwordController =
      TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    FocusScope.of(context).unfocus();

    final email =
        _emailController.text.trim();
    final password =
        _passwordController.text.trim();

    if (email.isEmpty ||
        password.isEmpty) {
      _showMessage(
        'Vui lòng nhập đầy đủ thông tin.',
      );
      return;
    }

    _showMessage(
      'Giao diện đăng nhập đã sẵn sàng.',
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
                  decoration:
                      BoxDecoration(
                    color:
                        AppTheme.darkGreen,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .movie_creation_outlined,
                    color:
                        Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Đăng nhập',
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
                  'Đăng nhập để tiếp tục trải nghiệm CineStream',
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
              const SizedBox(height: 34),
              const Text(
                'Email',
                style: TextStyle(
                  color: AppTheme.black,
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
                      'Nhập email của bạn',
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
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                    borderSide:
                        const BorderSide(
                      color: AppTheme
                          .darkGreen,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Mật khẩu',
                style: TextStyle(
                  color: AppTheme.black,
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
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                    borderSide:
                        const BorderSide(
                      color: AppTheme
                          .darkGreen,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _showMessage(
                      'Tính năng khôi phục mật khẩu sẽ được kết nối sau.',
                    );
                  },
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color:
                          AppTheme.darkGreen,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _login,
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
                    MainAxisAlignment
                        .center,
                children: [
                  const Text(
                    'Chưa có tài khoản? ',
                    style: TextStyle(
                      color:
                          AppTheme.grey,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator
                          .pushNamed(
                        context,
                        AppRoutes.register,
                      );
                    },
                    child: const Text(
                      'Đăng ký',
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