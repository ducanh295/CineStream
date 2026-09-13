import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final authProvider =
        context.read<AuthProvider>();

    final success =
        await authProvider.changePassword(
      currentPassword:
          _currentPasswordController.text,
      newPassword:
          _newPasswordController.text,
      confirmNewPassword:
          _confirmPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      _showMessage(
        'Đổi mật khẩu thành công.',
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
      return;
    }

    final error =
        authProvider.errorMessage;

    _showMessage(
      error == null || error.isEmpty
          ? 'Đổi mật khẩu thất bại.'
          : error,
      isError: true,
    );
  }

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
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: isError
              ? AppTheme.red
              : AppTheme.darkGreen,
        ),
      );
  }

  String? _validateCurrentPassword(
    String? value,
  ) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Vui lòng nhập mật khẩu hiện tại.';
    }

    return null;
  }

  String? _validateNewPassword(
    String? value,
  ) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới.';
    }

    if (text.length < 6) {
      return 'Mật khẩu mới phải có ít nhất 6 ký tự.';
    }

    if (text.length > 100) {
      return 'Mật khẩu mới không được vượt quá 100 ký tự.';
    }

    if (text ==
        _currentPasswordController.text) {
      return 'Mật khẩu mới phải khác mật khẩu hiện tại.';
    }

    return null;
  }

  String? _validateConfirmPassword(
    String? value,
  ) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu mới.';
    }

    if (text !=
        _newPasswordController.text) {
      return 'Xác nhận mật khẩu không khớp.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        backgroundColor:
            AppTheme.background,
        appBar: _buildAppBar(),
        body: _buildLoginRequired(),
      );
    }

    return Scaffold(
      backgroundColor:
          AppTheme.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đổi mật khẩu',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 32,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppTheme.black,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Đặt lại mật khẩu để bảo vệ tài khoản của bạn.',
                  style: TextStyle(
                    color:
                        AppTheme.grey,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                _buildSecurityHeader(),
                const SizedBox(
                  height: 24,
                ),
                _buildPasswordField(
                  controller:
                      _currentPasswordController,
                  label:
                      'Mật khẩu hiện tại',
                  hint:
                      'Nhập mật khẩu hiện tại',
                  obscureText:
                      _obscureCurrentPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureCurrentPassword =
                          !_obscureCurrentPassword;
                    });
                  },
                  validator:
                      _validateCurrentPassword,
                  textInputAction:
                      TextInputAction.next,
                ),
                const SizedBox(
                  height: 16,
                ),
                _buildPasswordField(
                  controller:
                      _newPasswordController,
                  label:
                      'Mật khẩu mới',
                  hint:
                      'Nhập mật khẩu mới',
                  obscureText:
                      _obscureNewPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureNewPassword =
                          !_obscureNewPassword;
                    });
                  },
                  validator:
                      _validateNewPassword,
                  textInputAction:
                      TextInputAction.next,
                ),
                const SizedBox(
                  height: 16,
                ),
                _buildPasswordField(
                  controller:
                      _confirmPasswordController,
                  label:
                      'Xác nhận mật khẩu mới',
                  hint:
                      'Nhập lại mật khẩu mới',
                  obscureText:
                      _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword =
                          !_obscureConfirmPassword;
                    });
                  },
                  validator:
                      _validateConfirmPassword,
                  textInputAction:
                      TextInputAction.done,
                  onFieldSubmitted:
                      (_) {
                    if (!_isLoading) {
                      _changePassword();
                    }
                  },
                ),
                const SizedBox(
                  height: 12,
                ),
                _buildPasswordHint(),
                const SizedBox(
                  height: 24,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _changePassword,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.darkGreen,
                      foregroundColor:
                          Colors.white,
                      disabledBackgroundColor:
                          AppTheme.lightGrey,
                      disabledForegroundColor:
                          AppTheme.grey,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          30,
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
                                  2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Text(
                            'Đổi mật khẩu',
                            style:
                                TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w800,
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
          color:
              AppTheme.black,
        ),
      ),
      centerTitle: true,
      title: const Text(
        'Bảo mật tài khoản',
        style: TextStyle(
          color:
              AppTheme.black,
          fontSize: 19,
          fontWeight:
              FontWeight.w800,
          fontFamily:
              'serif',
        ),
      ),
    );
  }

  Widget _buildSecurityHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color:
            AppTheme.darkGreen,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration:
                BoxDecoration(
              color:
                  Colors.white.withValues(
                alpha: 0.14,
              ),
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color:
                  Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Bảo mật',
                  style: TextStyle(
                    color:
                        Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(
                  height: 4,
                ),
                Text(
                  'Mật khẩu mới phải có ít nhất 6 ký tự.',
                  style: TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordHint() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color:
              AppTheme.grey,
          size: 17,
        ),
        const SizedBox(
          width: 7,
        ),
        Expanded(
          child: Text(
            'Sau khi đổi mật khẩu thành công, hãy sử dụng mật khẩu mới cho lần đăng nhập tiếp theo.',
            style:
                const TextStyle(
              color:
                  AppTheme.grey,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?)
        validator,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      textInputAction:
          textInputAction,
      onFieldSubmitted:
          onFieldSubmitted,
      style: const TextStyle(
        color:
            AppTheme.black,
        fontSize: 14,
      ),
      decoration:
          InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color:
              AppTheme.darkGreen,
          size: 21,
        ),
        suffixIcon: IconButton(
          onPressed:
              onToggleVisibility,
          icon: Icon(
            obscureText
                ? Icons
                    .visibility_outlined
                : Icons
                    .visibility_off_outlined,
            color:
                AppTheme.grey,
            size: 21,
          ),
        ),
        filled: true,
        fillColor:
            AppTheme.white,
        labelStyle:
            const TextStyle(
          color:
              AppTheme.grey,
          fontSize: 13,
        ),
        hintStyle:
            const TextStyle(
          color:
              AppTheme.grey,
          fontSize: 13,
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide:
              BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide:
              BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide:
              const BorderSide(
            color:
                AppTheme.darkGreen,
            width: 1.2,
          ),
        ),
        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide:
              const BorderSide(
            color:
                AppTheme.red,
          ),
        ),
        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide:
              const BorderSide(
            color:
                AppTheme.red,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color:
                  AppTheme.grey,
              size: 58,
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              'Bạn chưa đăng nhập',
              style: TextStyle(
                color:
                    AppTheme.black,
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              'Vui lòng đăng nhập để đổi mật khẩu.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    AppTheme.grey,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.login,
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppTheme.darkGreen,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                  ),
                ),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}