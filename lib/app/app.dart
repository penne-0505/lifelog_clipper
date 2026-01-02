import 'package:flutter/material.dart';

import 'package:lifelog_clipper/features/health_connect/presentation/health_connect_gate_page.dart';

class LifeLogClipperApp extends StatelessWidget {
  const LifeLogClipperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeLog Clipper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
      ),
      home: const HealthConnectGatePage(),
    );
  }
}
