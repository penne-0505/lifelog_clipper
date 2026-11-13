import 'package:health/health.dart';

import 'package:lifelog_clipper/features/auto_export/data/export_settings_store.dart';
import 'package:lifelog_clipper/features/auto_export/data/log_exporter.dart';
import 'package:lifelog_clipper/features/auto_export/domain/export_settings.dart';
import 'package:lifelog_clipper/features/health_connect/domain/health_connect_availability.dart';
import 'package:lifelog_clipper/features/lifelog/data/life_log_aggregator.dart';

/// 集計 → 送信の一連の処理。手動送信（UI）と定期送信（バックグラウンド）の
/// 双方から利用する。
///
/// 送信対象は直近48時間を含む直近3日分
/// （LifeLogAggregator の日次ウィンドウは JST の日境界で区切られるため、
/// 48時間を完全に覆うには3日分が必要）。
class ExportRunner {
  ExportRunner({
    LifeLogAggregator? aggregator,
    LogExporter? exporter,
    ExportSettingsStore? store,
    Health? health,
  }) : _aggregator = aggregator ?? LifeLogAggregator(),
       _exporter = exporter ?? LogExporter(),
       _store = store ?? ExportSettingsStore(),
       _health = health ?? Health();

  final LifeLogAggregator _aggregator;
  final LogExporter _exporter;
  final ExportSettingsStore _store;
  final Health _health;

  static const int exportDays = 3;

  static const List<HealthDataType> _requiredPermissionTypes = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_SESSION,
  ];

  Future<ExportResult> run({ExportSettings? settings}) async {
    final ExportSettings resolved = settings ?? await _store.load();

    if (!resolved.isConfigured) {
      return ExportResult.skipped('送信先URLが未設定です');
    }
    final Uri? endpoint = Uri.tryParse(resolved.endpointUrl.trim());
    if (endpoint == null ||
        (endpoint.scheme != 'http' && endpoint.scheme != 'https') ||
        endpoint.host.isEmpty) {
      return ExportResult.failure('送信先URLの形式が不正です');
    }

    await _health.configure();
    final HealthConnectSdkStatus? sdkStatus = await _health
        .getHealthConnectSdkStatus();
    if (sdkStatus != HealthConnectSdkStatus.sdkAvailable) {
      return ExportResult.skipped('Health Connectが利用できません');
    }

    final bool granted =
        await _health.hasPermissions(_requiredPermissionTypes) ?? false;
    if (!granted) {
      return ExportResult.skipped('Health Connectの権限が不足しています');
    }

    final logs = await _aggregator.buildRecentDailyLogs(
      days: exportDays,
      availability: const HealthConnectAvailability.available(),
    );

    return _exporter.send(
      endpoint: endpoint,
      secret: resolved.secret,
      logs: logs,
    );
  }
}
