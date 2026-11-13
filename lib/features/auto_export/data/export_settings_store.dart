import 'package:shared_preferences/shared_preferences.dart';

import 'package:lifelog_clipper/features/auto_export/domain/export_settings.dart';

class ExportSettingsStore {
  static const String _endpointUrlKey = 'auto_export.endpoint_url';
  static const String _secretKey = 'auto_export.secret';
  static const String _periodicEnabledKey = 'auto_export.periodic_enabled';

  Future<ExportSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ExportSettings(
      endpointUrl: prefs.getString(_endpointUrlKey) ?? '',
      secret: prefs.getString(_secretKey) ?? '',
      periodicEnabled: prefs.getBool(_periodicEnabledKey) ?? false,
    );
  }

  Future<void> save(ExportSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_endpointUrlKey, settings.endpointUrl);
    await prefs.setString(_secretKey, settings.secret);
    await prefs.setBool(_periodicEnabledKey, settings.periodicEnabled);
  }
}
