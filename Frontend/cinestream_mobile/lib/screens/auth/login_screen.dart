import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController
      _usernameOrEmailController =
      TextEditingController();

  final TextEditingController
      _passwordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================================================================
  // LOGIN
  // ================================================================

  Future<void> _login() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    final usernameOrEmail =
        _usernameOrEmailController.text.trim();

    final password =
        _passwordController.text.trim();

    if (usernameOrEmail.isEmpty ||
        password.isEmpty) {
      _showMessage(
        'Vui lòng nhập đầy đủ thông tin.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success =
          await context.read<AuthProvider>().login(
                usernameOrEmail:
                    usernameOrEmail,
                password: password,
              );

      if (!mounted) {
        return;
      }

      if (!success) {
        final message =
            context
                    .read<AuthProvider>()
                    .errorMessage ??
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
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ================================================================
  // MESSAGE
  // ================================================================

  void _showMessage(
    String message,
  ) {
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
              // ==================================================
              // LOGO
              // ==================================================

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
                  child:
                      const Icon(
                    Icons
                        .movie_creation_outlined,
                    color:
                        Colors.white,
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // TITLE
              // ==================================================

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

              const SizedBox(
                height: 8,
              ),

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

              const SizedBox(
                height: 34,
              ),

              // ==================================================
              // USERNAME / EMAIL
              // ==================================================

              const Text(
                'Email hoặc tên người dùng',
                style: TextStyle(
                  color:
                      AppTheme.black,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    _usernameOrEmailController,
                enabled:
                    !_isSubmitting,
                keyboardType:
                    TextInputType
                        .emailAddress,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    _inputDecoration(
                  hintText:
                      'Nhập email hoặc tên người dùng',
                  icon: Icons
                      .person_outline_rounded,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

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

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    _passwordController,
                enabled:
                    !_isSubmitting,
                obscureText:
                    _obscurePassword,
                textInputAction:
                    TextInputAction.done,
                onSubmitted: (_) {
                  _login();
                },
                decoration:
                    _inputDecoration(
                  hintText:
                      'Nhập mật khẩu',
                  icon: Icons
                      .lock_outline_rounded,
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

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // FORGOT PASSWORD
              // ==================================================

              Align(
                alignment:
                    Alignment.centerRight,
                child:
                    TextButton(
                  onPressed:
                      _isSubmitting
                          ? null
                          : () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes
                                    .forgotPassword,
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

              const SizedBox(
                height: 14,
              ),

              // ==================================================
              // LOGIN BUTTON
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
                          : _login,
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        AppTheme
                            .darkGreen,
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        AppTheme
                            .darkGreen
                            .withValues(
                      alpha: 0.5,
                    ),
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
                  child:
                      _isSubmitting
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
                                fontSize:
                                    15,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // REGISTER
              // ==================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  const Text(
                    'Chưa có tài khoản? ',
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
                            AppTheme.darkGreen,
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


