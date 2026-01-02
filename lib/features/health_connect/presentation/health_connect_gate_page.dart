import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lifelog_clipper/features/health_connect/application/health_connect_controller.dart';
import 'package:lifelog_clipper/features/health_connect/domain/health_connect_availability.dart';
import 'package:lifelog_clipper/features/health_connect/domain/health_connect_status.dart';
import 'package:lifelog_clipper/features/lifelog/data/life_log_aggregator.dart';
import 'package:lifelog_clipper/features/lifelog/domain/models.dart';

class HealthConnectGatePage extends StatefulWidget {
  const HealthConnectGatePage({super.key});

  @override
  State<HealthConnectGatePage> createState() => _HealthConnectGatePageState();
}

class _HealthConnectGatePageState extends State<HealthConnectGatePage>
    with SingleTickerProviderStateMixin {
  late final HealthConnectController _controller;
  late final LifeLogAggregator _aggregator;
  late final AnimationController _copyNotificationController;
  late final Animation<double> _copyNotificationFade;
  late final Animation<Offset> _copyNotificationSlide;
  bool _isLoadingLogs = false;
  bool _hasLoadedOnce = false;
  String? _loadErrorMessage;
  String? _copyingDateKey;
  List<DailyLogJson> _logs = const [];
  late final ValueNotifier<_CopyTargetsSelection> _copyTargets;
  OverlayEntry? _copyNotificationEntry;
  Timer? _copyNotificationTimer;

  @override
  void initState() {
    super.initState();
    _controller = HealthConnectController();
    _aggregator = LifeLogAggregator();
    _copyNotificationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    final curve = CurvedAnimation(
      parent: _copyNotificationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _copyNotificationFade = Tween<double>(begin: 0, end: 1).animate(curve);
    _copyNotificationSlide = Tween<Offset>(
      begin: const Offset(0, -0.12),
      end: Offset.zero,
    ).animate(curve);
    _copyTargets = ValueNotifier(const _CopyTargetsSelection());
    _controller.addListener(_onStatusChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _copyNotificationTimer?.cancel();
    _copyNotificationEntry?.remove();
    _copyNotificationController.dispose();
    _copyTargets.dispose();
    _controller.removeListener(_onStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStatusChanged() {
    final status = _controller.status;
    if (status.isAvailable && !_hasLoadedOnce && !_isLoadingLogs) {
      unawaited(_loadLogs());
    }
    if (!status.isAvailable) {
      _hasLoadedOnce = false;
      _loadErrorMessage = null;
      _logs = const [];
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _controller.status;

    return Scaffold(
      appBar: AppBar(title: const Text('LifeLog Clipper')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                children: [
                  Text(
                    status.message ?? '状態を確認中です',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (status.isChecking)
                    const LinearProgressIndicator()
                  else if (status.isUnavailable) ...[
                    Text(
                      _unavailableReasonLabel(status.reason),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _controller.isRequestingPermission
                          ? null
                          : _onRetry,
                      child: const Text('再試行'),
                    ),
                  ] else if (status.isPermissionRequired) ...[
                    FilledButton(
                      onPressed: _controller.isRequestingPermission
                          ? null
                          : _onRetry,
                      child: _controller.isRequestingPermission
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('権限を許可'),
                    ),
                    if (status.missingPermissions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        '不足: ${status.missingPermissions.join(' / ')}',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _onOpenSettings,
                      child: const Text('設定を開く'),
                    ),
                  ] else if (status.isAvailable) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Health Connectの準備が整いました',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isLoadingLogs ? null : _loadLogs,
                      icon: const Icon(Icons.refresh),
                      label: const Text('再読み込み'),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: RepaintBoundary(child: _buildCopyTargetsSection()),
            ),
            const Divider(height: 1),
            Expanded(child: RepaintBoundary(child: _buildLogList(status))),
          ],
        ),
      ),
    );
  }

  String _unavailableReasonLabel(HealthConnectAvailabilityReason? reason) {
    switch (reason) {
      case HealthConnectAvailabilityReason.notInstalled:
        return 'reason: not_installed';
      case HealthConnectAvailabilityReason.disabled:
        return 'reason: disabled';
      case HealthConnectAvailabilityReason.unsupported:
        return 'reason: unsupported';
      case HealthConnectAvailabilityReason.unknown:
        return 'reason: unknown';
      case null:
        return 'reason: unknown';
    }
  }

  Widget _buildCopyTargetsSection() {
    return CopyTargetsSection(selectionListenable: _copyTargets);
  }

  Future<void> _onRetry() async {
    if (_controller.status.isUnavailable) {
      await _controller.initialize();
      return;
    }
    await _controller.requestPermissions();
  }

  Future<void> _onOpenSettings() async {
    await _controller.openSettings();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoadingLogs = true;
      _loadErrorMessage = null;
    });
    try {
      final logs = await _aggregator.buildRecentDailyLogs(
        days: 7,
        availability: _controller.status.toAvailability(),
      );
      _hasLoadedOnce = true;
      if (mounted) {
        setState(() {
          _logs = logs;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadErrorMessage = 'データの取得に失敗しました';
          _logs = const [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLogs = false;
        });
      }
    }
  }

  Widget _buildLogList(HealthConnectStatus status) {
    if (!status.isAvailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Health Connectが利用できる状態になると、直近7日分のリストが表示されます。',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_isLoadingLogs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _loadErrorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadLogs, child: const Text('再読み込み')),
            ],
          ),
        ),
      );
    }

    if (_logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'データがまだありません。再読み込みをお試しください。',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = _logs[index];
        final dateKey = _dateKey(log.window.start);
        final isCopying = _copyingDateKey == dateKey;
        return Card(
          elevation: 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateLabel(log.window.start),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildAvailabilityChip(log.availability),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: isCopying ? null : () => _copyLog(log),
                      icon: isCopying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.copy),
                      label: Text(isCopying ? '処理中' : 'コピー'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailabilityChip(HealthConnectAvailability availability) {
    final isAvailable = availability.isAvailable;
    final label = isAvailable ? '取得可能' : '取得不可';
    final color = isAvailable ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showCopyNotification({required bool success}) {
    final backgroundColor = success
        ? const Color(0xFFE9F7EF)
        : const Color(0xFFFDECEA);
    final accentColor = success
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final textColor = success
        ? const Color(0xFF0F3B2F)
        : const Color(0xFF4A1C1C);
    final icon = success ? Icons.check_circle : Icons.error_outline;
    final message = success ? 'コピーが完了しました' : 'コピーに失敗しました';

    _copyNotificationTimer?.cancel();
    _copyNotificationEntry?.remove();
    _copyNotificationEntry = null;

    final overlay = Overlay.of(context);
    if (overlay == null) {
      return;
    }

    _copyNotificationEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: _copyNotificationFade,
                child: SlideTransition(
                  position: _copyNotificationSlide,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: accentColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_copyNotificationEntry!);

    _copyNotificationController.forward(from: 0);
    _copyNotificationTimer = Timer(const Duration(seconds: 2), () {
      _hideCopyNotification();
    });
  }

  Future<void> _hideCopyNotification() async {
    if (_copyNotificationEntry == null) {
      return;
    }
    try {
      await _copyNotificationController.reverse();
    } finally {
      _copyNotificationEntry?.remove();
      _copyNotificationEntry = null;
    }
  }

  Future<void> _copyLog(DailyLogJson log) async {
    final dateKey = _dateKey(log.window.start);
    setState(() {
      _copyingDateKey = dateKey;
    });

    try {
      final refreshed = await _aggregator.buildRecentDailyLogs(
        days: 7,
        availability: _controller.status.toAvailability(),
        generatedAt: DateTime.now(),
      );
      final DailyLogJson target = refreshed.firstWhere(
        (entry) => _dateKey(entry.window.start) == dateKey,
        orElse: () => log,
      );
      final selection = _copyTargets.value;
      await Clipboard.setData(
        ClipboardData(
          text: target.toPrettyJson(
            includeSteps: selection.includeSteps,
            includeHeartRate: selection.includeHeartRate,
            includeSleepSummary: selection.includeSleepSummary,
            includeSleepSessions: selection.includeSleepSessions,
          ),
        ),
      );
      if (mounted) {
        _showCopyNotification(success: true);
      }
    } catch (_) {
      if (mounted) {
        _showCopyNotification(success: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _copyingDateKey = null;
        });
      }
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${_pad2(date.month)}-${_pad2(date.day)}';
  }

  String _formatDateLabel(DateTime date) {
    return _dateKey(date);
  }

  String _pad2(int value) => value.toString().padLeft(2, '0');
}

class _CopyTargetsSelection {
  const _CopyTargetsSelection({
    this.includeSteps = true,
    this.includeHeartRate = true,
    this.includeSleepSummary = true,
    this.includeSleepSessions = true,
  });

  final bool includeSteps;
  final bool includeHeartRate;
  final bool includeSleepSummary;
  final bool includeSleepSessions;

  _CopyTargetsSelection copyWith({
    bool? includeSteps,
    bool? includeHeartRate,
    bool? includeSleepSummary,
    bool? includeSleepSessions,
  }) {
    return _CopyTargetsSelection(
      includeSteps: includeSteps ?? this.includeSteps,
      includeHeartRate: includeHeartRate ?? this.includeHeartRate,
      includeSleepSummary: includeSleepSummary ?? this.includeSleepSummary,
      includeSleepSessions: includeSleepSessions ?? this.includeSleepSessions,
    );
  }
}

class CopyTargetsSection extends StatefulWidget {
  const CopyTargetsSection({super.key, required this.selectionListenable});

  final ValueNotifier<_CopyTargetsSelection> selectionListenable;

  @override
  State<CopyTargetsSection> createState() => _CopyTargetsSectionState();
}

class _CopyTargetsSectionState extends State<CopyTargetsSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 160),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _expandAnimation = curve;
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _updateSelection(_CopyTargetsSelection selection) {
    widget.selectionListenable.value = selection;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: Theme.of(
          context,
        ).colorScheme.surfaceVariant.withValues(alpha: 0.4),
        child: Column(
          children: [
            InkWell(
              onTap: _toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'コピー対象',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: const Icon(Icons.expand_more),
                    ),
                  ],
                ),
              ),
            ),
            ClipRect(
              child: SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1,
                child: ValueListenableBuilder<_CopyTargetsSelection>(
                  valueListenable: widget.selectionListenable,
                  builder: (context, selection, _) {
                    return Column(
                      children: [
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          title: const Text('歩数'),
                          trailing: Switch.adaptive(
                            value: selection.includeSteps,
                            onChanged: (value) {
                              _updateSelection(
                                selection.copyWith(includeSteps: value),
                              );
                            },
                          ),
                          onTap: () {
                            _updateSelection(
                              selection.copyWith(
                                includeSteps: !selection.includeSteps,
                              ),
                            );
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          title: const Text('心拍'),
                          trailing: Switch.adaptive(
                            value: selection.includeHeartRate,
                            onChanged: (value) {
                              _updateSelection(
                                selection.copyWith(includeHeartRate: value),
                              );
                            },
                          ),
                          onTap: () {
                            _updateSelection(
                              selection.copyWith(
                                includeHeartRate: !selection.includeHeartRate,
                              ),
                            );
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          title: const Text('睡眠サマリ'),
                          trailing: Switch.adaptive(
                            value: selection.includeSleepSummary,
                            onChanged: (value) {
                              _updateSelection(
                                selection.copyWith(includeSleepSummary: value),
                              );
                            },
                          ),
                          onTap: () {
                            _updateSelection(
                              selection.copyWith(
                                includeSleepSummary:
                                    !selection.includeSleepSummary,
                              ),
                            );
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          title: const Text('睡眠セッション'),
                          trailing: Switch.adaptive(
                            value: selection.includeSleepSessions,
                            onChanged: (value) {
                              _updateSelection(
                                selection.copyWith(includeSleepSessions: value),
                              );
                            },
                          ),
                          onTap: () {
                            _updateSelection(
                              selection.copyWith(
                                includeSleepSessions:
                                    !selection.includeSleepSessions,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
