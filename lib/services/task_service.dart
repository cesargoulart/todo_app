import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/repeat_option.dart';
import '../models/repeat_settings.dart';
import 'package:flutter/material.dart';

class TaskService {
  final SupabaseClient _client = Supabase.instance.client;
  Timer? _deadlineCheckTimer;
  DateTime? _lastCheck;

  TaskService() {
    debugPrint('TaskService initialized');
  }

Future<void> updateTaskWithNextDeadline({
  required int taskId,
  required DateTime nextDeadline,
  required int completedCount,
}) async {
  return await _client.from('todos').update({
    'deadline': nextDeadline.toIso8601String(),
    'completed_count': completedCount,
  }).eq('id', taskId);
}
  // Method to add a task with repeat settings
  Future<void> addTask(String title, String description, {
    DateTime? deadline, 
    RepeatSettings? repeatSettings,
  }) async {
    final now = DateTime.now();
    
    // Get standardized deadline based on repetition settings
    final RepeatSettings settings = repeatSettings ?? RepeatSettings.never();
    
    // For repeating tasks, ensure we set a proper future date
    if (deadline != null && settings.option != RepeatOption.never) {
      // If deadline is in the past or now, get next occurrence
      if (!deadline.isAfter(now)) {
        final nextDeadline = getNextDeadlineWithSettings(deadline, settings);
        deadline = nextDeadline ?? now;
      }
    } else if (deadline != null && deadline.isBefore(now)) {
      // For non-repeating tasks, if deadline is in past, set to now
      deadline = now;
    }

    final response = await _client.from('todos').insert({
      'title': title,
      'description': description,
      'completed': false,
      'deadline': deadline?.toIso8601String(),
      'repeat_settings': settings.toJson(),
      'completed_count': 0, // Track how many instances have been completed
    }).select().maybeSingle();

    if (response == null) {
      throw Exception('Erro ao adicionar tarefa: Código de status null');
    }

    debugPrint('Task added successfully: $title');
  }

  // Method to fetch all tasks
  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final response = await _client.from('todos').select();
    
    return List<Map<String, dynamic>>.from(response);
    }

  // Updated method to update task deadline and repetition settings
  Future<void> updateTaskDeadline({
    required int taskId,
    DateTime? deadline,
    RepeatSettings? repeatSettings,
  }) async {
    final now = DateTime.now();
    final settings = repeatSettings ?? RepeatSettings.never();
    
    // For repeating tasks, ensure we set a proper future date
    if (deadline != null && settings.option != RepeatOption.never) {
      // If deadline is in the past or now, get next occurrence
      if (!deadline.isAfter(now)) {
        final nextDeadline = getNextDeadlineWithSettings(deadline, settings);
        deadline = nextDeadline ?? now;
      }
    } else if (deadline != null && deadline.isBefore(now)) {
      // For non-repeating tasks, if deadline is in past, set to now
      deadline = now;
    }

    // First check if task exists
    final exists = await _client.from('todos')
        .select()
        .eq('id', taskId)
        .maybeSingle();
        
    if (exists == null) {
      throw Exception('Tarefa não encontrada. A tarefa pode ter sido excluída em outro dispositivo.');
    }

    // Then update if it exists
    await _client.from('todos').update({
      'deadline': deadline?.toIso8601String(),
      'repeat_settings': settings.toJson(),
    }).eq('id', taskId);

    debugPrint('Task deadline updated for ID: $taskId');
  }

  // Legacy method for backward compatibility
  Future<void> updateTaskDeadlineLegacy({
    required int taskId,
    DateTime? deadline,
    RepeatOption repeatOption = RepeatOption.never,
    List<int>? selectedDays,
  }) async {
    // Convert to new format
    final repeatSettings = RepeatSettings(
      option: repeatOption,
      selectedDays: selectedDays,
    );
    
    return updateTaskDeadline(
      taskId: taskId,
      deadline: deadline,
      repeatSettings: repeatSettings,
    );
  }

  // New method to get next deadline based on RepeatSettings
  DateTime? getNextDeadlineWithSettings(DateTime current, RepeatSettings settings) {
    final now = DateTime.now();
    DateTime? nextDeadline;

    // Check if we've reached the end date
    if (settings.endDate != null) {
      // If current date is already past end date, no more repetitions
      if (current.isAfter(settings.endDate!)) {
        return null;
      }
    }

    switch (settings.option) {
      case RepeatOption.never:
        return null;
      case RepeatOption.daily:
        nextDeadline = current.add(const Duration(days: 1));
        break;
      case RepeatOption.weekly:
        if (settings.selectedDays != null && settings.selectedDays!.isNotEmpty) {
          nextDeadline = _getNextWeeklyDeadline(current, settings.selectedDays!);
        } else {
          // Default to 7 days if no days selected
          nextDeadline = current.add(const Duration(days: 7));
        }
        break;
      case RepeatOption.monthly:
        nextDeadline = DateTime(
          current.year,
          current.month + 1,
          current.day,
          current.hour,
          current.minute,
        );
        break;
      case RepeatOption.yearly:
        nextDeadline = DateTime(
          current.year + 1,
          current.month,
          current.day,
          current.hour,
          current.minute,
        );
        break;
    }

    // Ensure next deadline is not in the past
    if (nextDeadline.isBefore(now)) {
      while (nextDeadline!.isBefore(now)) {
        switch (settings.option) {
          case RepeatOption.never:
            break;
          case RepeatOption.daily:
            nextDeadline = nextDeadline.add(const Duration(days: 1));
            break;
          case RepeatOption.weekly:
            if (settings.selectedDays != null && settings.selectedDays!.isNotEmpty) {
              nextDeadline = _getNextWeeklyDeadline(nextDeadline, settings.selectedDays!);
            } else {
              nextDeadline = nextDeadline.add(const Duration(days: 7));
            }
            break;
          case RepeatOption.monthly:
            nextDeadline = DateTime(
              nextDeadline.year,
              nextDeadline.month + 1,
              nextDeadline.day,
              nextDeadline.hour,
              nextDeadline.minute,
            );
            break;
          case RepeatOption.yearly:
            nextDeadline = DateTime(
              nextDeadline.year + 1,
              nextDeadline.month,
              nextDeadline.day,
              nextDeadline.hour,
              nextDeadline.minute,
            );
            break;
        }
      }
    }

    // Check against end date (if set)
    if (settings.endDate != null) {
      if (nextDeadline.isAfter(settings.endDate!)) {
        return null; // Don't schedule beyond end date
      }
    }

    return nextDeadline;
  }

  // Helper method for calculating weekly deadlines
  DateTime _getNextWeeklyDeadline(DateTime current, List<int> selectedDays) {
    // Sort days for consistent processing
    final sortedDays = List<int>.from(selectedDays)..sort();
    final currentWeekday = current.weekday;
    
    // Find days later in the week
    final laterDays = sortedDays.where((day) => day > currentWeekday).toList();
    
    if (laterDays.isNotEmpty) {
      // There's a day later this week
      final nextDay = laterDays.first;
      final daysToAdd = nextDay - currentWeekday;
      return current.add(Duration(days: daysToAdd));
    } else {
      // Need to wrap to next week
      final nextDay = sortedDays.first;
      final daysToAdd = 7 - currentWeekday + nextDay;
      return current.add(Duration(days: daysToAdd));
    }
  }

  // Legacy method for backward compatibility
  DateTime? getNextDeadline(
    DateTime current,
    RepeatOption repeatOption, [
    List<int>? selectedDays,
  ]) {
    final settings = RepeatSettings(
      option: repeatOption,
      selectedDays: selectedDays,
    );
    
    return getNextDeadlineWithSettings(current, settings);
  }

  // Updated method to handle repeating task completion
  Future<void> completeRepeatingTask(int taskId, {bool skipToNext = false}) async {
    // First get the task to check its settings
    final taskResponse = await _client.from('todos')
        .select()
        .eq('id', taskId)
        .maybeSingle();
        
    if (taskResponse == null) {
      throw Exception('Erro ao buscar tarefa: Tarefa não encontrada');
    }

    final task = taskResponse;
    
    // Handle legacy data structure
    RepeatSettings settings;
    if (task['repeat_settings'] != null) {
      try {
        final repeatSettingsData = task['repeat_settings'] is String 
            ? jsonDecode(task['repeat_settings']) 
            : task['repeat_settings'];
        settings = RepeatSettings.fromJson(repeatSettingsData);
      } catch (e) {
        debugPrint('Error parsing repeat settings: $e');
        settings = RepeatSettings.never();
      }
    } else if (task['repeat_option'] != null) {
      // Legacy format
      settings = RepeatSettings(
        option: RepeatOption.fromJson(task['repeat_option']),
        selectedDays: task['selected_days'] != null
            ? List<int>.from(task['selected_days'])
            : null,
      );
    } else {
      // No repetition
      settings = RepeatSettings.never();
    }
    
    int completedCount = task['completed_count'] ?? 0;
    
    // If task doesn't repeat or we're at the repetition limit
    if (settings.option == RepeatOption.never || 
        (settings.repeatCount != null && completedCount >= settings.repeatCount!)) {
      // Just mark as completed
      await updateTaskCompletion(taskId, true);
      return;
    }
    
    // For repeating tasks, calculate next deadline
    final currentDeadline = task['deadline'] != null 
        ? DateTime.parse(task['deadline']) 
        : DateTime.now();
        
    final nextDeadline = getNextDeadlineWithSettings(currentDeadline, settings);
    
    // No more deadlines (e.g., past end date)
    if (nextDeadline == null) {
      await updateTaskCompletion(taskId, true);
      return;
    }
    
    // Increment completion count if not skipping
    if (!skipToNext) {
      completedCount++;
    }

    // Update task with new deadline and completion count
    await _client.from('todos').update({
      'deadline': nextDeadline.toIso8601String(),
      'completed_count': completedCount,
    }).eq('id', taskId);
    
    debugPrint('Repeating task updated for ID: $taskId, new deadline: $nextDeadline');
  }

  // Method to update task completion status
  Future<void> updateTaskCompletion(int taskId, bool isCompleted) async {
    debugPrint('Updating task completion for ID: $taskId');
    
    // First check if task exists
    final exists = await _client
        .from('todos')
        .select()
        .eq('id', taskId)
        .maybeSingle();
        
    if (exists == null) {
      throw Exception('A tarefa não existe mais no banco de dados (ID: $taskId). Ela pode ter sido excluída por outro usuário ou dispositivo.');
    }

    // Then update if it exists
    final response = await _client
        .from('todos')
        .update({'completed': isCompleted})
        .eq('id', taskId);

    debugPrint('Task completion updated for ID: $taskId');
  }

  // Method to delete a task
  Future<void> deleteTask(int taskId) async {
    final response = await _client.from('todos').delete().eq('id', taskId).select();

    debugPrint('Task deleted: $taskId');
  }

  void dispose() {
    _deadlineCheckTimer?.cancel();
    debugPrint('TaskService disposed');
  }
}
