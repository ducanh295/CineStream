import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class PaymentService {
  PaymentService._internal();

  static final PaymentService instance =
      PaymentService._internal();

  final Dio _dio =
      ApiClient.instance.dio;

  // ==============================================================
  // CREATE PAYMENT
  // POST /api/payments/create
  // ==============================================================

  Future<PaymentResponse> createPayment(
    String planType,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.createPayment,
        data: {
          'planType': planType,
        },
      );

      final body =
          _normalizeBody(response.data);

      if (body['success'] == false) {
        throw Exception(
          body['message']?.toString() ??
              'Không thể tạo đơn thanh toán.',
        );
      }

      final data = body['data'];

      if (data is! Map) {
        throw Exception(
          'Response thanh toán không hợp lệ.',
        );
      }

      return PaymentResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(e),
      );
    }
  }

  // ==============================================================
  // GET PAYMENT STATUS
  // GET /api/payments/status/{orderCode}
  // ==============================================================

  Future<PaymentStatusResponse>
      getPaymentStatus(
    String orderCode,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.paymentStatus}/$orderCode',
      );

      final body =
          _normalizeBody(response.data);

      if (body['success'] == false) {
        throw Exception(
          body['message']?.toString() ??
              'Không thể kiểm tra trạng thái thanh toán.',
        );
      }

      final data = body['data'];

      if (data is! Map) {
        throw Exception(
          'Response trạng thái thanh toán không hợp lệ.',
        );
      }

      return PaymentStatusResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(e),
      );
    }
  }

  // ==============================================================
  // HELPERS
  // ==============================================================

  Map<String, dynamic> _normalizeBody(
    dynamic data,
  ) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(
        data,
      );
    }

    throw Exception(
      'Response từ Backend không hợp lệ.',
    );
  }

  String _getErrorMessage(
    DioException error,
  ) {
    final statusCode =
        error.response?.statusCode;

    final responseData =
        error.response?.data;

    String message = '';

    if (responseData is Map) {
      final map =
          Map<String, dynamic>.from(
        responseData,
      );

      final value =
          map['message'] ??
          map['error'] ??
          map['title'] ??
          map['detail'];

      if (value != null) {
        message =
            value.toString();
      }
    } else if (responseData != null) {
      message =
          responseData.toString();
    }

    if (statusCode != null) {
      if (statusCode == 400) {
        return message.isNotEmpty
            ? 'Thanh toán lỗi 400: $message'
            : 'Thanh toán lỗi 400: Request không hợp lệ.';
      }

      if (statusCode == 401) {
        return message.isNotEmpty
            ? 'Thanh toán lỗi 401: $message'
            : 'Thanh toán lỗi 401: Bạn chưa đăng nhập hoặc token không hợp lệ.';
      }

      if (statusCode == 404) {
        return message.isNotEmpty
            ? 'Thanh toán lỗi 404: $message'
            : 'Thanh toán lỗi 404: Không tìm thấy đơn hàng hoặc endpoint.';
      }

      if (statusCode >= 500) {
        return message.isNotEmpty
            ? 'Thanh toán lỗi $statusCode: $message'
            : 'Backend thanh toán đang xảy ra lỗi.';
      }

      return message.isNotEmpty
          ? 'Thanh toán lỗi HTTP $statusCode: $message'
          : 'Thanh toán lỗi HTTP $statusCode.';
    }

    if (error.type ==
        DioExceptionType.connectionTimeout) {
      return 'Kết nối Backend thanh toán bị timeout.';
    }

    if (error.type ==
        DioExceptionType.sendTimeout) {
      return 'Gửi yêu cầu thanh toán bị timeout.';
    }

    if (error.type ==
        DioExceptionType.receiveTimeout) {
      return 'Backend thanh toán phản hồi quá chậm.';
    }

    if (error.type ==
        DioExceptionType.connectionError) {
      return 'Không thể kết nối tới Backend thanh toán.';
    }

    return 'Lỗi thanh toán: '
        '${error.message ?? error.toString()}';
  }
}

// ==================================================================
// PAYMENT RESPONSE
// ==================================================================

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
          json['orderCode']
                  ?.toString() ??
              '',
      amount:
          (json['amount'] as num?)
                  ?.toDouble() ??
              0,
      planDurationDays:
          (json['planDurationDays']
                      as num?)
                  ?.toInt() ??
              0,
      bankName:
          json['bankName']
                  ?.toString() ??
              '',
      accountNumber:
          json['accountNumber']
                  ?.toString() ??
              '',
      accountName:
          json['accountName']
                  ?.toString() ??
              '',
      description:
          json['description']
                  ?.toString() ??
              '',
      qrCodeUrl:
          json['qrCodeUrl']
                  ?.toString() ??
              '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(
                  json['createdAt']
                      .toString(),
                )
              : null,
    );
  }
}

// ==================================================================
// PAYMENT STATUS RESPONSE
// ==================================================================

class PaymentStatusResponse {
  final String orderCode;
  final String status;
  final bool isCompleted;
  final DateTime? completedAt;

  const PaymentStatusResponse({
    required this.orderCode,
    required this.status,
    required this.isCompleted,
    required this.completedAt,
  });

  factory PaymentStatusResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return PaymentStatusResponse(
      orderCode:
          json['orderCode']
                  ?.toString() ??
              '',
      status:
          json['status']
                  ?.toString() ??
              '',
      isCompleted:
          json['isCompleted'] ==
              true,
      completedAt:
          json['completedAt'] != null
              ? DateTime.tryParse(
                  json['completedAt']
                      .toString(),
                )
              : null,
    );
  }

  bool get isFailed {
    final normalized =
        status.toLowerCase();

    return normalized ==
            'failed' ||
        normalized ==
            'failure';
  }
}

