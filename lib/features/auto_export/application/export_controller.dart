import 'package:flutter/foundation.dart';

import 'package:lifelog_clipper/features/auto_export/application/export_runner.dart';
import 'package:lifelog_clipper/features/auto_export/application/periodic_export.dart';
import 'package:lifelog_clipper/features/auto_export/data/export_settings_store.dart';
import 'package:lifelog_clipper/features/auto_export/data/log_exporter.dart';
import 'package:lifelog_clipper/features/auto_export/domain/export_settings.dart';

class ExportController extends ChangeNotifier {
  ExportController({ExportSettingsStore? store, ExportRunner? runner})
    : _store = store ?? ExportSettingsStore(),
      _runner = runner ?? ExportRunner();

  final ExportSettingsStore _store;
  final ExportRunner _runner;

  ExportSettings _settings = const ExportSettings();
  bool _isLoading = true;
  bool _isSending = false;
  String? _statusMessage;

  ExportSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get statusMessage => _statusMessage;

  Future<void> load() async {
    _settings = await _store.load();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> save({
    required String endpointUrl,
    required String secret,
  }) async {
    _settings = _settings.copyWith(
      endpointUrl: endpointUrl.trim(),
      secret: secret,
    );
    await _store.save(_settings);
    _statusMessage = '設定を保存しました';
    notifyListeners();
  }

  Future<void> setPeriodicEnabled(bool enabled) async {
    _settings = _settings.copyWith(periodicEnabled: enabled);
    await _store.save(_settings);
    try {
      if (enabled) {
        await enablePeriodicExport();
      } else {
        await disablePeriodicExport();
      }
      _statusMessage = enabled ? '定期送信を有効にしました' : '定期送信を無効にしました';
    } catch (error) {
      _statusMessage = '定期送信の設定に失敗しました: $error';
    }
    notifyListeners();
  }

  Future<void> sendNow() async {
    _isSending = true;
    _statusMessage = null;
    notifyListeners();
    final ExportResult result = await _runner.run(settings: _settings);
    _statusMessage = result.isSuccess
        ? result.message
        : '送信できませんでした: ${result.message}';
    _isSending = false;
    notifyListeners();
  }
}
