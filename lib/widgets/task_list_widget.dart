import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../models/repeat_option.dart';
import 'toggle_completed_button.dart';
import 'hide_long_deadline_button.dart';
import 'deadline_button.dart';
import 'filter_buttons_bar.dart';

class TaskListWidget extends StatefulWidget {
  const TaskListWidget({Key? key}) : super(key: key);

  @override
  State<TaskListWidget> createState() => TaskListWidgetState();
}

class TaskListWidgetState extends State<TaskListWidget> {
  final TaskService _taskService = TaskService();
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  bool _hideCompleted = false;
  bool _hideLongDeadlines = false;

  // List of colors for task boxes
  final List<Color> _boxColors = [
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFF8E24AA), // Purple
    Color(0xFFE53935), // Red
    Color(0xFFFB8C00), // Orange
  ];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await _taskService.fetchTasks();
      setState(() {
        _tasks = tasks;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar tarefas: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTaskCompletion(int taskId, bool isCompleted) async {
    try {
      await _taskService.updateTaskCompletion(taskId, isCompleted);
      _fetchTasks(); // Atualiza a lista após alterar o estado da tarefa
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar tarefa: $e')),
      );
    }
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
      final deadline = task['deadline'] != null 
          ? DateTime.parse(task['deadline'])
          : null;
      final isCompleted = task['completed'] ?? false;
      final isLongDeadline = deadline != null && deadline.difference(DateTime.now()).inDays > 3;

      if (_hideCompleted && isCompleted) {
        return false;
      }

      if (_hideLongDeadlines && isLongDeadline) {
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  title: Text(
                    task['title'],
                    style: TextStyle(
                      decoration: task['completed']
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: color.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    task['description'],
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DeadlineButton(
                        deadline: task['deadline'] != null 
                            ? DateTime.parse(task['deadline'])
                            : null,
                        repeatOption: task['repeat_option'] != null
                            ? RepeatOption.fromJson(task['repeat_option'])
                            : RepeatOption.never,
                        color: color,
                        onDeadlineChanged: (newDeadline, repeatOption) async {
                          try {
                            await _taskService.updateTaskDeadline(
                              task['id'],
                              newDeadline,
                              repeatOption ?? RepeatOption.never,
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
                                  content: Text('Erro ao atualizar prazo: $e'),
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
          child: FilterButtonsBar(
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
        ),
      ],
    );
  }

  void reloadTasks() {
    _fetchTasks();
  }
}
