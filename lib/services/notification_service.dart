import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart'; // Add this package
import '../services/task_service.dart';
import '../widgets/task_list_widget.dart';

// Define missing constants.
const int FLASHW_ALL = 3;
const int FLASHW_TIMERNOFG = 12;
final user32 = DynamicLibrary.open('user32.dll');
final flashWindowEx = user32.lookupFunction<
    Int32 Function(Pointer<FLASHWINFO>),
    int Function(Pointer<FLASHWINFO>)>('FlashWindowEx');

// Define the FLASHWINFO struct as expected by the Windows API.
final class FLASHWINFO extends Struct {
  @Uint32()
  external int cbSize;

  @IntPtr()
  external int hwnd;

  @Uint32()
  external int dwFlags;

  @Uint32()
  external int uCount;

  @Uint32()
  external int dwTimeout;
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
      // Initialize timezone data and set the local timezone.
      tz.initializeTimeZones();
      tz.setLocalLocation(
          tz.getLocation('America/Detroit')); // Change to your timezone

      // Initialize window_manager (add this)
      if (Platform.isWindows) {
        await windowManager.ensureInitialized();
      }

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

      // If on Windows, flash the taskbar and show an always-on-top window
      if (Platform.isWindows) {
        flashTaskbar();
        await _showWindowsAlwaysOnTopNotification(title, description, taskId);
      } else {
        // For non-Windows platforms, use the regular notification dialog
        if (NavigationService.navigatorKey.currentContext == null) {
          debugPrint('No valid context found for showing notification dialog');
          return;
        }

        showDialog(
          context: NavigationService.navigatorKey.currentContext!,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return _buildNotificationDialog(context, title, taskId);
          },
        );
      }

      debugPrint('Notification shown successfully');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Function to create an always-on-top window notification for Windows
  Future<void> _showWindowsAlwaysOnTopNotification(
      String title, String description, int taskId) async {
    // Store the current window state
    bool wasAlwaysOnTop = await windowManager.isAlwaysOnTop();
    
    try {
      // Make sure the window is visible and on top
      await windowManager.setAlwaysOnTop(true);
      await windowManager.focus();
      
      // Ensure we have a valid context
      if (NavigationService.navigatorKey.currentContext == null) {
        debugPrint('No valid context found for showing notification dialog');
        return;
      }
      
      // Show the notification dialog
      showDialog(
        context: NavigationService.navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return _buildNotificationDialog(context, title, taskId);
        },
      );
    } catch (e) {
      debugPrint('Error showing Windows notification: $e');
    }
  }

  // Extract dialog building to a separate method for reuse
  Widget _buildNotificationDialog(BuildContext context, String title, int taskId) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: const Text('Deadline Reached'),
        content: Text('Task "$title" deadline has been reached.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Snooze'),
            onPressed: () async {
              Navigator.of(context).pop();
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
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
              
              // Reset always-on-top if needed
              _resetWindowState();
            },
          ),
          TextButton(
            child: const Text('Complete',
                style: TextStyle(color: Color.fromARGB(255, 152, 236, 155))),
            onPressed: () async {
              Navigator.of(context).pop();
              await TaskService().completeRepeatingTask(taskId);
              TaskListWidgetState.instance?.reloadTasks();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task marked as completed'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              
              // Reset always-on-top if needed
              _resetWindowState();
            },
          ),
          TextButton(
            child: const Text('Dismiss'),
            onPressed: () {
              Navigator.of(context).pop();
              
              // Reset always-on-top if needed
              _resetWindowState();
            },
          ),
        ],
      ),
    );
  }

  // Helper method to reset window state after notification is dismissed
  Future<void> _resetWindowState() async {
    if (Platform.isWindows) {
      try {
        // Set back to not always on top
        await windowManager.setAlwaysOnTop(false);
      } catch (e) {
        debugPrint('Error resetting window state: $e');
      }
    }
  }

  // Function to flash the taskbar on Windows.
  void flashTaskbar() {
    try {
      final hwnd = GetActiveWindow();
      if (hwnd == 0) {
        debugPrint('No active window handle found.');
        return;
      }
      final flashInfo = calloc<FLASHWINFO>();
      flashInfo.ref.cbSize = sizeOf<FLASHWINFO>();
      flashInfo.ref.hwnd = hwnd;
      flashInfo.ref.dwFlags = FLASHW_ALL | FLASHW_TIMERNOFG;
      flashInfo.ref.uCount = 3;
      flashInfo.ref.dwTimeout = 0;
      
      // Use the manually defined function
      flashWindowEx(flashInfo);
      
      calloc.free(flashInfo);
      debugPrint('Taskbar flashed.');
    } catch (e) {
      debugPrint('Error flashing taskbar: $e');
    }
  }
}

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}