import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../models/repeat_option.dart';
import '../models/repeat_settings.dart';
import 'deadline_button.dart';
import 'filter_buttons_bar.dart';
import 'hide_overdue_button.dart';
import 'dart:async';
import 'dart:convert';
import '../services/notification_service.dart';

class TaskListWidget extends StatefulWidget {
  const TaskListWidget({super.key});

  @override
  State<TaskListWidget> createState() => TaskListWidgetState();
}

class TaskListWidgetState extends State<TaskListWidget> {
  static TaskListWidgetState? instance;
  final TaskService _taskService = TaskService();
  List<Map<String, dynamic>> _tasks = [];

  bool _isLoading = true;
  bool _hideCompleted = true;
  bool _hideLongDeadlines = true;
  bool _hideOverdue = false;
  Timer? _deadlineCheckTimer;
  final Set<String> _shownDialogs = {};

  // List of colors for task boxes
  final List<Color> _boxColors = [
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFFE53935),
    Color(0xFFFB8C00),
  ];

  @override
  void initState() {
    super.initState();
    instance = this;
    _fetchTasks();
    _startDeadlineCheck();
  }

  void _startDeadlineCheck() {
    _deadlineCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkDeadlines();
    });
  }

  RepeatSettings _getRepeatSettings(Map<String, dynamic> task) {
    if (task['repeat_settings'] != null) {
      final repeatSettingsData = task['repeat_settings'] is String
          ? jsonDecode(task['repeat_settings'])
          : task['repeat_settings'];
      return RepeatSettings.fromJson(repeatSettingsData);
    }

    if (task['repeat_option'] != null) {
      return RepeatSettings(
        option: RepeatOption.fromJson(task['repeat_option']),
        selectedDays: _parseSelectedDays(task['selected_days']),
      );
    }

    return RepeatSettings.never();
  }

  List<int>? _parseSelectedDays(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e as int).toList();
    }
    return null;
  }

  Future<void> _checkDeadlines() async {
    try {
      final now = DateTime.now();
      debugPrint('Checking deadlines at ${now.toString()}');

      for (final task in _tasks) {
        if (task['deadline'] != null && !task['completed']) {
          final deadline = DateTime.parse(task['deadline']);
          final timeUntilDeadline = deadline.difference(now);
          final dialogKey = '${task['id']}_${deadline.toString()}';

          if (timeUntilDeadline.inSeconds >= 0 &&
              timeUntilDeadline.inSeconds < 1 &&
              !_shownDialogs.contains(dialogKey)) {
            debugPrint('Task deadline reached: ${task['title']}');
            _shownDialogs.add(dialogKey);

            NotificationService().showDeadlineNotification(
              task['title'],
              task['description'],
              task['id'],
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking deadlines: $e');
    }
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await _taskService.fetchTasks();
      tasks.sort((a, b) {
        DateTime? aDeadline =
            a['deadline'] != null ? DateTime.parse(a['deadline']) : null;
        DateTime? bDeadline =
            b['deadline'] != null ? DateTime.parse(b['deadline']) : null;

        if (aDeadline == null && bDeadline == null) return 0;
        if (aDeadline == null) return 1;
        if (bDeadline == null) return -1;
        return aDeadline.compareTo(bDeadline);
      });
      setState(() {
        _tasks = tasks;
        _shownDialogs.removeWhere((dialogKey) {
          final taskId = int.tryParse(dialogKey.split('_')[0]);
          return taskId == null || !tasks.any((task) => task['id'] == taskId);
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar tarefas: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTaskCompletion(int taskId, bool isCompleted) async {
    try {
      setState(() {
        final taskIndex = _tasks.indexWhere((t) => t['id'] == taskId);
        if (taskIndex != -1) {
          _tasks[taskIndex] = {
            ..._tasks[taskIndex],
            'completed': isCompleted,
          };
        }
      });

      final task = _tasks.firstWhere(
        (t) => t['id'] == taskId,
        orElse: () => throw Exception(
            'Não foi possível encontrar a tarefa na lista local. Tentando atualizar a lista...'),
      );
      final repeatSettings = _getRepeatSettings(task);

      if (isCompleted && repeatSettings.option != RepeatOption.never) {
        final choice = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Tarefa Recorrente'),
              content: const Text('Esta é uma tarefa recorrente. O que deseja fazer?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'complete_instance'),
                  child: const Text('Concluir Esta Ocorrência'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'skip'),
                  child: const Text('Pular Para Próxima'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'complete_all'),
                  child: const Text('Concluir Todas'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'cancel'),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );

        if (choice == 'cancel' || choice == null) {
          return;
        }

        if (choice == 'complete_all') {
          await _taskService.updateTaskCompletion(taskId, true);
        } else {
          final bool incrementCompletionCount = (choice == 'complete_instance');
          final deadline = DateTime.parse(task['deadline']);
          final nextDeadline = _taskService.getNextDeadlineWithSettings(
              deadline, repeatSettings);

          if (nextDeadline == null) {
            await _taskService.updateTaskCompletion(taskId, true);
          } else {
            final completedCount =
                (task['completed_count'] ?? 0) + (incrementCompletionCount ? 1 : 0);

            await _taskService.updateTaskWithNextDeadline(
              taskId: taskId,
              nextDeadline: nextDeadline,
              completedCount: completedCount,
            );
          }
        }
      } else {
        await _taskService.updateTaskCompletion(taskId, isCompleted);
      }

      _fetchTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar tarefa: $e')),
        );
        _fetchTasks();
      }
    }
  }

  @override
  void dispose() {
    if (instance == this) {
      instance = null;
    }
    _deadlineCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_tasks.isEmpty) {
      return const Center(
        child: Text('Nenhuma tarefa encontrada.'),
      );
    }

    final visibleTasks = _tasks.where((task) {
      final deadline =
          task['deadline'] != null ? DateTime.parse(task['deadline']) : null;
      final isCompleted = task['completed'] ?? false;
      final isLongDeadline =
          deadline != null && deadline.difference(DateTime.now()).inDays > 2;
      final isOverdue = deadline != null && deadline.isBefore(DateTime.now());

      if (_hideCompleted && isCompleted) {
        return false;
      }

      if (_hideLongDeadlines && isLongDeadline) {
        return false;
      }

      // When hideOverdue is true, hide overdue tasks
      if (_hideOverdue && isOverdue) {
        return false;
      }

      return true;
    }).toList();

    return Stack(
      children: [
        ListView.builder(
          itemCount: visibleTasks.length,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemBuilder: (context, index) {
            final task = visibleTasks[index];
            final color = _boxColors[index % _boxColors.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Checkbox(
                    value: task['completed'],
                    activeColor: color,
                    checkColor: Colors.white,
                    onChanged: (value) {
                      if (value != null) {
                        _toggleTaskCompletion(task['id'], value);
                      }
                    },
                  ),
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      task['title'],
                      style: TextStyle(
                        decoration: task['completed']
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: color.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['description'],
                        style: TextStyle(
                          color: color.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      if (task['completed_count'] != null &&
                          task['completed_count'] > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Completado ${task['completed_count']} vezes',
                            style: TextStyle(
                              color: color.withOpacity(0.5),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DeadlineButton(
                        deadline: task['deadline'] != null
                            ? DateTime.parse(task['deadline'])
                            : null,
                        repeatSettings: _getRepeatSettings(task),
                        color: color,
                        onDeadlineChanged: (newDeadline, newRepeatSettings) async {
                          try {
                            await _taskService.updateTaskDeadline(
                              taskId: task['id'],
                              deadline: newDeadline,
                              repeatSettings: newRepeatSettings,
                            );
                            _fetchTasks();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    newDeadline != null
                                        ? 'Prazo atualizado!'
                                        : 'Prazo removido!',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: color.withOpacity(0.8),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.red[700],
                                  duration: const Duration(seconds: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: color),
                        onPressed: () async {
                          try {
                            await _taskService.deleteTask(task['id']);
                            _fetchTasks();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tarefa excluída!',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: color.withOpacity(0.8),
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erro ao excluir: $e',
                                  style: TextStyle(color: color.withOpacity(0.9)),
                                ),
                                backgroundColor: Colors.white.withOpacity(0.9),
                                behavior: SnackBarBehavior.floating,
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                        splashRadius: 24,
                        style: IconButton.styleFrom(
                          foregroundColor: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                FilterButtonsBar(
                  hideCompleted: _hideCompleted,
                  hideLongDeadlines: _hideLongDeadlines,
                  onToggleCompleted: () {
                    setState(() {
                      _hideCompleted = !_hideCompleted;
                    });
                  },
                  onToggleLongDeadlines: () {
                    setState(() {
                      _hideLongDeadlines = !_hideLongDeadlines;
                    });
                  },
                ),
                const SizedBox(width: 16),
                HideOverdueButton(
                  hideOverdue: _hideOverdue,
                  onToggleOverdue: () {
                    setState(() {
                      _hideOverdue = !_hideOverdue;
                    });
                  },
                  color: Colors.red[700]!,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void reloadTasks() {
    _fetchTasks();
  }
}
