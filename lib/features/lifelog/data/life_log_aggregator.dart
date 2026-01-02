import 'package:health/health.dart';

import 'package:lifelog_clipper/features/health_connect/domain/health_connect_availability.dart';
import 'package:lifelog_clipper/features/lifelog/domain/jst_time.dart';
import 'package:lifelog_clipper/features/lifelog/domain/models.dart';

class LifeLogAggregator {
  LifeLogAggregator({
    Health? health,
    DateTime Function()? clock,
  })  : _health = health ?? Health(),
        _clock = clock ?? DateTime.now;

  final Health _health;
  final DateTime Function() _clock;

  Future<List<DailyLogJson>> buildRecentDailyLogs({
    int days = 7,
    HealthConnectAvailability availability =
        const HealthConnectAvailability.available(),
    DateTime? generatedAt,
  }) async {
    final DateTime generatedAtUtc = (generatedAt ?? _clock()).toUtc();
    final DateTime generatedAtJst = truncateToSeconds(toJst(generatedAtUtc));
    final List<DateWindow> windows = _buildRecentWindows(generatedAtJst, days);
    if (windows.isEmpty) {
      return const <DailyLogJson>[];
    }

    if (!availability.isAvailable) {
      return windows
          .map(
            (window) =>
                _buildUnavailableLog(window, generatedAtJst, availability),
          )
          .toList();
    }

    await _health.configure();

    final DateTime queryStartUtc = fromJst(windows.last.start);
    final DateTime queryEndUtc = fromJst(windows.first.end);

    final List<_JstDataPoint> dataPoints;
    try {
      final rawPoints = await _health.getHealthDataFromTypes(
        types: _requiredTypes,
        startTime: queryStartUtc,
        endTime: queryEndUtc,
      );
      dataPoints = rawPoints.map(_JstDataPoint.from).toList();
    } catch (_) {
      return windows
          .map((window) =>
              _buildNullDataLog(window, generatedAtJst, availability))
          .toList();
    }

    final Map<HealthDataType, List<_JstDataPoint>> pointsByType =
        <HealthDataType, List<_JstDataPoint>>{};
    for (final point in dataPoints) {
      pointsByType.putIfAbsent(point.type, () => []).add(point);
    }

    final List<_JstDataPoint> stepPoints =
        pointsByType[HealthDataType.STEPS] ?? const [];
    final List<_JstDataPoint> heartPoints =
        pointsByType[HealthDataType.HEART_RATE] ?? const [];
    final List<_JstDataPoint> sessionPoints =
        pointsByType[HealthDataType.SLEEP_SESSION] ?? const [];
    final List<_JstDataPoint> stagePoints = _collectStagePoints(pointsByType);

    return windows
        .map(
          (window) => _buildAvailableLog(
            window: window,
            generatedAt: generatedAtJst,
            availability: availability,
            stepPoints: stepPoints,
            heartPoints: heartPoints,
            sessionPoints: sessionPoints,
            stagePoints: stagePoints,
          ),
        )
        .toList();
  }

  DailyLogJson _buildUnavailableLog(
    DateWindow window,
    DateTime generatedAt,
    HealthConnectAvailability availability,
  ) {
    return DailyLogJson(
      schemaVersion: _schemaVersion,
      generatedAt: generatedAt,
      window: window,
      availability: availability,
      steps: const StepsSummary(total: null),
      heartRate: const HeartRateSummary(
        minBpm: null,
        avgBpmTimeWeighted: null,
        maxBpm: null,
        samplesCount: null,
      ),
      sleepSummary: _nullSleepSummary(),
      sleepSessions: null,
    );
  }

  DailyLogJson _buildNullDataLog(
    DateWindow window,
    DateTime generatedAt,
    HealthConnectAvailability availability,
  ) {
    return DailyLogJson(
      schemaVersion: _schemaVersion,
      generatedAt: generatedAt,
      window: window,
      availability: availability,
      steps: const StepsSummary(total: null),
      heartRate: const HeartRateSummary(
        minBpm: null,
        avgBpmTimeWeighted: null,
        maxBpm: null,
        samplesCount: null,
      ),
      sleepSummary: _nullSleepSummary(),
      sleepSessions: null,
    );
  }

  DailyLogJson _buildAvailableLog({
    required DateWindow window,
    required DateTime generatedAt,
    required HealthConnectAvailability availability,
    required List<_JstDataPoint> stepPoints,
    required List<_JstDataPoint> heartPoints,
    required List<_JstDataPoint> sessionPoints,
    required List<_JstDataPoint> stagePoints,
  }) {
    final StepsSummary steps = _aggregateSteps(stepPoints, window);
    final HeartRateSummary heartRate = _aggregateHeartRate(heartPoints, window);
    final _SleepAggregationResult sleepAggregation = _aggregateSleep(
      sessionPoints,
      stagePoints,
      window,
    );

    return DailyLogJson(
      schemaVersion: _schemaVersion,
      generatedAt: generatedAt,
      window: window,
      availability: availability,
      steps: steps,
      heartRate: heartRate,
      sleepSummary: sleepAggregation.summary,
      sleepSessions: sleepAggregation.sessions,
    );
  }
}

class _JstDataPoint {
  _JstDataPoint({
    required this.point,
    required this.start,
    required this.end,
  });

  final HealthDataPoint point;
  final DateTime start;
  final DateTime end;

  HealthDataType get type => point.type;

  static _JstDataPoint from(HealthDataPoint point) {
    return _JstDataPoint(
      point: point,
      start: toJst(point.dateFrom),
      end: toJst(point.dateTo),
    );
  }
}

class _SleepAggregationResult {
  const _SleepAggregationResult({
    required this.summary,
    required this.sessions,
  });

  final SleepSummary summary;
  final List<SleepSession> sessions;
}

class _StageInterval {
  const _StageInterval({
    required this.start,
    required this.end,
    required this.stage,
  });

  final DateTime start;
  final DateTime end;
  final String stage;
}

const int _schemaVersion = 1;

const List<HealthDataType> _requiredTypes = <HealthDataType>[
  HealthDataType.STEPS,
  HealthDataType.HEART_RATE,
  HealthDataType.SLEEP_SESSION,
  HealthDataType.SLEEP_LIGHT,
  HealthDataType.SLEEP_DEEP,
  HealthDataType.SLEEP_REM,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_OUT_OF_BED,
  HealthDataType.SLEEP_UNKNOWN,
];

List<DateWindow> _buildRecentWindows(DateTime generatedAtJst, int days) {
  final DateTime todayStart =
      DateTime.utc(generatedAtJst.year, generatedAtJst.month, generatedAtJst.day);

  return List<DateWindow>.generate(days, (index) {
    final DateTime start = todayStart.subtract(Duration(days: index));
    final DateTime end = index == 0
        ? generatedAtJst
        : start.add(const Duration(days: 1));
    return DateWindow(start: start, end: end);
  });
}

StepsSummary _aggregateSteps(List<_JstDataPoint> points, DateWindow window) {
  double total = 0;
  bool hasValue = false;

  for (final point in points) {
    final DateTime start = point.start;
    final DateTime end = point.end;
    final Duration overlap =
        _overlapDuration(start, end, window.start, window.end);
    if (overlap == Duration.zero) {
      continue;
    }

    final Duration totalDuration = end.difference(start);
    if (totalDuration <= Duration.zero) {
      continue;
    }

    final num? value = _numericValue(point.point);
    if (value == null) {
      continue;
    }

    final double ratio = overlap.inMilliseconds / totalDuration.inMilliseconds;
    total += value * ratio;
    hasValue = true;
  }

  final int totalSteps = hasValue ? total.round() : 0;
  return StepsSummary(total: totalSteps);
}

HeartRateSummary _aggregateHeartRate(
  List<_JstDataPoint> points,
  DateWindow window,
) {
  final List<_SamplePoint> samples = [];
  for (final point in points) {
    final num? value = _numericValue(point.point);
    if (value == null) {
      continue;
    }
    final DateTime time = point.start;
    if (time.isBefore(window.start) || !time.isBefore(window.end)) {
      continue;
    }
    samples.add(_SamplePoint(time: time, value: value.toDouble()));
  }

  if (samples.isEmpty) {
    return const HeartRateSummary(
      minBpm: null,
      avgBpmTimeWeighted: null,
      maxBpm: null,
      samplesCount: null,
    );
  }

  samples.sort((a, b) => a.time.compareTo(b.time));

  double weightedSum = 0;
  double totalWeightSeconds = 0;
  double totalValue = 0;
  double minValue = samples.first.value;
  double maxValue = samples.first.value;

  for (var i = 0; i < samples.length; i++) {
    final current = samples[i];
    totalValue += current.value;
    if (current.value < minValue) {
      minValue = current.value;
    }
    if (current.value > maxValue) {
      maxValue = current.value;
    }

    final DateTime start = current.time;
    final DateTime end = (i + 1 < samples.length)
        ? samples[i + 1].time
        : window.end;
    final DateTime clippedEnd = end.isBefore(window.end) ? end : window.end;
    if (!clippedEnd.isAfter(start)) {
      continue;
    }
    final double seconds =
        clippedEnd.difference(start).inMilliseconds / 1000.0;
    weightedSum += current.value * seconds;
    totalWeightSeconds += seconds;
  }

  final double avg = totalWeightSeconds > 0
      ? weightedSum / totalWeightSeconds
      : totalValue / samples.length;

  final double avgRounded = double.parse(avg.toStringAsFixed(1));

  return HeartRateSummary(
    minBpm: minValue.round(),
    avgBpmTimeWeighted: avgRounded,
    maxBpm: maxValue.round(),
    samplesCount: samples.length,
  );
}

_SleepAggregationResult _aggregateSleep(
  List<_JstDataPoint> sessionPoints,
  List<_JstDataPoint> stagePoints,
  DateWindow window,
) {
  final List<SleepSession> sessions = [];

  for (final point in sessionPoints) {
    if (!isSameJstDate(point.end, window.start)) {
      continue;
    }
    final DateTime clippedStart = point.start;
    final DateTime clippedEnd = point.end;
    if (!clippedEnd.isAfter(clippedStart)) {
      continue;
    }

    final List<SleepStage> stages = _extractStagesForSession(
      stagePoints,
      sessionStart: clippedStart,
      sessionEnd: clippedEnd,
    );

    sessions.add(
      SleepSession(
        start: clippedStart,
        end: clippedEnd,
        stages: stages,
      ),
    );
  }

  sessions.sort((a, b) => a.start.compareTo(b.start));

  final List<_StageInterval> stageIntervals = _extractStageIntervalsForSessions(
    stagePoints,
    sessions,
  );

  if (stageIntervals.isEmpty) {
    return _SleepAggregationResult(
      summary: _nullSleepSummary(),
      sessions: sessions,
    );
  }

  final int totalMinutes = sessions.fold<int>(
    0,
    (sum, session) => sum + session.end.difference(session.start).inMinutes,
  );

  final List<_StageInterval> merged = _applyStageOverrides(stageIntervals);
  final Map<String, int> totals = {
    for (final stage in stageOrder) stage: 0,
  };

  for (final interval in merged) {
    final int minutes = interval.end.difference(interval.start).inMinutes;
    totals[interval.stage] = (totals[interval.stage] ?? 0) + minutes;
  }

  final Map<String, int?> byStageMinutes = {
    for (final stage in stageOrder) stage: totals[stage],
  };

  return _SleepAggregationResult(
    summary: SleepSummary(
      totalMinutesSessionBasis: totalMinutes,
      sessionsCount: sessions.length,
      byStageMinutes: byStageMinutes,
    ),
    sessions: sessions,
  );
}

List<SleepStage> _extractStagesForSession(
  List<_JstDataPoint> stagePoints, {
  required DateTime sessionStart,
  required DateTime sessionEnd,
}) {
  final List<SleepStage> stages = [];

  for (final point in stagePoints) {
    if (!_overlaps(point.start, point.end, sessionStart, sessionEnd)) {
      continue;
    }
    final DateTime start = _maxDate(point.start, sessionStart);
    final DateTime end = _minDate(point.end, sessionEnd);
    if (!end.isAfter(start)) {
      continue;
    }
    stages.add(
      SleepStage(
        start: start,
        end: end,
        stage: _mapStage(point.type),
      ),
    );
  }

  stages.sort((a, b) => a.start.compareTo(b.start));
  return stages;
}

List<_StageInterval> _extractStageIntervalsForSessions(
  List<_JstDataPoint> stagePoints,
  List<SleepSession> sessions,
) {
  final List<_StageInterval> intervals = [];

  for (final session in sessions) {
    for (final point in stagePoints) {
      if (!_overlaps(point.start, point.end, session.start, session.end)) {
        continue;
      }
      final DateTime start = _maxDate(point.start, session.start);
      final DateTime end = _minDate(point.end, session.end);
      if (!end.isAfter(start)) {
        continue;
      }
      intervals.add(
        _StageInterval(
          start: start,
          end: end,
          stage: _mapStage(point.type),
        ),
      );
    }
  }

  intervals.sort((a, b) {
    final int primary = a.start.compareTo(b.start);
    if (primary != 0) {
      return primary;
    }
    return a.end.compareTo(b.end);
  });

  return intervals;
}

List<_StageInterval> _applyStageOverrides(
  List<_StageInterval> intervals,
) {
  final List<_StageInterval> segments = [];

  for (final interval in intervals) {
    final List<_StageInterval> updated = [];

    for (final segment in segments) {
      if (!_overlaps(segment.start, segment.end, interval.start, interval.end)) {
        updated.add(segment);
        continue;
      }

      if (segment.start.isBefore(interval.start)) {
        updated.add(
          _StageInterval(
            start: segment.start,
            end: interval.start,
            stage: segment.stage,
          ),
        );
      }

      if (segment.end.isAfter(interval.end)) {
        updated.add(
          _StageInterval(
            start: interval.end,
            end: segment.end,
            stage: segment.stage,
          ),
        );
      }
    }

    updated.add(interval);
    updated.sort((a, b) => a.start.compareTo(b.start));
    segments
      ..clear()
      ..addAll(updated);
  }

  return segments;
}

SleepSummary _nullSleepSummary() {
  return SleepSummary(
    totalMinutesSessionBasis: null,
    sessionsCount: null,
    byStageMinutes: {
      for (final stage in stageOrder) stage: null,
    },
  );
}

List<_JstDataPoint> _collectStagePoints(
  Map<HealthDataType, List<_JstDataPoint>> pointsByType,
) {
  final List<_JstDataPoint> result = [];
  for (final type in _stageTypes) {
    final points = pointsByType[type];
    if (points != null && points.isNotEmpty) {
      result.addAll(points);
    }
  }
  return result;
}

const List<HealthDataType> _stageTypes = <HealthDataType>[
  HealthDataType.SLEEP_LIGHT,
  HealthDataType.SLEEP_DEEP,
  HealthDataType.SLEEP_REM,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_OUT_OF_BED,
  HealthDataType.SLEEP_UNKNOWN,
];

String _mapStage(HealthDataType type) {
  switch (type) {
    case HealthDataType.SLEEP_LIGHT:
      return 'LIGHT';
    case HealthDataType.SLEEP_DEEP:
      return 'DEEP';
    case HealthDataType.SLEEP_REM:
      return 'REM';
    case HealthDataType.SLEEP_AWAKE:
      return 'AWAKE';
    case HealthDataType.SLEEP_OUT_OF_BED:
      return 'OUT_OF_BED';
    case HealthDataType.SLEEP_ASLEEP:
      return 'SLEEPING';
    case HealthDataType.SLEEP_UNKNOWN:
      return 'UNKNOWN';
    default:
      return 'UNKNOWN';
  }
}

num? _numericValue(HealthDataPoint point) {
  final HealthValue value = point.value;
  if (value is NumericHealthValue) {
    return value.numericValue;
  }
  return null;
}

bool _overlaps(
  DateTime start,
  DateTime end,
  DateTime otherStart,
  DateTime otherEnd,
) {
  return start.isBefore(otherEnd) && end.isAfter(otherStart);
}

Duration _overlapDuration(
  DateTime start,
  DateTime end,
  DateTime otherStart,
  DateTime otherEnd,
) {
  if (!_overlaps(start, end, otherStart, otherEnd)) {
    return Duration.zero;
  }
  final DateTime overlapStart = _maxDate(start, otherStart);
  final DateTime overlapEnd = _minDate(end, otherEnd);
  return overlapEnd.difference(overlapStart);
}

DateTime _minDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

DateTime _maxDate(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

class _SamplePoint {
  const _SamplePoint({required this.time, required this.value});

  final DateTime time;
  final double value;
}
