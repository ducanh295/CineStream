import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/payment_service.dart';

class PaymentServicePlan {
  PaymentServicePlan._();

  static const String oneMonth = '1M';
  static const String threeMonths = '3M';
  static const String oneYear = '1Y';
}

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PaymentService _paymentService = PaymentService.instance;

  String _selectedPlan = PaymentServicePlan.oneMonth;

  PaymentResponse? _payment;
  PaymentStatus? _paymentStatus;

  Timer? _pollingTimer;

  bool _isCreatingPayment = false;
  bool _isCheckingStatus = false;
  String? _errorMessage;

  // Giá đúng theo PaymentService.cs
  static const Map<String, int> _planPrices = {
    PaymentServicePlan.oneMonth: 50000,
    PaymentServicePlan.threeMonths: 135000,
    PaymentServicePlan.oneYear: 480000,
  };

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final text = amount.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return '${buffer.toString()}đ';
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '--';

    final local = dateTime.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _getPlanTitle(String plan) {
    switch (plan) {
      case PaymentServicePlan.oneMonth:
        return 'Premium 1 tháng';

      case PaymentServicePlan.threeMonths:
        return 'Premium 3 tháng';

      case PaymentServicePlan.oneYear:
        return 'Premium 1 năm';

      default:
        return 'Premium';
    }
  }

  String _getPlanSubtitle(String plan) {
    switch (plan) {
      case PaymentServicePlan.oneMonth:
        return 'Gói cơ bản';

      case PaymentServicePlan.threeMonths:
        return 'Tiết kiệm hơn';

      case PaymentServicePlan.oneYear:
        return 'Tiết kiệm nhất';

      default:
        return '';
    }
  }

  String _getPlanDurationText(String plan) {
    switch (plan) {
      case PaymentServicePlan.oneMonth:
        return '30 ngày';

      case PaymentServicePlan.threeMonths:
        return '90 ngày';

      case PaymentServicePlan.oneYear:
        return '365 ngày';

      default:
        return '';
    }
  }

  void _selectPlan(String plan) {
    if (_isCreatingPayment) return;

    _pollingTimer?.cancel();
    _pollingTimer = null;

    setState(() {
      _selectedPlan = plan;
      _errorMessage = null;
      _payment = null;
      _paymentStatus = null;
    });
  }

  Future<void> _createPayment() async {
    if (_isCreatingPayment) return;

    _pollingTimer?.cancel();
    _pollingTimer = null;

    setState(() {
      _isCreatingPayment = true;
      _errorMessage = null;
      _payment = null;
      _paymentStatus = null;
    });

    try {
      final payment = await _paymentService.createPayment(
        planType: _selectedPlan,
      );

      if (!mounted) return;

      setState(() {
        _payment = payment;
        _isCreatingPayment = false;
      });

      _startPolling(payment.orderCode);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCreatingPayment = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  void _startPolling(String orderCode) {
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _checkPaymentStatus(orderCode);
      },
    );

    _checkPaymentStatus(orderCode);
  }

  Future<void> _checkPaymentStatus(String orderCode) async {
    if (_isCheckingStatus) return;

    _isCheckingStatus = true;

    try {
      final status = await _paymentService.getPaymentStatus(orderCode);

      if (!mounted) {
        _isCheckingStatus = false;
        return;
      }

      setState(() {
        _paymentStatus = status;
      });

      if (status.isCompleted) {
        _pollingTimer?.cancel();
        _pollingTimer = null;

        await _refreshUser();

        if (!mounted) return;

        _showSuccessMessage();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _cleanErrorMessage(e);
        });
      }
    } finally {
      _isCheckingStatus = false;
    }
  }

  Future<void> _refreshUser() async {
    try {
      await context.read<AuthProvider>().checkLoginStatus();
    } catch (_) {}
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Thanh toán thành công! Gói Premium đã được kích hoạt.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  String _getPaymentStatusText() {
    final status = _paymentStatus;

    if (status == null) {
      return 'Đang chờ thanh toán...';
    }

    if (status.isCompleted) {
      return 'Thanh toán thành công';
    }

    switch (status.status.toLowerCase()) {
      case 'pending':
        return 'Đang chờ thanh toán...';

      case 'failed':
        return 'Thanh toán thất bại';

      default:
        return status.status;
    }
  }

  Color _getPaymentStatusColor(BuildContext context) {
    final status = _paymentStatus;

    if (status?.isCompleted == true) {
      return Colors.green;
    }

    if (status?.status.toLowerCase() == 'failed') {
      return Colors.red;
    }

    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Premium',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshUser,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildPremiumHeader(context, user),
              const SizedBox(height: 20),

              _buildPlanSection(context),

              const SizedBox(height: 20),

              _buildPaymentButton(context),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                _buildErrorMessage(context),
              ],

              if (_payment != null) ...[
                const SizedBox(height: 24),
                _buildPaymentInfo(context),
              ],

              const SizedBox(height: 28),

              _buildBenefits(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, User? user) {
    final isPremium = user?.premiumActive == true;

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'CineStream Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            isPremium
                ? 'Tài khoản Premium đang hoạt động'
                : 'Nâng cấp tài khoản để trải nghiệm đầy đủ hơn',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (isPremium && user?.premiumExpiresAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Hết hạn: ${_formatDate(user!.premiumExpiresAt)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn gói Premium',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Giá từng gói được hiển thị trước khi thanh toán.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 14),

        _buildPlanCard(
          context,
          plan: PaymentServicePlan.oneMonth,
          icon: Icons.calendar_month,
        ),

        const SizedBox(height: 12),

        _buildPlanCard(
          context,
          plan: PaymentServicePlan.threeMonths,
          icon: Icons.event_available,
          badge: 'PHỔ BIẾN',
        ),

        const SizedBox(height: 12),

        _buildPlanCard(
          context,
          plan: PaymentServicePlan.oneYear,
          icon: Icons.workspace_premium,
          badge: 'TIẾT KIỆM',
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String plan,
    required IconData icon,
    String? badge,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final isSelected = _selectedPlan == plan;
    final price = _planPrices[plan] ?? 0;

    return InkWell(
      onTap: () => _selectPlan(plan),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : theme.dividerColor.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 4),
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.12)
                    : theme.dividerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? primaryColor
                    : theme.textTheme.bodyLarge?.color,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _getPlanTitle(plan),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      if (badge != null) ...[
                        const SizedBox(width: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${_getPlanSubtitle(plan)} • ${_getPlanDurationText(plan)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _formatCurrency(price),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected
                  ? primaryColor
                  : theme.textTheme.bodySmall?.color,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton(BuildContext context) {
    final price = _planPrices[_selectedPlan] ?? 0;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isCreatingPayment ? null : _createPayment,
            icon: _isCreatingPayment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.payment),
            label: Text(
              _isCreatingPayment
                  ? 'Đang tạo thanh toán...'
                  : 'Thanh toán ${_formatCurrency(price)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Sau khi bấm Thanh toán, mã VietQR sẽ được tạo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
              ),
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
            icon: const Icon(
              Icons.close,
              color: Colors.red,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context) {
    final payment = _payment!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin thanh toán',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    payment.qrCodeUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (
                      context,
                      child,
                      loadingProgress,
                    ) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 42,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Không thể tải mã VietQR',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              _buildPaymentRow(
                context,
                title: 'Gói',
                value: _getPlanTitle(_selectedPlan),
              ),

              _buildPaymentRow(
                context,
                title: 'Số tiền',
                value: _formatCurrency(payment.amount.toInt()),
                valueBold: true,
              ),

              _buildPaymentRow(
                context,
                title: 'Ngân hàng',
                value: payment.bankName,
              ),

              _buildPaymentRow(
                context,
                title: 'Số tài khoản',
                value: payment.accountNumber,
              ),

              _buildPaymentRow(
                context,
                title: 'Chủ tài khoản',
                value: payment.accountName,
              ),

              _buildPaymentRow(
                context,
                title: 'Nội dung',
                value: payment.description,
              ),

              _buildPaymentRow(
                context,
                title: 'Thời hạn',
                value: '${payment.planDurationDays} ngày',
              ),

              _buildPaymentRow(
                context,
                title: 'Mã đơn hàng',
                value: payment.orderCode,
              ),

              _buildPaymentRow(
                context,
                title: 'Tạo lúc',
                value: _formatDate(payment.createdAt),
                isLast: true,
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _getPaymentStatusColor(context).withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _paymentStatus?.isCompleted == true
                          ? Icons.check_circle
                          : Icons.access_time,
                      color: _getPaymentStatusColor(context),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        _getPaymentStatusText(),
                        style: TextStyle(
                          color: _getPaymentStatusColor(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    if (_paymentStatus?.isCompleted != true)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _paymentStatus?.isCompleted == true
                    ? 'Gói Premium đã được kích hoạt cho tài khoản của bạn.'
                    : 'Sau khi chuyển khoản, hệ thống sẽ tự động kiểm tra và cập nhật trạng thái thanh toán.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(
    BuildContext context, {
    required String title,
    required String value,
    bool valueBold = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: valueBold
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits(BuildContext context) {
    const benefits = [
      'Xem nội dung Premium',
      'Trải nghiệm CineBot AI',
      'Không bị giới hạn bởi các tính năng Premium',
      'Gói Premium tự động cộng thêm thời gian khi mua tiếp',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quyền lợi Premium',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...benefits.map(
          (benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    benefit,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

