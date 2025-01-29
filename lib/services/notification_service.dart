import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'task_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Create notification channel for Android
      if (Theme.of(NavigationService.navigatorKey.currentContext!).platform ==
          TargetPlatform.android) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(const AndroidNotificationChannel(
              'task_deadlines',
              'Task Deadlines',
              description: 'Notifications for task deadlines',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ));
      }

      debugPrint('Notifications initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> showDeadlineNotification(String title, String description, int taskId) async {
    try {
      debugPrint('Showing notification for task: $title');

      showDialog(
        context: NavigationService.navigatorKey.currentContext!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Deadline Reached'),
            content: Text('Task "$title" deadline has been reached.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  TaskService().updateTaskCompletion(taskId, true);
                },
              ),
              TextButton(
                child: Text('Snooze'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Implement snooze functionality
                },
              ),
            ],
          );
        },
      );

      debugPrint('Notification dialog shown successfully');
    } catch (e) {
      debugPrint('Error showing notification dialog: $e');
    }
  }
}

// Navigator key for access to BuildContext
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
