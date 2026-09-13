import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class PaymentResponse {
  final String orderCode;
  final double amount;
  final int planDurationDays;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String description;
  final String qrCodeUrl;
  final DateTime? createdAt;

  const PaymentResponse({
    required this.orderCode,
    required this.amount,
    required this.planDurationDays,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.description,
    required this.qrCodeUrl,
    required this.createdAt,
  });

  factory PaymentResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return PaymentResponse(
      orderCode:
          json['orderCode']?.toString() ?? '',
      amount:
          (json['amount'] as num?)?.toDouble() ??
              0,
      planDurationDays:
          (json['planDurationDays'] as num?)
                  ?.toInt() ??
              0,
      bankName:
          json['bankName']?.toString() ?? '',
      accountNumber:
          json['accountNumber']?.toString() ?? '',
      accountName:
          json['accountName']?.toString() ?? '',
      description:
          json['description']?.toString() ?? '',
      qrCodeUrl:
          json['qrCodeUrl']?.toString() ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(
                  json['createdAt'].toString(),
                )
              : null,
    );
  }
}

class PaymentStatus {
  final String orderCode;
  final String status;
  final bool isCompleted;
  final DateTime? completedAt;

  const PaymentStatus({
    required this.orderCode,
    required this.status,
    required this.isCompleted,
    required this.completedAt,
  });

  factory PaymentStatus.fromJson(
    Map<String, dynamic> json,
  ) {
    return PaymentStatus(
      orderCode:
          json['orderCode']?.toString() ?? '',
      status:
          json['status']?.toString() ?? '',
      isCompleted:
          json['isCompleted'] == true,
      completedAt:
          json['completedAt'] != null
              ? DateTime.tryParse(
                  json['completedAt']
                      .toString(),
                )
              : null,
    );
  }
}

class PaymentTransaction {
  final int id;
  final int userId;
  final String? userEmail;
  final String orderCode;
  final double amount;
  final int planDurationDays;
  final String status;
  final String paymentGateway;
  final String? gatewayTransactionId;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const PaymentTransaction({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.orderCode,
    required this.amount,
    required this.planDurationDays,
    required this.status,
    required this.paymentGateway,
    required this.gatewayTransactionId,
    required this.createdAt,
    required this.completedAt,
  });

  factory PaymentTransaction.fromJson(
    Map<String, dynamic> json,
  ) {
    return PaymentTransaction(
      id:
          (json['id'] as num?)?.toInt() ?? 0,
      userId:
          (json['userId'] as num?)?.toInt() ??
              0,
      userEmail:
          json['userEmail']?.toString(),
      orderCode:
          json['orderCode']?.toString() ?? '',
      amount:
          (json['amount'] as num?)?.toDouble() ??
              0,
      planDurationDays:
          (json['planDurationDays'] as num?)
                  ?.toInt() ??
              0,
      status:
          json['status']?.toString() ?? '',
      paymentGateway:
          json['paymentGateway']?.toString() ??
              '',
      gatewayTransactionId:
          json['gatewayTransactionId']
              ?.toString(),
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(
                  json['createdAt'].toString(),
                )
              : null,
      completedAt:
          json['completedAt'] != null
              ? DateTime.tryParse(
                  json['completedAt'].toString(),
                )
              : null,
    );
  }
}

class PaymentService {
  PaymentService._();

  static final PaymentService instance =
      PaymentService._();

  final Dio _dio =
      ApiClient.instance.dio;

  // ============================================================
  // CREATE PAYMENT
  // ============================================================

  Future<PaymentResponse> createPayment({
    required String planType,
  }) async {
    try {
      final response =
          await _dio.post(
        ApiConstants.createPayment,
        data: {
          'planType': planType,
        },
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(
        body,
        'Không thể tạo đơn thanh toán.',
      );

      final data =
          _asMap(body['data']);

      if (data.isEmpty) {
        throw Exception(
          'Backend không trả về thông tin thanh toán.',
        );
      }

      return PaymentResponse.fromJson(
        data,
      );
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Không thể tạo đơn thanh toán.',
        ),
      );
    }
  }

  // ============================================================
  // PAYMENT STATUS
  // ============================================================

  Future<PaymentStatus> getPaymentStatus(
    String orderCode,
  ) async {
    final code =
        orderCode.trim();

    if (code.isEmpty) {
      throw Exception(
        'Mã đơn hàng không hợp lệ.',
      );
    }

    try {
      final response =
          await _dio.get(
        '${ApiConstants.paymentStatus}/$code',
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(
        body,
        'Không thể kiểm tra trạng thái thanh toán.',
      );

      final data =
          _asMap(body['data']);

      if (data.isEmpty) {
        throw Exception(
          'Backend không trả về trạng thái thanh toán.',
        );
      }

      return PaymentStatus.fromJson(
        data,
      );
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Không thể kiểm tra trạng thái thanh toán.',
        ),
      );
    }
  }

  // ============================================================
  // HISTORY
  // ============================================================

  Future<List<PaymentTransaction>>
      getHistory() async {
    try {
      final response =
          await _dio.get(
        ApiConstants.paymentHistory,
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(
        body,
        'Không thể lấy lịch sử thanh toán.',
      );

      final data =
          body['data'];

      if (data is! List) {
        return const [];
      }

      return data
          .whereType<Map>()
          .map(
            (item) =>
                PaymentTransaction.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Không thể lấy lịch sử thanh toán.',
        ),
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Map<String, dynamic> _asMap(
    dynamic value,
  ) {
    if (value is! Map) {
      throw Exception(
        'Dữ liệu máy chủ trả về không hợp lệ.',
      );
    }

    return Map<String, dynamic>.from(
      value,
    );
  }

  void _ensureSuccess(
    Map<String, dynamic> body,
    String defaultMessage,
  ) {
    if (body['success'] != true) {
      throw Exception(
        body['message']?.toString() ??
            defaultMessage,
      );
    }
  }

  String _getErrorMessage(
    DioException error,
    String defaultMessage,
  ) {
    final responseData =
        error.response?.data;

    if (responseData is Map) {
      final body =
          _asMap(responseData);

      final message =
          body['message']
              ?.toString()
              .trim();

      if (message != null &&
          message.isNotEmpty) {
        return message;
      }

      final errors =
          body['errors'];

      if (errors is Map &&
          errors.isNotEmpty) {
        for (final value
            in errors.values) {
          if (value is List &&
              value.isNotEmpty) {
            return value.first
                .toString();
          }

          if (value != null) {
            return value.toString();
          }
        }
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Kết nối đến máy chủ quá thời gian.';

      case DioExceptionType.connectionError:
        return 'Không thể kết nối đến máy chủ.';

      case DioExceptionType.badCertificate:
        return 'Chứng chỉ máy chủ không hợp lệ.';

      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy.';

      case DioExceptionType.badResponse:
        final status =
            error.response?.statusCode;

        if (status == 401) {
          return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        }

        if (status == 404) {
          return 'Không tìm thấy đơn thanh toán.';
        }

        return 'Máy chủ trả về lỗi HTTP ${status ?? ''}.';

      case DioExceptionType.unknown:
        return defaultMessage;
    }
  }
}