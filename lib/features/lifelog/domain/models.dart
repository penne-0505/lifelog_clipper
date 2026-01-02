import 'dart:collection';
import 'dart:convert';

import 'package:lifelog_clipper/features/health_connect/domain/health_connect_availability.dart';
import 'package:lifelog_clipper/features/lifelog/domain/jst_time.dart';

class DateWindow {
  const DateWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class StepsSummary {
  const StepsSummary({required this.total});

  final int? total;

  Map<String, Object?> toJson() {
    return LinkedHashMap.of({
      'total': total,
    });
  }
}

class HeartRateSummary {
  const HeartRateSummary({
    required this.minBpm,
    required this.avgBpmTimeWeighted,
    required this.maxBpm,
    required this.samplesCount,
  });

  final int? minBpm;
  final double? avgBpmTimeWeighted;
  final int? maxBpm;
  final int? samplesCount;

  Map<String, Object?> toJson() {
    return LinkedHashMap.of({
      'min_bpm': minBpm,
      'avg_bpm_time_weighted': avgBpmTimeWeighted,
      'max_bpm': maxBpm,
      'samples_count': samplesCount,
    });
  }
}

class SleepSummary {
  const SleepSummary({
    required this.totalMinutesSessionBasis,
    required this.sessionsCount,
    required this.byStageMinutes,
  });

  final int? totalMinutesSessionBasis;
  final int? sessionsCount;
  final Map<String, int?> byStageMinutes;

  Map<String, Object?> toJson() {
    return LinkedHashMap.of({
      'total_minutes_session_basis': totalMinutesSessionBasis,
      'sessions_count': sessionsCount,
      'by_stage_minutes': LinkedHashMap.of({
        for (final stage in stageOrder) stage: byStageMinutes[stage],
      }),
    });
  }
}

class SleepStage {
  const SleepStage({
    required this.start,
    required this.end,
    required this.stage,
  });

  final DateTime start;
  final DateTime end;
  final String stage;

  Map<String, Object?> toJson() {
    return LinkedHashMap.of({
      'start': formatJstDateTime(start),
      'end': formatJstDateTime(end),
      'stage': stage,
    });
  }
}

class SleepSession {
  const SleepSession({
    required this.start,
    required this.end,
    required this.stages,
  });

  final DateTime start;
  final DateTime end;
  final List<SleepStage> stages;

  Map<String, Object?> toJson() {
    return LinkedHashMap.of({
      'start': formatJstDateTime(start),
      'end': formatJstDateTime(end),
      'stages': stages.map((stage) => stage.toJson()).toList(),
    });
  }
}

class DailyLogJson {
  const DailyLogJson({
    required this.schemaVersion,
    required this.generatedAt,
    required this.window,
    required this.availability,
    required this.steps,
    required this.heartRate,
    required this.sleepSummary,
    required this.sleepSessions,
  });

  final int schemaVersion;
  final DateTime generatedAt;
  final DateWindow window;
  final HealthConnectAvailability availability;
  final StepsSummary steps;
  final HeartRateSummary heartRate;
  final SleepSummary sleepSummary;
  final List<SleepSession>? sleepSessions;

  Map<String, Object?> toJson({
    bool includeSteps = true,
    bool includeHeartRate = true,
    bool includeSleepSummary = true,
    bool includeSleepSessions = true,
  }) {
    return LinkedHashMap.of({
      'schema_version': schemaVersion,
      'generated_at': formatJstDateTime(generatedAt),
      'date': formatJstDate(window.start),
      'timezone': jstTimezone,
      'window': LinkedHashMap.of({
        'start': formatJstDateTime(window.start),
        'end': formatJstDateTime(window.end),
      }),
      'availability': LinkedHashMap.of({
        'health_connect':
            availability.isAvailable ? 'available' : 'unavailable',
        'reason': availability.isAvailable
            ? null
            : availability.resolvedReason.jsonValue,
      }),
      'steps': includeSteps ? steps.toJson() : null,
      'heart_rate': includeHeartRate ? heartRate.toJson() : null,
      'sleep_summary': includeSleepSummary ? sleepSummary.toJson() : null,
      'sleep_sessions': includeSleepSessions
          ? sleepSessions?.map((s) => s.toJson()).toList()
          : null,
    });
  }

  String toPrettyJson({
    bool includeSteps = true,
    bool includeHeartRate = true,
    bool includeSleepSummary = true,
    bool includeSleepSessions = true,
  }) {
    return const JsonEncoder.withIndent('  ').convert(
      toJson(
        includeSteps: includeSteps,
        includeHeartRate: includeHeartRate,
        includeSleepSummary: includeSleepSummary,
        includeSleepSessions: includeSleepSessions,
      ),
    );
  }
}

const List<String> stageOrder = <String>[
  'UNKNOWN',
  'AWAKE',
  'SLEEPING',
  'OUT_OF_BED',
  'LIGHT',
  'DEEP',
  'REM',
];
