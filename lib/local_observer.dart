import 'package:flutter/material.dart';

class LocalObserver extends WidgetsBindingObserver {
  LocalObserver({
    required this.temporaryStopCallback,
    required this.stopCallback,
    this.startCallback,
  });
  final VoidCallback temporaryStopCallback;
  final VoidCallback stopCallback;
  final VoidCallback? startCallback;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        temporaryStopCallback.call();
        break;
      case AppLifecycleState.detached:
        stopCallback.call();
        break;
      case AppLifecycleState.resumed:
        startCallback?.call();
        break;
    }
  }
}
