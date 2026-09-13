import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _displayNameController =
      TextEditingController();

  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentUser();
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD CURRENT USER
  // ============================================================

  Future<void> _loadCurrentUser() async {
    final authProvider =
        context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
      });

      return;
    }

    try {
      User? user = authProvider.user;

      // Lấy thông tin mới nhất từ backend.
      try {
        user =
            await AuthService.instance.getMe();

        if (!mounted) {
          return;
        }

        authProvider.setUserFromExternalSource(
          user,
        );
      } catch (_) {
        // Nếu getMe thất bại thì dùng dữ liệu
        // hiện có trong AuthProvider.
      }

      if (!mounted) {
        return;
      }

      _displayNameController.text =
          user?.profile?.displayName
                  ?.trim() ??
              user?.username ??
              '';

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
      });

      _showMessage(
        _cleanErrorMessage(e),
        isError: true,
      );
    }
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser =
          await AuthService.instance.updateProfile(
        displayName:
            _displayNameController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      context
          .read<AuthProvider>()
          .setUserFromExternalSource(
            updatedUser,
          );

      _showMessage(
        'Cập nhật hồ sơ thành công.',
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 350),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        updatedUser,
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
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  void _openChangePassword() {
    Navigator.pushNamed(
      context,
      AppRoutes.changePassword,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

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

  String _cleanErrorMessage(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
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
      body: _isInitializing
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    AppTheme.darkGreen,
              ),
            )
          : SafeArea(
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
                        'Chỉnh sửa hồ sơ',
                        style:
                            TextStyle(
                          fontFamily:
                              'serif',
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
                        'Cập nhật tên hiển thị của bạn.',
                        style:
                            TextStyle(
                          color:
                              AppTheme.grey,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      _buildProfileHeader(
                        authProvider.user,
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      _buildTextField(
                        controller:
                            _displayNameController,
                        label:
                            'Tên hiển thị',
                        hint:
                            'Nhập tên hiển thị',
                        icon:
                            Icons.person_outline_rounded,
                        textCapitalization:
                            TextCapitalization
                                .words,
                        validator: (value) {
                          final text =
                              value?.trim() ??
                                  '';

                          if (text.isEmpty) {
                            return 'Tên hiển thị không được để trống.';
                          }

                          if (text.length >
                              100) {
                            return 'Tên hiển thị không được vượt quá 100 ký tự.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      SizedBox(
                        width:
                            double.infinity,
                        height: 52,
                        child:
                            ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _saveProfile,
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
                                    .lightGrey,
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
                                  'Lưu thay đổi',
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
                        height: 14,
                      ),
                      SizedBox(
                        width:
                            double.infinity,
                        height: 52,
                        child:
                            OutlinedButton
                                .icon(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _openChangePassword,
                          icon: const Icon(
                            Icons
                                .lock_outline_rounded,
                            size: 20,
                          ),
                          label:
                              const Text(
                            'Đổi mật khẩu',
                            style:
                                TextStyle(
                              fontSize:
                                  14,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                AppTheme
                                    .darkGreen,
                            side:
                                const BorderSide(
                              color:
                                  AppTheme
                                      .darkGreen,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                30,
                              ),
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

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor:
          AppTheme.background,
      surfaceTintColor:
          Colors.transparent,
      elevation: 0,
      leading:
          IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon:
            const Icon(
          Icons.arrow_back_rounded,
          color:
              AppTheme.black,
        ),
      ),
      centerTitle: true,
      title:
          const Text(
        'Hồ sơ',
        style:
            TextStyle(
          color:
              AppTheme.black,
          fontSize: 20,
          fontWeight:
              FontWeight.w800,
          fontFamily:
              'serif',
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader(
    User? user,
  ) {
    final username =
        user?.username.trim() ?? '';

    final email =
        user?.email.trim() ?? '';

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color:
            AppTheme.darkGreen,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration:
                BoxDecoration(
              color:
                  Colors.white.withValues(
                alpha: 0.14,
              ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color:
                  Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  username.isEmpty
                      ? 'Tài khoản'
                      : username,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  email.isEmpty
                      ? 'Chưa có email'
                      : email,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextCapitalization
        textCapitalization =
        TextCapitalization.none,
    String? Function(String?)?
        validator,
  }) {
    return TextFormField(
      controller:
          controller,
      maxLength: 100,
      textCapitalization:
          textCapitalization,
      validator:
          validator,
      style:
          const TextStyle(
        color:
            AppTheme.black,
        fontSize: 14,
      ),
      decoration:
          InputDecoration(
        labelText:
            label,
        hintText:
            hint,
        prefixIcon:
            Padding(
          padding:
              const EdgeInsets.only(
            left: 14,
            right: 8,
          ),
          child:
              Icon(
            icon,
            color:
                AppTheme.darkGreen,
            size: 21,
          ),
        ),
        prefixIconConstraints:
            const BoxConstraints(
          minWidth: 48,
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
        counterStyle:
            const TextStyle(
          color:
              AppTheme.grey,
          fontSize: 11,
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          borderSide:
              BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          borderSide:
              BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          borderSide:
              const BorderSide(
            color:
                AppTheme.darkGreen,
            width:
                1.2,
          ),
        ),
        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          borderSide:
              const BorderSide(
            color:
                AppTheme.red,
          ),
        ),
        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          borderSide:
              const BorderSide(
            color:
                AppTheme.red,
            width:
                1.2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN REQUIRED
  // ============================================================

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
              style:
                  TextStyle(
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
              'Vui lòng đăng nhập để chỉnh sửa hồ sơ.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
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
              child:
                  ElevatedButton(
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
                child:
                    const Text(
                  'Đăng nhập',
                  style:
                      TextStyle(
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