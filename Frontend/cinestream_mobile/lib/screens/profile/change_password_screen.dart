import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
  });

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController =
      TextEditingController();
  final _newPasswordController =
      TextEditingController();
  final _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final message =
          await AuthService.instance.changePassword(
        currentPassword:
            _currentPasswordController.text,
        newPassword:
            _newPasswordController.text,
        confirmPassword:
            _confirmPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.darkGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

      // Xóa dữ liệu đã nhập sau khi đổi mật khẩu thành công.
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message = e.toString().replaceFirst(
            'Exception: ',
            '',
          );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mật khẩu hiện tại.';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới.';
    }

    if (value.length < 6) {
      return 'Mật khẩu mới phải có ít nhất 6 ký tự.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu mới.';
    }

    if (value != _newPasswordController.text) {
      return 'Mật khẩu xác nhận không khớp.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
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
        centerTitle: true,
        title: const Text(
          'Đổi mật khẩu',
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 15, 18, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE
                const Text(
                  'Bảo mật tài khoản',
                  style: TextStyle(
                    color: AppTheme.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đặt một mật khẩu mới để bảo vệ tài khoản CineStream của bạn.',
                  style: TextStyle(
                    color: AppTheme.grey,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // CURRENT PASSWORD
                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: 'Mật khẩu hiện tại',
                  hint: 'Nhập mật khẩu hiện tại',
                  obscureText: _obscureCurrentPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureCurrentPassword =
                          !_obscureCurrentPassword;
                    });
                  },
                  validator: _validateCurrentPassword,
                ),
                const SizedBox(height: 16),

                // NEW PASSWORD
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'Mật khẩu mới',
                  hint: 'Nhập mật khẩu mới',
                  obscureText: _obscureNewPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  validator: _validateNewPassword,
                ),
                const SizedBox(height: 16),

                // CONFIRM PASSWORD
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Xác nhận mật khẩu mới',
                  hint: 'Nhập lại mật khẩu mới',
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword =
                          !_obscureConfirmPassword;
                    });
                  },
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 14),

                // REQUIREMENT
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.darkGreen.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.darkGreen,
                        size: 21,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mật khẩu mới phải có ít nhất 6 ký tự và không được trùng với mật khẩu hiện tại.',
                          style: TextStyle(
                            color: AppTheme.grey,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SUBMIT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkGreen,
                      disabledBackgroundColor:
                          AppTheme.darkGreen.withValues(
                        alpha: 0.45,
                      ),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Đổi mật khẩu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // PASSWORD FIELD HELPER WIDGET
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.black,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: !_isLoading,
          validator: validator,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppTheme.grey,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.grey,
              size: 21,
            ),
            suffixIcon: IconButton(
              onPressed: _isLoading ? null : onToggleVisibility,
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.grey,
                size: 21,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.darkGreen.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.darkGreen.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.darkGreen,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.redAccent,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}