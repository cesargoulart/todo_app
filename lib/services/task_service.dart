import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/repeat_option.dart';
import 'package:flutter/material.dart';

class TaskService {
  final SupabaseClient _client = Supabase.instance.client;
  Timer? _deadlineCheckTimer;
  DateTime? _lastCheck;

  TaskService() {
    debugPrint('TaskService initialized');
  }

  // Método para adicionar uma tarefa
  Future<void> addTask(String title, String description, {
    DateTime? deadline, 
    RepeatOption repeatOption = RepeatOption.never,
    List<int>? selectedDays,
  }) async {
    final now = DateTime.now();
    
    // For repeating tasks, ensure we set a proper future date
    if (deadline != null && repeatOption != RepeatOption.never) {
      // If deadline is in the past or now, get next occurrence
      if (!deadline.isAfter(now)) {
        final nextDeadline = getNextDeadline(deadline, repeatOption, selectedDays);
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
      'repeat_option': repeatOption.toJson(),
      'selected_days': selectedDays,
    }).maybeSingle();

    if (response == null || response['error'] != null) {
      throw Exception('Erro ao adicionar tarefa: Código de status ${response?['status']}');
    }

    debugPrint('Task added successfully: $title');
  }

  // Método para buscar todas as tarefas
  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final response = await _client.from('todos').select();

    if (response == null) {
      throw Exception('Erro ao buscar tarefas: Resposta nula');
    }
    
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    } else {
      throw Exception('Erro ao buscar tarefas: Resposta inesperada ${response.runtimeType}');
    }
  }

  // Método para atualizar o prazo e repetição da tarefa
  Future<void> updateTaskDeadline({
    required int taskId,
    DateTime? deadline,
    RepeatOption repeatOption = RepeatOption.never,
    List<int>? selectedDays,
  }) async {
    final now = DateTime.now();
    
    // For repeating tasks, ensure we set a proper future date
    if (deadline != null && repeatOption != RepeatOption.never) {
      // If deadline is in the past or now, get next occurrence
      if (!deadline.isAfter(now)) {
        final nextDeadline = getNextDeadline(deadline, repeatOption, selectedDays);
        deadline = nextDeadline ?? now;
      }
    } else if (deadline != null && deadline.isBefore(now)) {
      // For non-repeating tasks, if deadline is in past, set to now
      deadline = now;
    }

    final response = await _client.from('todos').update({
      'deadline': deadline?.toIso8601String(),
      'repeat_option': repeatOption.toJson(),
      'selected_days': selectedDays,
    }).eq('id', taskId).maybeSingle();

    if (response == null || response['error'] != null) {
      throw Exception('Erro ao atualizar prazo: Código de status ${response?['status']}');
    }

    debugPrint('Task deadline updated for ID: $taskId');
  }

  // Método para obter a próxima data com base na repetição
  DateTime? getNextDeadline(
    DateTime current,
    RepeatOption repeatOption, [
    List<int>? selectedDays,
  ]) {
    final now = DateTime.now();
    DateTime? nextDeadline;

    switch (repeatOption) {
      case RepeatOption.never:
        return null;
      case RepeatOption.daily:
        nextDeadline = current.add(const Duration(days: 1));
        break;
      case RepeatOption.weekly:
        if (selectedDays != null && selectedDays.isNotEmpty) {
          // Find the next selected day that's after current
          final currentWeekday = current.weekday;
          final sortedDays = List<int>.from(selectedDays)..sort();
          
          // Find the next day after current weekday
          int? nextDay = sortedDays.firstWhere(
            (day) => day > currentWeekday,
            orElse: () => sortedDays.first, // Wrap around to first day if none found
          );
          
          // Calculate days to add
          int daysToAdd;
          if (nextDay <= currentWeekday) {
            // If wrapping around to next week
            daysToAdd = 7 - currentWeekday + nextDay;
          } else {
            daysToAdd = nextDay - currentWeekday;
          }
          
          // Add days while keeping time components
          nextDeadline = current.add(Duration(days: daysToAdd));
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
    if (nextDeadline != null && nextDeadline.isBefore(now)) {
      while (nextDeadline!.isBefore(now)) {
        switch (repeatOption) {
          case RepeatOption.never:
            break;
          case RepeatOption.daily:
            nextDeadline = nextDeadline.add(const Duration(days: 1));
            break;
          case RepeatOption.weekly:
            if (selectedDays != null && selectedDays.isNotEmpty) {
              // Find the next selected day after current
              final currentWeekday = nextDeadline.weekday;
              final sortedDays = List<int>.from(selectedDays)..sort();
              
              // Find the next day after today
              int? nextDay = sortedDays.firstWhere(
                (day) => day > currentWeekday,
                orElse: () => sortedDays.first, // Wrap around to first day if none found
              );
              
              // Calculate days to add
              int daysToAdd;
              if (nextDay <= currentWeekday) {
                // If wrapping around to next week
                daysToAdd = 7 - currentWeekday + nextDay;
              } else {
                daysToAdd = nextDay - currentWeekday;
              }
              
              nextDeadline = nextDeadline.add(Duration(days: daysToAdd));
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

    return nextDeadline;
  }

  // Método para atualizar o estado de conclusão da tarefa
  Future<void> updateTaskCompletion(int taskId, bool isCompleted) async {
    final response = await _client.from('todos').update({
      'completed': isCompleted,
    }).eq('id', taskId).maybeSingle();

    if (response == null || response['error'] != null) {
      throw Exception('Erro ao atualizar tarefa: Código de status ${response?['status']}');
    }

    debugPrint('Task completion updated for ID: $taskId');
  }

  // Método para excluir uma tarefa
  Future<void> deleteTask(int taskId) async {
    final response = await _client.from('todos').delete().eq('id', taskId).maybeSingle();

    if (response == null || response['error'] != null) {
      throw Exception('Erro ao excluir tarefa: Código de status ${response?['status']}');
    }

    debugPrint('Task deleted: $taskId');
  }

  void dispose() {
    _deadlineCheckTimer?.cancel();
    debugPrint('TaskService disposed');
  }
}
