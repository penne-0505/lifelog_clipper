import 'package:flutter/foundation.dart';
import 'package:lifelog_clipper/features/health_connect/domain/health_connect_availability.dart';

enum HealthConnectAvailabilityReason {
  notInstalled,
  disabled,
  unsupported,
  unknown,
}

enum HealthConnectStatusType {
  checking,
  available,
  unavailable,
  permissionRequired,
}

@immutable
class HealthConnectStatus {
  const HealthConnectStatus._({
    required this.type,
    this.reason,
    this.message,
    this.missingPermissions = const [],
  });

  final HealthConnectStatusType type;
  final HealthConnectAvailabilityReason? reason;
  final String? message;
  final List<String> missingPermissions;

  bool get isChecking => type == HealthConnectStatusType.checking;
  bool get isAvailable => type == HealthConnectStatusType.available;
  bool get isUnavailable => type == HealthConnectStatusType.unavailable;
  bool get isPermissionRequired =>
      type == HealthConnectStatusType.permissionRequired;

  HealthConnectAvailability toAvailability() {
    switch (type) {
      case HealthConnectStatusType.available:
        return const HealthConnectAvailability.available();
      case HealthConnectStatusType.unavailable:
        return HealthConnectAvailability.unavailable(
          _mapUnavailableReason(reason),
        );
      case HealthConnectStatusType.permissionRequired:
      case HealthConnectStatusType.checking:
        return const HealthConnectAvailability.unavailable(
          HealthConnectUnavailableReason.unknown,
        );
    }
  }

  static const checking = HealthConnectStatus._(
    type: HealthConnectStatusType.checking,
    message: 'Health Connect確認中...',
  );

  static const available = HealthConnectStatus._(
    type: HealthConnectStatusType.available,
    message: 'Health Connect利用可能',
  );

  static HealthConnectStatus unavailable(
    HealthConnectAvailabilityReason reason, {
    String? message,
  }) {
    return HealthConnectStatus._(
      type: HealthConnectStatusType.unavailable,
      reason: reason,
      message: message,
    );
  }

  static HealthConnectStatus permissionRequired({
    String? message,
    List<String> missingPermissions = const [],
  }) {
    return HealthConnectStatus._(
      type: HealthConnectStatusType.permissionRequired,
      message: message,
      missingPermissions: missingPermissions,
    );
  }

  static HealthConnectUnavailableReason _mapUnavailableReason(
    HealthConnectAvailabilityReason? reason,
  ) {
    switch (reason) {
      case HealthConnectAvailabilityReason.notInstalled:
        return HealthConnectUnavailableReason.notInstalled;
      case HealthConnectAvailabilityReason.disabled:
        return HealthConnectUnavailableReason.disabled;
      case HealthConnectAvailabilityReason.unsupported:
        return HealthConnectUnavailableReason.unsupported;
      case HealthConnectAvailabilityReason.unknown:
      case null:
        return HealthConnectUnavailableReason.unknown;
    }
  }
}
