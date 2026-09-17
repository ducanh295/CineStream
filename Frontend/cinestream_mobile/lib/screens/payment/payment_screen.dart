import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() =>
      _PaymentScreenState();
}

class _PaymentScreenState
    extends State<PaymentScreen> {
  final PaymentService _paymentService =
      PaymentService.instance;

  Timer? _pollTimer;
  Timer? _timeoutTimer;

  String _selectedPlan = '1M';

  PaymentResponse? _payment;
  PaymentStatusResponse? _paymentStatus;

  bool _isCreatingPayment = false;
  bool _isCheckingPayment = false;

  String? _errorMessage;

  // Thời gian tối đa chờ một giao dịch.
  static const Duration _paymentTimeout =
      Duration(minutes: 10);

  // Kiểm tra trạng thái thanh toán mỗi 3 giây.
  static const Duration _pollInterval =
      Duration(seconds: 3);

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  // ================================================================
  // CREATE PAYMENT
  // ================================================================

  Future<void> _createPayment() async {
    if (_isCreatingPayment ||
        _isCheckingPayment) {
      return;
    }

    _stopPolling();

    if (!mounted) {
      return;
    }

    setState(() {
      _isCreatingPayment = true;
      _errorMessage = null;
      _payment = null;
      _paymentStatus = null;
    });

    try {
      final payment =
          await _paymentService.createPayment(
        _selectedPlan,
      );

      if (!mounted) {
        return;
      }

      if (payment.orderCode.isEmpty) {
        throw Exception(
          'Không thể khởi tạo mã đơn hàng. Vui lòng thử lại.',
        );
      }

      if (payment.qrCodeUrl.isEmpty) {
        throw Exception(
          'Không thể khởi tạo mã VietQR. Vui lòng thử lại.',
        );
      }

      setState(() {
        _payment = payment;
        _isCreatingPayment = false;
        _errorMessage = null;
      });

      _startPolling();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreatingPayment = false;
        _errorMessage =
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }
  }

  // ================================================================
  // POLLING
  // ================================================================

  void _startPolling() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();

    if (_payment == null ||
        _payment!.orderCode.isEmpty ||
        !mounted) {
      return;
    }

    setState(() {
      _isCheckingPayment = true;
    });

    _pollTimer = Timer.periodic(
      _pollInterval,
      (_) {
        _checkPaymentStatus();
      },
    );

    _timeoutTimer = Timer(
      _paymentTimeout,
      _handlePaymentTimeout,
    );

    // Kiểm tra ngay sau khi tạo đơn.
    _checkPaymentStatus();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;

    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    if (mounted) {
      setState(() {
        _isCheckingPayment = false;
      });
    }
  }

  Future<void> _checkPaymentStatus() async {
    final payment = _payment;

    if (payment == null ||
        payment.orderCode.isEmpty ||
        !_isCheckingPayment) {
      return;
    }

    try {
      final status =
          await _paymentService
              .getPaymentStatus(
        payment.orderCode,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _paymentStatus = status;
        _errorMessage = null;
      });

      // ============================================================
      // SUCCESS
      // ============================================================

      if (status.isCompleted) {
        await _handlePaymentSuccess(
          status,
        );
        return;
      }

      // ============================================================
      // FAILED
      // ============================================================

      if (status.isFailed) {
        _handlePaymentFailed(
          status,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      // Không dừng polling chỉ vì một lần
      // kiểm tra trạng thái bị lỗi mạng.
      setState(() {
        _errorMessage =
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }
  }

  // ================================================================
  // SUCCESS
  // ================================================================

  Future<void> _handlePaymentSuccess(
    PaymentStatusResponse status,
  ) async {
    _stopPolling();

    if (!mounted) {
      return;
    }

    setState(() {
      _paymentStatus = status;
      _errorMessage = null;
    });

    // Tải lại User từ Backend thông qua /auth/me.
    final authProvider =
        context.read<AuthProvider>();

    await authProvider.checkLoginStatus();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Thanh toán thành công! Tài khoản đã được nâng cấp Premium.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ================================================================
  // FAILED
  // ================================================================

  void _handlePaymentFailed(
    PaymentStatusResponse status,
  ) {
    _stopPolling();

    if (!mounted) {
      return;
    }

    setState(() {
      _paymentStatus = status;
      _errorMessage =
          'Giao dịch đã thất bại.';
    });
  }

  // ================================================================
  // TIMEOUT
  // ================================================================

  void _handlePaymentTimeout() {
    _stopPolling();

    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage =
          'Đơn thanh toán đã hết thời gian chờ. '
          'Bạn có thể tạo đơn mới.';
    });
  }

  // ================================================================
  // PLAN
  // ================================================================

  List<_PaymentPlan> get _plans {
    return const [
      _PaymentPlan(
        type: '1M',
        title: '1 tháng',
        price: 2000,
        days: 30,
      ),
      _PaymentPlan(
        type: '3M',
        title: '3 tháng',
        price: 5000,
        days: 90,
      ),
      _PaymentPlan(
        type: '1Y',
        title: '1 năm',
        price: 10000,
        days: 365,
      ),
    ];
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final authProvider =
        context.watch<AuthProvider>();

    final user = authProvider.user;

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
            10,
            18,
            35,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Premium',
                style:
                    TextStyle(
                  color:
                      AppTheme.black,
                  fontSize: 34,
                  fontWeight:
                      FontWeight.w900,
                  fontFamily:
                      'Georgia',
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Nâng cấp tài khoản để sử dụng gói thành viên cao cấp.',
                style:
                    TextStyle(
                  color:
                      AppTheme.grey,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              _buildCurrentPremiumCard(
                user,
              ),

              const SizedBox(
                height: 22,
              ),

              const Text(
                'Chọn gói Premium',
                style:
                    TextStyle(
                  color:
                      AppTheme.black,
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              ..._plans.map(
                _buildPlanCard,
              ),

              const SizedBox(
                height: 20,
              ),

              if (_payment == null)
                _buildCreatePaymentButton()
              else
                _buildPaymentSection(),

              if (_errorMessage != null) ...[
                const SizedBox(
                  height: 14,
                ),
                _buildErrorCard(),
              ],
            ],
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
        'CineStream',
        style:
            TextStyle(
          color:
              AppTheme.black,
          fontSize: 22,
          fontWeight:
              FontWeight.w900,
          fontFamily:
              'Georgia',
        ),
      ),
    );
  }

  // ================================================================
  // CURRENT PREMIUM
  // ================================================================

  Widget _buildCurrentPremiumCard(
    User? user,
  ) {
    final isPremium =
        user?.premiumActive == true;

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color:
            isPremium
                ? const Color(
                    0xFF3D3210,
                  )
                : AppTheme.darkGreen,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
                BoxDecoration(
              color:
                  Colors.amber.withValues(
                alpha: 0.18,
              ),
              shape:
                  BoxShape.circle,
            ),
            child: Icon(
              isPremium
                  ? Icons
                      .workspace_premium_rounded
                  : Icons.person_rounded,
              color:
                  isPremium
                      ? Colors.amber
                      : Colors.white,
              size: 29,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium
                      ? 'Premium đang hoạt động'
                      : 'Tài khoản thường',
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  isPremium &&
                          user?.premiumExpiresAt !=
                              null
                      ? 'Hết hạn: ${_formatDate(user!.premiumExpiresAt!)}'
                      : 'Chọn một gói để nâng cấp.',
                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize:
                        12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PLAN CARD
  // ================================================================

  Widget _buildPlanCard(
    _PaymentPlan plan,
  ) {
    final selected =
        _selectedPlan ==
        plan.type;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Material(
        color:
            selected
                ? AppTheme.darkGreen
                    .withValues(
                  alpha: 0.08,
                )
                : Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        child: InkWell(
          onTap:
              _isCreatingPayment ||
                      _isCheckingPayment
                  ? null
                  : () {
                      setState(() {
                        _selectedPlan =
                            plan.type;
                        _payment = null;
                        _paymentStatus =
                            null;
                        _errorMessage =
                            null;
                      });
                    },
          borderRadius:
              BorderRadius.circular(18),
          child: Container(
            padding:
                const EdgeInsets.all(16),
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border:
                  Border.all(
                color:
                    selected
                        ? AppTheme
                            .darkGreen
                        : AppTheme
                            .darkGreen
                            .withValues(
                          alpha:
                              0.10,
                        ),
                width:
                    selected
                        ? 1.5
                        : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    color:
                        selected
                            ? AppTheme
                                .darkGreen
                            : AppTheme
                                .lightGrey,
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    Icons
                        .workspace_premium_rounded,
                    color:
                        selected
                            ? Colors
                                .white
                            : AppTheme
                                .grey,
                    size: 24,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style:
                            const TextStyle(
                          color:
                              AppTheme
                                  .black,
                          fontSize: 15,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        '${_formatMoney(plan.price)} • ${plan.days} ngày',
                        style:
                            const TextStyle(
                          color:
                              AppTheme
                                  .grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                if (selected)
                  const Icon(
                    Icons
                        .check_circle_rounded,
                    color:
                        AppTheme
                            .darkGreen,
                    size: 23,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CREATE PAYMENT BUTTON
  // ================================================================

  Widget _buildCreatePaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed:
            _isCreatingPayment
                ? null
                : _createPayment,
        icon:
            _isCreatingPayment
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                          Colors.white,
                    ),
                  )
                : const Icon(
                    Icons
                        .account_balance_rounded,
                  ),
        label: Text(
          _isCreatingPayment
              ? 'Đang tạo đơn...'
              : 'Mua gói Premium',
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              AppTheme.darkGreen,
          foregroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              30,
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // PAYMENT SECTION
  // ================================================================

  Widget _buildPaymentSection() {
    final payment =
        _payment!;

    final status =
        _paymentStatus;

    final completed =
        status?.isCompleted ==
            true;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Thanh toán VietQR',
            style:
                TextStyle(
              color: AppTheme.black,
              fontSize: 20,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Mở ứng dụng ngân hàng và quét mã QR bên dưới.',
            style:
                TextStyle(
              color: AppTheme.grey,
              fontSize: 12,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Center(
            child: Container(
              width: 260,
              height: 260,
              padding:
                  const EdgeInsets.all(
                10,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                border:
                    Border.all(
                  color:
                      AppTheme.darkGreen
                          .withValues(
                    alpha: 0.10,
                  ),
                ),
              ),
              child:
                  Image.network(
                payment.qrCodeUrl,
                fit: BoxFit.contain,
                loadingBuilder:
                    (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress ==
                      null) {
                    return child;
                  }

                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          AppTheme.darkGreen,
                    ),
                  );
                },
                errorBuilder:
                    (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          Icons
                              .broken_image_outlined,
                          color:
                              AppTheme
                                  .grey,
                          size:
                              45,
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          'Không tải được QR.',
                          style:
                              TextStyle(
                            color:
                                AppTheme
                                    .grey,
                            fontSize:
                                12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          _buildPaymentInfoRow(
            'Ngân hàng',
            payment.bankName,
          ),

          _buildPaymentInfoRow(
            'Số tài khoản',
            payment.accountNumber,
          ),

          _buildPaymentInfoRow(
            'Chủ tài khoản',
            payment.accountName,
          ),

          _buildPaymentInfoRow(
            'Số tiền',
            _formatMoney(
              payment.amount,
            ),
          ),

          _buildPaymentInfoRow(
            'Nội dung',
            payment.description,
          ),

          _buildPaymentInfoRow(
            'Mã đơn hàng',
            payment.orderCode,
          ),

          const SizedBox(
            height: 14,
          ),

          // ========================================================
          // SUCCESS
          // ========================================================

          if (completed)
            _buildStatusBox(
              icon:
                  Icons
                      .check_circle_rounded,
              title:
                  'Thanh toán thành công',
              message:
                  'Tài khoản của bạn đã được cập nhật Premium.',
              isSuccess:
                  true,
            )

          // ========================================================
          // FAILED
          // ========================================================

          else if (status?.isFailed ==
              true)
            _buildStatusBox(
              icon:
                  Icons.cancel_rounded,
              title:
                  'Thanh toán thất bại',
              message:
                  'Giao dịch không thành công. Bạn có thể tạo đơn mới.',
              isSuccess:
                  false,
            )

          // ========================================================
          // PENDING
          // ========================================================

          else if (_isCheckingPayment)
            _buildStatusBox(
              icon:
                  Icons.sync_rounded,
              title:
                  'Đang chờ thanh toán',
              message:
                  'Hệ thống đang tự động kiểm tra giao dịch...',
              isSuccess:
                  false,
            ),

          // ========================================================
          // SUCCESS BUTTON
          // ========================================================

          if (completed) ...[
            const SizedBox(
              height: 14,
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppTheme
                          .darkGreen,
                  foregroundColor:
                      Colors.white,
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
                    const Text(
                  'Quay lại tài khoản',
                ),
              ),
            ),
          ],

          // ========================================================
          // NEW PAYMENT
          // ========================================================

          if (!_isCheckingPayment &&
              !completed) ...[
            const SizedBox(
              height: 14,
            ),
            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton(
                onPressed:
                    _createPayment,
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      AppTheme.darkGreen,
                  side:
                      const BorderSide(
                    color:
                        AppTheme
                            .darkGreen,
                  ),
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
                    const Text(
                  'Tạo đơn thanh toán mới',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // PAYMENT INFO
  // ================================================================

  Widget _buildPaymentInfoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style:
                  const TextStyle(
                color:
                    AppTheme.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child:
                SelectableText(
              value,
              style:
                  const TextStyle(
                color:
                    AppTheme.black,
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STATUS BOX
  // ================================================================

  Widget _buildStatusBox({
    required IconData icon,
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    final color =
        isSuccess
            ? AppTheme.darkGreen
            : AppTheme.grey;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color:
            isSuccess
                ? AppTheme.darkGreen
                    .withValues(
                  alpha: 0.07,
                )
                : AppTheme.lightGrey,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  message,
                  style:
                      const TextStyle(
                    color:
                        AppTheme.grey,
                    fontSize: 11.5,
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

  // ================================================================
  // ERROR
  // ================================================================

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color:
            Colors.red.withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons
                .error_outline_rounded,
            color: Colors.red,
            size: 23,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              _errorMessage!,
              style:
                  const TextStyle(
                color:
                    AppTheme.grey,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // FORMAT MONEY
  // ================================================================

  String _formatMoney(
    num amount,
  ) {
    final value =
        amount.round();

    final text =
        value.toString();

    final buffer =
        StringBuffer();

    for (int i = 0;
        i < text.length;
        i++) {
      if (i > 0 &&
          (text.length - i) %
                  3 ==
              0) {
        buffer.write('.');
      }

      buffer.write(
        text[i],
      );
    }

    return '${buffer.toString()}đ';
  }

  // ================================================================
  // FORMAT DATE
  // ================================================================

  String _formatDate(
    DateTime date,
  ) {
    final local =
        date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}

// ==================================================================
// PAYMENT PLAN
// ==================================================================

class _PaymentPlan {
  final String type;
  final String title;
  final int price;
  final int days;

  const _PaymentPlan({
    required this.type,
    required this.title,
    required this.price,
    required this.days,
  });
}

