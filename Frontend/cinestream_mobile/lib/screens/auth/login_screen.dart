import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final AuthService _authService =
      AuthService.instance;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) {
      return;
    }

    final usernameOrEmail =
        _emailController.text.trim();

    final password =
        _passwordController.text;

    // -----------------------------
    // Kiểm tra dữ liệu đầu vào
    // -----------------------------

    if (usernameOrEmail.isEmpty &&
        password.isEmpty) {
      _showMessage(
        'Vui lòng nhập tài khoản và mật khẩu.',
      );
      return;
    }

    if (usernameOrEmail.isEmpty) {
      _showMessage(
        'Vui lòng nhập tài khoản hoặc email.',
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        'Vui lòng nhập mật khẩu.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // -----------------------------
      // Gọi API đăng nhập
      // -----------------------------

      await _authService.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Đăng nhập thành công.',
      );

      // Đợi một chút để SnackBar hiển thị
      await Future.delayed(
        const Duration(milliseconds: 300),
      );

      if (!mounted) {
        return;
      }

      // -----------------------------
      // Xóa toàn bộ stack và về Home
      // -----------------------------

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      // AuthService đã xử lý:
      // 401 → Tài khoản hoặc mật khẩu không đúng.
      // 400 → Chưa kích hoạt / bị khóa / lỗi khác.
      // Connection → Không kết nối được server.
      // 500 → Server lỗi.
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
            color:
                AppTheme.black,
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
              // ====================================================
              // LOGO
              // ====================================================

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

              // ====================================================
              // TITLE
              // ====================================================

              const Center(
                child: Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color:
                        AppTheme.black,
                    fontSize: 32,
                    fontWeight:
                        FontWeight.w900,
                    fontFamily:
                        'Georgia',
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

              // ====================================================
              // USERNAME / EMAIL
              // ====================================================

              const Text(
                'Email hoặc tên đăng nhập',
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
                      'Nhập email hoặc tên đăng nhập',
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

              const SizedBox(height: 20),

              // ====================================================
              // PASSWORD
              // ====================================================

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
                    TextInputAction.done,
                onSubmitted: (_) {
                  _login();
                },
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

              const SizedBox(height: 12),

              // ====================================================
              // FORGOT PASSWORD
              // ====================================================

              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          _showMessage(
                            'Tính năng khôi phục mật khẩu sẽ được kết nối sau.',
                          );
                        },
                  child:
                      const Text(
                    'Quên mật khẩu?',
                    style:
                        TextStyle(
                      color:
                          AppTheme.darkGreen,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ====================================================
              // LOGIN BUTTON
              // ====================================================

              SizedBox(
                width:
                    double.infinity,
                height: 54,
                child:
                    ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _login,
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
                          BorderRadius
                              .circular(
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
                          'Đăng nhập',
                          style:
                              TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ====================================================
              // REGISTER
              // ====================================================

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
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                                Navigator
                                    .pushNamed(
                                  context,
                                  AppRoutes
                                      .register,
                                );
                              },
                    child:
                        const Text(
                      'Đăng ký',
                      style:
                          TextStyle(
                        color:
                            AppTheme
                                .darkGreen,
                        fontWeight:
                            FontWeight
                                .w800,
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