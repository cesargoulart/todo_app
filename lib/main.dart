import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'pages/add_task_page.dart';
import 'widgets/task_list_widget.dart';
import 'services/notification_service.dart';
import 'services/task_service.dart' as task_service;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://vggdloymkuntqiisrivy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZnZ2Rsb3lta3VudHFpaXNyaXZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc4OTQxNTUsImV4cCI6MjA1MzQ3MDE1NX0.X1-dH3eRMcwQZ3fqkvHJ0gbweWM0UfO76Nqh8NV1gCo',
  );

  // Initialize Task Service after Supabase
  final taskService = TaskService();

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initializeNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<TaskListWidgetState> _taskListKey = GlobalKey<TaskListWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo Task App'),
      ),
      body: TaskListWidget(
        key: _taskListKey,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskPage()),
          );

          if (result == true) {
            _taskListKey.currentState?.reloadTasks();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
