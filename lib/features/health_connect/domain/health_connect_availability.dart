enum HealthConnectAvailabilityState { available, unavailable }

enum HealthConnectUnavailableReason {
  notInstalled,
  disabled,
  unsupported,
  unknown,
}

extension HealthConnectUnavailableReasonJson on HealthConnectUnavailableReason {
  String get jsonValue {
    switch (this) {
      case HealthConnectUnavailableReason.notInstalled:
        return 'not_installed';
      case HealthConnectUnavailableReason.disabled:
        return 'disabled';
      case HealthConnectUnavailableReason.unsupported:
        return 'unsupported';
      case HealthConnectUnavailableReason.unknown:
        return 'unknown';
    }
  }
}

class HealthConnectAvailability {
  const HealthConnectAvailability.available()
      : state = HealthConnectAvailabilityState.available,
        reason = null;

  const HealthConnectAvailability.unavailable([
    this.reason,
  ]) : state = HealthConnectAvailabilityState.unavailable;

  final HealthConnectAvailabilityState state;
  final HealthConnectUnavailableReason? reason;

  bool get isAvailable => state == HealthConnectAvailabilityState.available;

  HealthConnectUnavailableReason get resolvedReason =>
      reason ?? HealthConnectUnavailableReason.unknown;
}
