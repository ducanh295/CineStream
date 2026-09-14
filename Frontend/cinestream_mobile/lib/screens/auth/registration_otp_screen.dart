import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class RegistrationOtpScreen extends StatefulWidget {
  const RegistrationOtpScreen({
    super.key,
  });

  @override
  State<RegistrationOtpScreen> createState() =>
      _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState
    extends State<RegistrationOtpScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isSending = false;
  bool _isVerifying = false;
  bool _codeSent = false;

  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();

    _emailController.dispose();
    _codeController.dispose();

    super.dispose();
  }

  // ================================================================
  // SEND REGISTRATION OTP
  // ================================================================

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

    if (!_validateEmail(email)) {
      return;
    }

    if (_isSending ||
        _isVerifying ||
        _resendSeconds > 0) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await AuthService.instance
          .resendVerification(
            email: email,
          )
          .timeout(
        const Duration(seconds: 15),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _codeSent = true;
      });

      _startResendCooldown();

      _showMessage(
        'Mã OTP đăng ký đã được gửi đến email.',
      );
    } on TimeoutException {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Gửi OTP quá thời gian. Vui lòng thử lại.',
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
          _isSending = false;
        });
      }
    }
  }

  // ================================================================
  // VERIFY OTP
  // ================================================================

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();

    final email =
        _emailController.text.trim();

    final code =
        _codeController.text.trim();

    if (!_validateEmail(email)) {
      return;
    }

    if (code.isEmpty) {
      _showMessage(
        'Vui lòng nhập mã OTP.',
        isError: true,
      );
      return;
    }

    if (code.length < 4) {
      _showMessage(
        'Mã OTP không hợp lệ.',
        isError: true,
      );
      return;
    }

    if (_isVerifying || !_codeSent) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      await AuthService.instance
          .verifyEmail(
            email: email,
            code: code,
          )
          .timeout(
        const Duration(seconds: 15),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Xác minh email thành công.',
      );

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
    } on TimeoutException {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Xác minh OTP quá thời gian. Vui lòng thử lại.',
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
          _isVerifying = false;
        });
      }
    }
  }

  // ================================================================
  // COOLDOWN
  // ================================================================

  void _startResendCooldown() {
    _resendTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _resendSeconds = 60;
    });

    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_resendSeconds <= 1) {
          timer.cancel();

          setState(() {
            _resendSeconds = 0;
          });

          return;
        }

        setState(() {
          _resendSeconds--;
        });
      },
    );
  }

  // ================================================================
  // VALIDATE EMAIL
  // ================================================================

  bool _validateEmail(String email) {
    if (email.isEmpty) {
      _showMessage(
        'Vui lòng nhập email.',
        isError: true,
      );
      return false;
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showMessage(
        'Email không hợp lệ.',
        isError: true,
      );
      return false;
    }

    return true;
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
          onPressed:
              (_isSending || _isVerifying)
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.black,
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Xác minh đăng ký',
          style: TextStyle(
            color: AppTheme.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontFamily: 'Georgia',
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Xác minh email',
                style: TextStyle(
                  color: AppTheme.black,
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w900,
                  fontFamily: 'Georgia',
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Nhập email đăng ký để nhận mã OTP xác minh tài khoản.',
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // EMAIL
              // ==================================================

              const Text(
                'Email',
                style: TextStyle(
                  color: AppTheme.black,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    _emailController,
                enabled:
                    !_isSending &&
                    !_isVerifying,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    _inputDecoration(
                  hint:
                      'Nhập email đăng ký',
                  icon:
                      Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // SEND OTP
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 50,
                child:
                    ElevatedButton(
                  onPressed:
                      (_isSending ||
                              _isVerifying ||
                              _resendSeconds >
                                  0)
                          ? null
                          : _sendCode,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppTheme.darkGreen,
                    disabledBackgroundColor:
                        AppTheme.darkGreen
                            .withValues(
                      alpha: 0.45,
                    ),
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        28,
                      ),
                    ),
                  ),
                  child:
                      _isSending
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2.2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : Text(
                              _resendSeconds >
                                      0
                                  ? 'Gửi lại sau ${_resendSeconds}s'
                                  : _codeSent
                                      ? 'Gửi lại OTP'
                                      : 'Gửi OTP đăng ký',
                              style:
                                  const TextStyle(
                                fontSize:
                                    15,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                ),
              ),

              // ==================================================
              // OTP
              // ==================================================

              if (_codeSent) ...[
                const SizedBox(height: 25),

                const Text(
                  'Mã OTP',
                  style: TextStyle(
                    color:
                        AppTheme.black,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller:
                      _codeController,
                  enabled:
                      !_isVerifying,
                  keyboardType:
                      TextInputType.number,
                  textInputAction:
                      TextInputAction.done,
                  textAlign:
                      TextAlign.center,
                  maxLength: 6,
                  onSubmitted: (_) {
                    _verifyCode();
                  },
                  decoration:
                      _inputDecoration(
                    hint:
                        'Nhập mã OTP',
                    icon: Icons
                        .verified_outlined,
                  ).copyWith(
                    counterText: '',
                  ),
                  style:
                      const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: 6,
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // VERIFY BUTTON
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,
                  height: 52,
                  child:
                      ElevatedButton(
                    onPressed:
                        _isVerifying
                            ? null
                            : _verifyCode,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.darkGreen,
                      disabledBackgroundColor:
                          AppTheme.darkGreen
                              .withValues(
                        alpha: 0.45,
                      ),
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          28,
                        ),
                      ),
                    ),
                    child:
                        _isVerifying
                            ? const SizedBox(
                                width: 21,
                                height: 21,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2.2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Text(
                                'Xác minh email',
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
              ],

              const SizedBox(height: 24),

              // ==================================================
              // INFORMATION
              // ==================================================

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  border:
                      Border.all(
                    color:
                        AppTheme.darkGreen
                            .withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
                child:
                    const Text(
                  'Bạn cần tạo tài khoản trước trong trang Đăng ký. Trang này dùng để gửi lại và xác minh mã OTP khi chưa đăng nhập.',
                  style:
                      TextStyle(
                    color:
                        AppTheme.grey,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // INPUT DECORATION
  // ================================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(
        color:
            AppTheme.grey,
        fontSize: 13,
      ),
      prefixIcon:
          Icon(
        icon,
        color:
            AppTheme.grey,
        size: 21,
      ),
      filled: true,
      fillColor:
          Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        borderSide:
            BorderSide(
          color:
              AppTheme.darkGreen
                  .withValues(
            alpha: 0.08,
          ),
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        borderSide:
            BorderSide(
          color:
              AppTheme.darkGreen
                  .withValues(
            alpha: 0.08,
          ),
        ),
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
          width: 1.4,
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        borderSide:
            const BorderSide(
          color:
              Colors.redAccent,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        borderSide:
            const BorderSide(
          color:
              Colors.redAccent,
          width: 1.3,
        ),
      ),
    );
  }
}

