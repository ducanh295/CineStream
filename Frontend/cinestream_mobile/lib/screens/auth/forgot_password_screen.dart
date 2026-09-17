import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
  });

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController =
      TextEditingController();
  final _confirmPasswordController =
      TextEditingController();

  bool _isSendingCode = false;
  bool _isResetting = false;
  bool _codeSent = false;

  int _resendSeconds = 0;
  Timer? _resendTimer;

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _resendTimer?.cancel();

    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ================================================================
  // SEND OTP
  // ================================================================

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();

    if (!_validateEmail()) {
      return;
    }

    if (_isSendingCode || _resendSeconds > 0) {
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      await AuthService.instance
          .forgotPassword(
            email: _emailController.text.trim(),
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
        'Mã OTP đã được gửi đến email của bạn.',
      );
    } on TimeoutException {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Gửi mã OTP quá thời gian. Vui lòng thử lại.',
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
          _isSendingCode = false;
        });
      }
    }
  }

  // ================================================================
  // RESET PASSWORD
  // ================================================================

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_codeSent || _isResetting) {
      return;
    }

    setState(() {
      _isResetting = true;
    });

    try {
      await AuthService.instance
          .resetPassword(
            email: _emailController.text.trim(),
            code: _codeController.text.trim(),
            newPassword:
                _newPasswordController.text.trim(),
          )
          .timeout(
        const Duration(seconds: 15),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Đặt lại mật khẩu thành công.',
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
        'Đặt lại mật khẩu quá thời gian. Vui lòng thử lại.',
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
          _isResetting = false;
        });
      }
    }
  }

  // ================================================================
  // RESEND COOLDOWN
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
  // EMAIL VALIDATION
  // ================================================================

  bool _validateEmail() {
    final email =
        _emailController.text.trim();

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
              (_isSendingCode ||
                      _isResetting)
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
          'Quên mật khẩu',
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // TITLE
                // ==================================================

                const Text(
                  'Khôi phục tài khoản',
                  style: TextStyle(
                    color: AppTheme.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Georgia',
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Nhập email để nhận mã OTP và đặt lại mật khẩu.',
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

                _buildField(
                  controller:
                      _emailController,
                  label: 'Email',
                  hint:
                      'Nhập email tài khoản',
                  icon:
                      Icons.email_outlined,
                  keyboardType:
                      TextInputType
                          .emailAddress,
                  enabled:
                      !_isResetting,
                ),

                const SizedBox(height: 14),

                // ==================================================
                // SEND OTP BUTTON
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,
                  height: 50,
                  child:
                      ElevatedButton(
                    onPressed:
                        (_isSendingCode ||
                                _isResetting ||
                                _resendSeconds >
                                    0)
                            ? null
                            : _sendCode,
                    style:
                        ElevatedButton
                            .styleFrom(
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
                            BorderRadius
                                .circular(
                          28,
                        ),
                      ),
                    ),
                    child:
                        _isSendingCode
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
                                        ? 'Gửi lại mã OTP'
                                        : 'Gửi mã OTP',
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
                // OTP + NEW PASSWORD
                // ==================================================

                if (_codeSent) ...[
                  const SizedBox(
                    height: 25,
                  ),

                  _buildField(
                    controller:
                        _codeController,
                    label: 'Mã OTP',
                    hint: 'Nhập mã OTP',
                    icon: Icons
                        .verified_outlined,
                    keyboardType:
                        TextInputType.number,
                    enabled:
                        !_isResetting,
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _buildPasswordField(
                    controller:
                        _newPasswordController,
                    label: 'Mật khẩu mới',
                    hint:
                        'Nhập mật khẩu mới',
                    obscureText:
                        _obscureNewPassword,
                    enabled:
                        !_isResetting,
                    onToggle: () {
                      setState(() {
                        _obscureNewPassword =
                            !_obscureNewPassword;
                      });
                    },
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _buildPasswordField(
                    controller:
                        _confirmPasswordController,
                    label:
                        'Xác nhận mật khẩu',
                    hint:
                        'Nhập lại mật khẩu mới',
                    obscureText:
                        _obscureConfirmPassword,
                    enabled:
                        !_isResetting,
                    onToggle: () {
                      setState(() {
                        _obscureConfirmPassword =
                            !_obscureConfirmPassword;
                      });
                    },
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // ==================================================
                  // RESET BUTTON
                  // ==================================================

                  SizedBox(
                    width:
                        double.infinity,
                    height: 52,
                    child:
                        ElevatedButton(
                      onPressed:
                          _isResetting
                              ? null
                              : _resetPassword,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme
                                .darkGreen,
                        disabledBackgroundColor:
                            AppTheme
                                .darkGreen
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
                          _isResetting
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
                                  'Đặt lại mật khẩu',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // NORMAL FIELD
  // ================================================================

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.black,
            fontSize: 13,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType:
              keyboardType,
          decoration:
              _inputDecoration(
            hint: hint,
            icon: icon,
          ),
          validator: (value) {
            if (value == null ||
                value.trim().isEmpty) {
              return '$label không được để trống.';
            }

            if (label == 'Mã OTP' &&
                value.trim().length < 4) {
              return 'Mã OTP không hợp lệ.';
            }

            return null;
          },
        ),
      ],
    );
  }

  // ================================================================
  // PASSWORD FIELD
  // ================================================================

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required bool enabled,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.black,
            fontSize: 13,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText:
              obscureText,
          validator: (value) {
            final text =
                value ?? '';

            if (text.isEmpty) {
              return '$label không được để trống.';
            }

            if (label ==
                    'Mật khẩu mới' &&
                text.length < 6) {
              return 'Mật khẩu phải có ít nhất 6 ký tự.';
            }

            if (label ==
                    'Xác nhận mật khẩu' &&
                text !=
                    _newPasswordController
                        .text) {
              return 'Mật khẩu xác nhận không khớp.';
            }

            return null;
          },
          decoration:
              _inputDecoration(
            hint: hint,
            icon: Icons
                .lock_outline_rounded,
          ).copyWith(
            suffixIcon:
                IconButton(
              onPressed: enabled
                  ? onToggle
                  : null,
              icon: Icon(
                obscureText
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
      ],
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

