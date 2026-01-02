import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:lifelog_clipper/features/health_connect/domain/health_connect_status.dart';

class HealthConnectController extends ChangeNotifier {
  HealthConnectController({
    Health? health,
    this.permissionTimeout = const Duration(seconds: 30),
    DeviceInfoPlugin? deviceInfo,
  })  : _health = health ?? Health(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final Health _health;
  final DeviceInfoPlugin _deviceInfo;
  final Duration permissionTimeout;

  HealthConnectStatus _status = HealthConnectStatus.checking;
  bool _isRequestingPermission = false;

  HealthConnectStatus get status => _status;
  bool get isRequestingPermission => _isRequestingPermission;

  Future<void> initialize() async {
    _status = HealthConnectStatus.checking;
    notifyListeners();

    await _health.configure();
    final sdkStatus = await _health.getHealthConnectSdkStatus();
    if (sdkStatus != HealthConnectSdkStatus.sdkAvailable) {
      final androidSdkInt = await _getAndroidSdkInt();
      _status = _mapUnavailableStatus(sdkStatus, androidSdkInt);
      notifyListeners();
      return;
    }

    await _ensureActivityRecognitionPermission();
    final permissionState = await _checkPermissions();
    if (permissionState.isGranted) {
      _status = HealthConnectStatus.available;
      notifyListeners();
      return;
    }

    _status = HealthConnectStatus.permissionRequired(
      message: 'Health Connectの権限が必要です',
      missingPermissions: permissionState.missingLabels,
    );
    notifyListeners();
  }

  Future<void> requestPermissions() async {
    if (_isRequestingPermission) {
      return;
    }
    _isRequestingPermission = true;
    notifyListeners();

    try {
      await _ensureActivityRecognitionPermission();
      final permissionState = await _checkPermissions();
      final typesToRequest = permissionState.typesToRequest;
      final granted = typesToRequest.isEmpty
          ? true
          : await _health
              .requestAuthorization(typesToRequest)
              .timeout(permissionTimeout);

      if (granted == true) {
        final refreshed = await _checkPermissions();
        if (refreshed.isGranted) {
          _status = HealthConnectStatus.available;
        } else {
          _status = HealthConnectStatus.permissionRequired(
            message: 'Health Connectの権限が必要です',
            missingPermissions: refreshed.missingLabels,
          );
        }
      } else {
        _status = HealthConnectStatus.permissionRequired(
          message: 'Health Connectの権限が必要です',
          missingPermissions: permissionState.missingLabels,
        );
      }
    } on TimeoutException {
      _status = HealthConnectStatus.permissionRequired(
        message: '権限の応答待ちがタイムアウトしました',
      );
    } catch (_) {
      _status = HealthConnectStatus.permissionRequired(
        message: '権限要求に失敗しました',
      );
    } finally {
      _isRequestingPermission = false;
      notifyListeners();
    }
  }

  Future<void> openSettings() async {
    if (_status.isUnavailable &&
        _status.reason == HealthConnectAvailabilityReason.notInstalled) {
      await _health.installHealthConnect();
      return;
    }
    await openAppSettings();
  }

  HealthConnectStatus _mapUnavailableStatus(
    HealthConnectSdkStatus? status,
    int? androidSdkInt,
  ) {
    switch (status) {
      case HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired:
        return HealthConnectStatus.unavailable(
          HealthConnectAvailabilityReason.disabled,
          message: '現在利用不可',
        );
      case HealthConnectSdkStatus.sdkUnavailable:
        if (androidSdkInt != null && androidSdkInt < 28) {
          return HealthConnectStatus.unavailable(
            HealthConnectAvailabilityReason.unsupported,
            message: '現在利用不可',
          );
        }
        return HealthConnectStatus.unavailable(
          HealthConnectAvailabilityReason.notInstalled,
          message: '現在利用不可',
        );
      case HealthConnectSdkStatus.sdkAvailable:
        return HealthConnectStatus.available;
      case null:
        return HealthConnectStatus.unavailable(
          HealthConnectAvailabilityReason.unknown,
          message: '現在利用不可',
        );
    }
  }

  Future<void> _ensureActivityRecognitionPermission() async {
    final status = await Permission.activityRecognition.status;
    if (status.isGranted) {
      return;
    }
    await Permission.activityRecognition.request();
  }

  Future<int?> _getAndroidSdkInt() async {
    if (!Platform.isAndroid) {
      return null;
    }
    try {
      final info = await _deviceInfo.androidInfo;
      return info.version.sdkInt;
    } catch (_) {
      return null;
    }
  }

  Future<_PermissionCheckResult> _checkPermissions() async {
    final stepsGranted =
        await _health.hasPermissions(const [HealthDataType.STEPS]) ?? false;
    final heartGranted =
        await _health.hasPermissions(const [HealthDataType.HEART_RATE]) ?? false;
    final sleepGranted =
        await _health.hasPermissions(const [HealthDataType.SLEEP_SESSION]) ??
            false;

    final missingLabels = <String>[
      if (!stepsGranted) '歩数',
      if (!heartGranted) '心拍数',
      if (!sleepGranted) '睡眠',
    ];

    final typesToRequest = <HealthDataType>[
      if (!stepsGranted) HealthDataType.STEPS,
      if (!heartGranted) HealthDataType.HEART_RATE,
      if (!sleepGranted) HealthDataType.SLEEP_SESSION,
    ];

    return _PermissionCheckResult(
      missingLabels: missingLabels,
      typesToRequest: typesToRequest,
    );
  }
}

class _PermissionCheckResult {
  const _PermissionCheckResult({
    required this.missingLabels,
    required this.typesToRequest,
  });

  final List<String> missingLabels;
  final List<HealthDataType> typesToRequest;

  bool get isGranted => missingLabels.isEmpty;
}
