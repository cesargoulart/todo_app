import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../services/task_service.dart';
import '../widgets/task_list_widget.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initializeNotifications() async {
    try {
      // Initialize timezone data.
      tz.initializeTimeZones();

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

      // Create notification channel for Android.
      if (Platform.isAndroid) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(const AndroidNotificationChannel(
              'task_deadlines',
              'Task Deadlines',
              description: 'Notifications for task deadlines',
              importance: Importance.max,
            ));
      }

      debugPrint('Notifications initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> showDeadlineNotification(
      String title, String description, int taskId) async {
    try {
debugPrint('Showing notification for task: $title');
debugPrint('Current context: ${NavigationService.navigatorKey.currentContext}');

      // Ensure that a valid context is available.
      if (NavigationService.navigatorKey.currentContext == null) {
        debugPrint('No valid context found for showing notification dialog');
        return;
      }

      showDialog(
        context: NavigationService.navigatorKey.currentContext!,
        barrierDismissible: false, // Prevent dismiss by tapping outside.
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false, // Prevent dismiss via back button.
            child: AlertDialog(
              title: const Text('Deadline Reached'),
              content: Text('Task "$title" deadline has been reached.'),
              actions: <Widget>[
                // Snooze action.
                TextButton(
                  child: const Text('Snooze'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Schedule a new notification 5 minutes from now.
                    final now = DateTime.now();
                    final snoozeTime = now.add(const Duration(minutes: 5));

                    await _notifications.zonedSchedule(
                      taskId,
                      'Snoozed Task',
                      title,
                      tz.TZDateTime.from(snoozeTime, tz.local),
                      const NotificationDetails(
                        android: AndroidNotificationDetails(
                          'task_deadlines',
                          'Task Deadlines',
                          importance: Importance.max,
                          priority: Priority.high,
                        ),
                      ),
                      androidAllowWhileIdle: true,
                      uiLocalNotificationDateInterpretation:
                          UILocalNotificationDateInterpretation.absoluteTime,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task snoozed for 5 minutes'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                // Check action.
                TextButton(
                  child: const Text('Complete', style: TextStyle(color: Color.fromARGB(255, 152, 236, 155))),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await TaskService().completeRepeatingTask(taskId);
                    
                    // Trigger UI refresh using TaskListWidget instance
                    TaskListWidgetState.instance?.reloadTasks();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task marked as completed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                // OK action with explicit style.
         
                TextButton(
                  child: const Text('Dismiss'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      );

      debugPrint('Notification dialog shown successfully');
    } catch (e) {
      debugPrint('Error showing notification dialog: $e');
    }
  }
}

// Navigator key for access to BuildContext from anywhere.
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
