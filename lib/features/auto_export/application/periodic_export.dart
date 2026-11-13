import 'dart:ui';

import 'package:workmanager/workmanager.dart';

import 'package:lifelog_clipper/features/auto_export/application/export_runner.dart';
import 'package:lifelog_clipper/features/auto_export/data/log_exporter.dart';

const String periodicExportUniqueName = 'lifelog_clipper.periodic_export';
const String periodicExportTaskName = 'exportRecentLogs';

/// WorkManager の定期実行間隔。Android の WorkManager の下限が15分のため、
/// これより短い間隔は指定できない。
const Duration periodicExportInterval = Duration(minutes: 15);

@pragma('vm:entry-point')
void exportCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != periodicExportTaskName) {
      return true;
    }
    try {
      DartPluginRegistrant.ensureInitialized();
      final ExportResult result = await ExportRunner().run();
      // 前提条件を満たさない（未設定・権限不足など）場合はリトライしても
      // 改善しないため成功扱いで打ち切る。送信失敗時のみ false を返し、
      // WorkManager のバックオフに委ねる。
      return result.isSuccess || result.isSkipped;
    } catch (_) {
      return false;
    }
  });
}

Future<void> initializePeriodicExport() {
  return Workmanager().initialize(exportCallbackDispatcher);
}

Future<void> enablePeriodicExport() {
  return Workmanager().registerPeriodicTask(
    periodicExportUniqueName,
    periodicExportTaskName,
    frequency: periodicExportInterval,
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: const Duration(minutes: 10),
  );
}

Future<void> disablePeriodicExport() {
  return Workmanager().cancelByUniqueName(periodicExportUniqueName);
}
