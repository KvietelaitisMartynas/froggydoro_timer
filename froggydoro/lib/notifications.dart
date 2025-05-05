import 'dart:developer';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Notifications {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationDetails _notificationDetails() => const NotificationDetails(
    android: AndroidNotificationDetails(
      'froggydoro_channel',
      'Froggydoro Notifications',
      channelDescription: 'Froggydoro alerts for work/break sessions',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/frog_notif_icon',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  Notifications({FlutterLocalNotificationsPlugin? plugin})
    : flutterLocalNotificationsPlugin =
          plugin ?? FlutterLocalNotificationsPlugin();

  // Method that initializes the notifications class.
  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create the notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'froggydoro_channel', // Ensure this matches the channel ID in AndroidNotificationDetails
      'Froggydoro Notifications',
      description: 'Froggydoro alerts for work/break sessions',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Initialize timezone data
    tz.initializeTimeZones();

    // Request permissions
    await _requestPermissions();
  }

  // Method that requests permissions from the user to allow the app to send notifications.
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      // Request permissions for iOS
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      // Request permissions for Android (Android 13+ requires POST_NOTIFICATIONS permission)
      await Permission.notification.request();
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        _notificationDetails(),
      );
    } catch (e) {
      log('Error displaying notification: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (Platform.isAndroid) {
      // Skip scheduling notifications on Android
      return;
    }

    // Schedule notifications for iOS
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'Notification Payload',
      );
    } catch (e) {
      log('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      log('Error canceling notification: $e');
    }
  }
}
