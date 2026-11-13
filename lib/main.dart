import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:lifelog_clipper/app/app.dart';
import 'package:lifelog_clipper/features/auto_export/application/periodic_export.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializePeriodicExport();
  runApp(const LifeLogClipperApp());
}

Future<void> _initializePeriodicExport() async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return;
  }
  try {
    await initializePeriodicExport();
  } catch (_) {
    // バックグラウンド送信の初期化に失敗してもアプリの起動は止めない。
    // 定期送信の有効化は設定画面から改めて行える。
  }
}
