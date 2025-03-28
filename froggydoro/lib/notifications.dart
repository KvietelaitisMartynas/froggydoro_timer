import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Notifications {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  Notifications({FlutterLocalNotificationsPlugin? plugin})
    : flutterLocalNotificationsPlugin =
          plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
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
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        if (status.isGranted) {
          print('Notification permission granted on Android.');
        } else {
          print('Notification permission denied on Android.');
        }
      } else {
        print('Notification permission already granted on Android.');
      }
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
        const NotificationDetails(
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
        ),
      );
      print('Notification displayed successfully.');
    } catch (e) {
      print('Error displaying notification: $e');
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
      print('Skipping scheduled notification on Android.');
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
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'froggydoro_channel',
            'Froggydoro Notifications',
            channelDescription: 'Froggydoro alerts for work/break sessions',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'Notification Payload',
      );
      print('Scheduled notification successfully on iOS.');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      print('Notification with ID $id canceled successfully.');
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }
}
