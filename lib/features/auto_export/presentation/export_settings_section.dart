import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lifelog_clipper/features/auto_export/application/export_controller.dart';

class ExportSettingsSection extends StatefulWidget {
  const ExportSettingsSection({super.key});

  @override
  State<ExportSettingsSection> createState() => _ExportSettingsSectionState();
}

class _ExportSettingsSectionState extends State<ExportSettingsSection> {
  late final ExportController _controller;
  late final TextEditingController _urlTextController;
  late final TextEditingController _secretTextController;
  bool _fieldsInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = ExportController();
    _urlTextController = TextEditingController();
    _secretTextController = TextEditingController();
    _controller.addListener(_onControllerChanged);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _urlTextController.dispose();
    _secretTextController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!_fieldsInitialized && !_controller.isLoading) {
      _urlTextController.text = _controller.settings.endpointUrl;
      _secretTextController.text = _controller.settings.secret;
      _fieldsInitialized = true;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveFields() {
    return _controller.save(
      endpointUrl: _urlTextController.text,
      secret: _secretTextController.text,
    );
  }

  Future<void> _onSavePressed() async {
    await _saveFields();
  }

  Future<void> _onSendNowPressed() async {
    await _saveFields();
    await _controller.sendNow();
  }

  Future<void> _onPeriodicChanged(bool enabled) async {
    await _saveFields();
    await _controller.setPeriodicEnabled(enabled);
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = _controller.isLoading || _controller.isSending;
    return Material(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('自動送信 (HTTP)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            TextField(
              controller: _urlTextController,
              enabled: !busy,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: '送信先URL',
                hintText: 'https://example.com/ingest',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _secretTextController,
              enabled: !busy,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '共有シークレット (x-ingest-secret)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: busy ? null : _onSavePressed,
                  child: const Text('設定を保存'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: busy ? null : _onSendNowPressed,
                  icon: _controller.isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('今すぐ送信'),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('定期送信'),
              subtitle: const Text('15分間隔で直近のログを自動送信します'),
              value: _controller.settings.periodicEnabled,
              onChanged: busy ? null : _onPeriodicChanged,
            ),
            if (_controller.statusMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _controller.statusMessage!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
