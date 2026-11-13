class ExportSettings {
  const ExportSettings({
    this.endpointUrl = '',
    this.secret = '',
    this.periodicEnabled = false,
  });

  final String endpointUrl;
  final String secret;
  final bool periodicEnabled;

  bool get isConfigured => endpointUrl.trim().isNotEmpty;

  ExportSettings copyWith({
    String? endpointUrl,
    String? secret,
    bool? periodicEnabled,
  }) {
    return ExportSettings(
      endpointUrl: endpointUrl ?? this.endpointUrl,
      secret: secret ?? this.secret,
      periodicEnabled: periodicEnabled ?? this.periodicEnabled,
    );
  }
}
