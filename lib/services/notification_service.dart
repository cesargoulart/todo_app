import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the notification service before running the app.
  await NotificationService().initializeNotifications();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Test App',
      navigatorKey: NavigationService.navigatorKey,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Test App')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // This will trigger the popup dialog.
            NotificationService().showDeadlineNotification(
              "Test Task",
              "This is a test notification.",
              1,
            );
          },
          child: const Text("Show Notification Popup"),
        ),
      ),
    );
  }
}

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
                  child: const Text('OK', style: TextStyle(color: Color.fromARGB(255, 152, 236, 155))),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await TaskService().updateTaskCompletion(taskId, true);

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
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue, // Ensures contrast.
                  ),
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
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

// Dummy TaskService implementation for demonstration.
class TaskService {
  Future<void> updateTaskCompletion(int taskId, bool completed) async {
    debugPrint('Task $taskId updated to completed: $completed');
    // Simulate a network or database update delay.
    await Future.delayed(const Duration(seconds: 1));
  }
}
