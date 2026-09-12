import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyEmailScreen> createState() =>
      _VerifyEmailScreenState();
}

class _VerifyEmailScreenState
    extends State<VerifyEmailScreen> {
  final TextEditingController _codeController =
      TextEditingController();

  final AuthService _authService =
      AuthService.instance;

  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();

    // Đặt con trỏ vào ô OTP khi mở màn hình.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(
          _codeFocusNode,
        );
      }
    });
  }

  final FocusNode _codeFocusNode = FocusNode();

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // VERIFY EMAIL
  // ============================================================

  Future<void> _verifyEmail() async {
    FocusScope.of(context).unfocus();

    if (_isLoading || _isResending) {
      return;
    }

    final code = _codeController.text.trim();

    if (code.isEmpty) {
      _showMessage(
        'Vui lòng nhập mã xác thực.',
      );
      return;
    }

    if (code.length < 4 || code.length > 10) {
      _showMessage(
        'Mã xác thực phải từ 4 đến 10 ký tự.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.verifyEmail(
        email: widget.email,
        code: code,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Xác thực email thành công.',
      );

      await Future.delayed(
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
  // RESEND CODE
  // ============================================================

  Future<void> _resendCode() async {
    FocusScope.of(context).unfocus();

    if (_isLoading || _isResending) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await _authService.resendVerificationEmail(
        email: widget.email,
      );

      if (!mounted) {
        return;
      }

      _codeController.clear();

      _showMessage(
        'Mã xác thực mới đã được gửi đến email của bạn.',
      );

      FocusScope.of(context).requestFocus(
        _codeFocusNode,
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
          _isResending = false;
        });
      }
    }
  }

  // ============================================================
  // GO TO LOGIN
  // ============================================================

  void _goToLogin() {
    if (_isLoading || _isResending) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
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
          onPressed:
              _isLoading || _isResending
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
            28,
            24,
            32,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // ICON
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
                  child: const Icon(
                    Icons
                        .mark_email_read_outlined,
                    color:
                        Colors.white,
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // TITLE
              // ==================================================

              const Center(
                child: Text(
                  'Xác thực email',
                  style: TextStyle(
                    color:
                        AppTheme.black,
                    fontSize: 31,
                    fontWeight:
                        FontWeight.w900,
                    fontFamily:
                        'Georgia',
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  'Mã xác thực đã được gửi đến email của bạn.',
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

              const SizedBox(height: 10),

              Center(
                child: Text(
                  widget.email,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        AppTheme.darkGreen,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 34),

              // ==================================================
              // OTP LABEL
              // ==================================================

              const Text(
                'Mã xác thực',
                style: TextStyle(
                  color:
                      AppTheme.black,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // OTP INPUT
              // ==================================================

              TextField(
                controller:
                    _codeController,
                focusNode:
                    _codeFocusNode,
                enabled:
                    !_isLoading &&
                    !_isResending,
                keyboardType:
                    TextInputType.number,
                textInputAction:
                    TextInputAction.done,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color:
                      AppTheme.black,
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: 5,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter
                      .digitsOnly,
                  LengthLimitingTextInputFormatter(
                    10,
                  ),
                ],
                onSubmitted: (_) {
                  _verifyEmail();
                },
                decoration:
                    InputDecoration(
                  hintText:
                      'Nhập mã OTP',
                  hintStyle:
                      const TextStyle(
                    color:
                        AppTheme.grey,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w500,
                    letterSpacing: 0,
                  ),
                  prefixIcon:
                      const Icon(
                    Icons
                        .verified_outlined,
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
                  enabledBorder:
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

              const SizedBox(height: 24),

              // ==================================================
              // VERIFY BUTTON
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 54,
                child:
                    ElevatedButton(
                  onPressed:
                      _isLoading ||
                              _isResending
                          ? null
                          : _verifyEmail,
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
                          'Xác thực email',
                          style:
                              TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // RESEND
              // ==================================================

              Center(
                child: TextButton(
                  onPressed:
                      _isLoading ||
                              _isResending
                          ? null
                          : _resendCode,
                  child: _isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                          ),
                        )
                      : const Text(
                          'Gửi lại mã xác thực',
                          style:
                              TextStyle(
                            color:
                                AppTheme.darkGreen,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // BACK TO LOGIN
              // ==================================================

              Center(
                child: TextButton(
                  onPressed:
                      _isLoading ||
                              _isResending
                          ? null
                          : _goToLogin,
                  child:
                      const Text(
                    'Quay lại đăng nhập',
                    style: TextStyle(
                      color:
                          AppTheme.grey,
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