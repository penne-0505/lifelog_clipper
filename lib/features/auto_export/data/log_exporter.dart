import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:lifelog_clipper/features/lifelog/domain/models.dart';

class ExportResult {
  const ExportResult._({
    required this.isSuccess,
    required this.isSkipped,
    required this.message,
    this.statusCode,
  });

  factory ExportResult.success(int statusCode) {
    return ExportResult._(
      isSuccess: true,
      isSkipped: false,
      message: '送信しました (HTTP $statusCode)',
      statusCode: statusCode,
    );
  }

  factory ExportResult.failure(String message, {int? statusCode}) {
    return ExportResult._(
      isSuccess: false,
      isSkipped: false,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ExportResult.skipped(String message) {
    return ExportResult._(isSuccess: false, isSkipped: true, message: message);
  }

  final bool isSuccess;

  /// 前提条件を満たさず送信自体を行わなかった場合に true。
  final bool isSkipped;

  final String message;
  final int? statusCode;
}

class LogExporter {
  LogExporter({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String payloadAppName = 'lifelog_clipper';
  static const int payloadVersion = 1;

  Map<String, Object?> buildPayload(List<DailyLogJson> logs) {
    return <String, Object?>{
      'app': payloadAppName,
      'payload_version': payloadVersion,
      'logs': logs.map((log) => log.toJson()).toList(),
    };
  }

  Future<ExportResult> send({
    required Uri endpoint,
    required String secret,
    required List<DailyLogJson> logs,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final response = await _client
          .post(
            endpoint,
            headers: <String, String>{
              'Content-Type': 'application/json',
              if (secret.isNotEmpty) 'x-ingest-secret': secret,
            },
            body: jsonEncode(buildPayload(logs)),
          )
          .timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ExportResult.success(response.statusCode);
      }
      return ExportResult.failure(
        'サーバがエラーを返しました (HTTP ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (error) {
      return ExportResult.failure('送信に失敗しました: $error');
    }
  }
}
