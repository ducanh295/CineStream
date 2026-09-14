
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _displayNameController = TextEditingController();

  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _loadCurrentProfile();
      },
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  // ================================================================
  // LOAD CURRENT PROFILE
  // ================================================================

  Future<void> _loadCurrentProfile() async {
    if (!mounted) {
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();

      var user = authProvider.user;

      // Nếu AuthProvider chưa có User,
      // lấy dữ liệu mới nhất trực tiếp từ Backend.
      user ??= await AuthService.instance.getMe();

      if (!mounted) {
        return;
      }

      _displayNameController.text =
          user.profile?.displayName ?? '';
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _getErrorMessage(e),
        isError: true,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isInitializing = false;
    });
  }

  // ================================================================
  // SAVE DISPLAY NAME
  // ================================================================

  Future<void> _saveProfile() async {
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
      await AuthService.instance.updateProfile(
        displayName: _displayNameController.text.trim(),
        avatarUrl: null,
        bio: null,
      );

      if (!mounted) {
        return;
      }

      // Lấy User/Profile mới nhất từ Backend.
      await context.read<AuthProvider>().checkLoginStatus();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Cập nhật tên hiển thị thành công.',
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _getErrorMessage(e),
        isError: true,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  // ================================================================
  // VALIDATOR
  // ================================================================

  String? _validateDisplayName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Display Name không được để trống.';
    }

    if (text.length > 100) {
      return 'Display Name không được vượt quá 100 ký tự.';
    }

    return null;
  }

  // ================================================================
  // ERROR MESSAGE
  // ================================================================

  String _getErrorMessage(Object error) {
    return error.toString().replaceFirst(
          'Exception: ',
          '',
        );
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
              isError ? Colors.red : AppTheme.darkGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _isInitializing
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.darkGreen,
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18,
                  14,
                  18,
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
                        'Chỉnh sửa hồ sơ',
                        style: TextStyle(
                          color: AppTheme.black,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Georgia',
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Thay đổi tên hiển thị của bạn.',
                        style: TextStyle(
                          color: AppTheme.grey,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // DISPLAY NAME
                      // ==================================================

                      _buildTextField(
                        controller:
                            _displayNameController,
                        label: 'Display Name',
                        hint: 'Nhập tên hiển thị',
                        icon:
                            Icons.person_outline_rounded,
                        textInputAction:
                            TextInputAction.done,
                        validator:
                            _validateDisplayName,
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // SAVE BUTTON
                      // ==================================================

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _saveProfile,
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
                                30,
                              ),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 21,
                                  height: 21,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Lưu thay đổi',
                                  style: TextStyle(
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

  // ================================================================
  // APP BAR
  // ================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
        'CineStream',
        style: TextStyle(
          color: AppTheme.black,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontFamily: 'Georgia',
        ),
      ),
    );
  }

  // ================================================================
  // TEXT FIELD
  // ================================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
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
          enabled: !_isLoading,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLength: 100,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppTheme.grey,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: AppTheme.grey,
              size: 21,
            ),
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    AppTheme.darkGreen.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    AppTheme.darkGreen.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.darkGreen,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.redAccent,
              ),
            ),
            focusedErrorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16),
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
