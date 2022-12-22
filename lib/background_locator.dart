import 'dart:async';
import 'dart:ui';

import 'package:background_locator_2/settings/android_settings.dart';
import 'package:background_locator_2/settings/ios_settings.dart';
import 'package:background_locator_2/utils/settings_util.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'local_observer.dart';
import 'callback_dispatcher.dart';
import 'keys.dart';
import 'location_dto.dart';

class BackgroundLocator {
  static const MethodChannel _channel = const MethodChannel(Keys.CHANNEL_ID);

  static Future<void> initialize() async {
    final CallbackHandle callback =
        PluginUtilities.getCallbackHandle(callbackDispatcher)!;
    await _channel.invokeMethod(Keys.METHOD_PLUGIN_INITIALIZE_SERVICE,
        {Keys.ARG_CALLBACK_DISPATCHER: callback.toRawHandle()});
  }

  static WidgetsBinding? get _widgetsBinding => WidgetsBinding.instance;

  static LocalObserver? _observer;

  /// [autoStart] Restart the background locator when it stops in the
  /// [AppLifecycleState.inactive] or [AppLifecycleState.paused] states.
  /// It is only possible to use autoStart if autoStop is enabled.
  static Future<void> registerLocationUpdate(
      void Function(LocationDto) callback,
      {void Function(Map<String, dynamic>)? initCallback,
      Map<String, dynamic> initDataCallback = const {},
      void Function()? disposeCallback,
      bool autoStop = false,
      bool autoStart = false,
      AndroidSettings androidSettings = const AndroidSettings(),
      IOSSettings iosSettings = const IOSSettings()}) async {
    assert(autoStart ? autoStop : true,
        'It is only possible to use autoStart if autoStop is enabled');

    final args = SettingsUtil.getArgumentsMap(
        callback: callback,
        initCallback: initCallback,
        initDataCallback: initDataCallback,
        disposeCallback: disposeCallback,
        androidSettings: androidSettings,
        iosSettings: iosSettings);

    _registerLocalObserver(
      autoStart: autoStart,
      autoStop: autoStop,
      args: args,
    );

    await _registerLocationUpdateMethod(args: args);
  }

  static Future<void> unRegisterLocationUpdate() async {
    await _unRegisterLocationUpdateMethod();

    if (_observer != null) {
      _widgetsBinding!.removeObserver(_observer!);
    }
  }

  static Future<bool> isRegisterLocationUpdate() async {
    return (await _channel
        .invokeMethod<bool>(Keys.METHOD_PLUGIN_IS_REGISTER_LOCATION_UPDATE))!;
  }

  static Future<bool> isServiceRunning() async {
    return (await _channel
        .invokeMethod<bool>(Keys.METHOD_PLUGIN_IS_SERVICE_RUNNING))!;
  }

  static Future<void> updateNotificationText(
      {String? title, String? msg, String? bigMsg}) async {
    final Map<String, dynamic> arg = {};

    if (title != null) {
      arg[Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE] = title;
    }

    if (msg != null) {
      arg[Keys.SETTINGS_ANDROID_NOTIFICATION_MSG] = msg;
    }

    if (bigMsg != null) {
      arg[Keys.SETTINGS_ANDROID_NOTIFICATION_BIG_MSG] = bigMsg;
    }

    await _channel.invokeMethod(Keys.METHOD_PLUGIN_UPDATE_NOTIFICATION, arg);
  }

  static Future<void> _registerLocationUpdateMethod(
      {required Map<String, dynamic> args}) async {
    await _channel.invokeMethod(
        Keys.METHOD_PLUGIN_REGISTER_LOCATION_UPDATE, args);
  }

  static Future<void> _unRegisterLocationUpdateMethod() async {
    await _channel.invokeMethod(Keys.METHOD_PLUGIN_UN_REGISTER_LOCATION_UPDATE);
  }

  static void _registerLocalObserver({
    required bool autoStop,
    required bool autoStart,
    required Map<String, dynamic> args,
  }) {
    if (autoStop) {
      _observer = LocalObserver(
        stopCallback: () async => await unRegisterLocationUpdate(),
        temporaryStopCallback: () async => autoStart
            ? await _unRegisterLocationUpdateMethod()
            : await unRegisterLocationUpdate(),
        startCallback: autoStart
            ? () async => _registerLocationUpdateMethod(args: args)
            : null,
      );
      _widgetsBinding!.addObserver(_observer!);
    }
  }
}
