import 'package:froggydoro/notifications.dart';

class NotificationsHelper {
  final Notifications notificationHelper;

  NotificationsHelper({required this.notificationHelper});

  // Method to show a notification for Android
  Future<void> showAndroidNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await notificationHelper.showNotification(
        id: id,
        title: title,
        body: body,
      );
      print('Android notification displayed successfully.');
    } catch (e) {
      print('Error displaying Android notification: $e');
    }
  }

  // Method to schedule a notification for iOS
  Future<void> scheduleIOSNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      await notificationHelper.scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
      );
      print('iOS notification scheduled successfully.');
    } catch (e) {
      print('Error scheduling iOS notification: $e');
    }
  }

  // Method to cancel notifications
  Future<void> cancelNotification({
    required int id,
  }) async {
    try {
      await notificationHelper.cancelNotification(id);
      print('Notification with ID $id canceled successfully.');
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }

  // Method to cancel all scheduled notifications, passing scheduledNotifications as a parameter
  Future<void> cancelScheduledNotifications(Set<int> scheduledNotifications) async {
    try {
      // Iterate through the list passed as a parameter
      for (int id in scheduledNotifications) {
        await notificationHelper.cancelNotification(id);
      }
      // After canceling, clear the passed list
      scheduledNotifications.clear();
      print('All scheduled notifications canceled.');
    } catch (e) {
      print('Error canceling all scheduled notifications: $e');
    }
  }
}
