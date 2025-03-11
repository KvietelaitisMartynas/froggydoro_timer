import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications {
  static final Notifications _instance = Notifications._internal();

  factory Notifications() {
    return _instance;
  }

  Notifications._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/frog2');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'froggydoro_channel',
      'Froggydoro Notifications',
      description: 'Froggydoro alerts for work/break sessions',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('res_notif2'),
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'froggydoro_channel',
      'Froggydoro Notifications',
      channelDescription: 'Froggydoro alerts for work/break sessions',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF99B97E),
      playSound: true,
      sound: RawResourceAndroidNotificationSound('res_notif2'),
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
