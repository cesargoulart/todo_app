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
  Future<void> addTask(String title, String description, {DateTime? deadline, RepeatOption repeatOption = RepeatOption.never}) async {
    // If deadline is in the past, set it to now
    final now = DateTime.now();
    if (deadline != null && deadline.isBefore(now)) {
      deadline = now;
    }

    final response = await _client.from('todos').insert({
      'title': title,
      'description': description,
      'completed': false,
      'deadline': deadline?.toIso8601String(),
      'repeat_option': repeatOption.toJson(),
    }).execute();

    if (response.status != 200 && response.status != 201) {
      throw Exception('Erro ao adicionar tarefa: Código de status ${response.status}');
    }

    debugPrint('Task added successfully: $title');
  }

  // Método para buscar todas as tarefas
  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final response = await _client.from('todos').select().execute();

    if (response.status != 200) {
      throw Exception('Erro ao buscar tarefas: Código de status ${response.status}');
    }

    return List<Map<String, dynamic>>.from(response.data ?? []);
  }

  // Método para atualizar o prazo e repetição da tarefa
  Future<void> updateTaskDeadline(
    int taskId, 
    DateTime? deadline,
    [RepeatOption repeatOption = RepeatOption.never]
  ) async {
    // If deadline is in the past, set it to now
    final now = DateTime.now();
    if (deadline != null && deadline.isBefore(now)) {
      deadline = now;
    }

    final response = await _client.from('todos').update({
      'deadline': deadline?.toIso8601String(),
      'repeat_option': repeatOption.toJson(),
    }).eq('id', taskId).execute();

    if (response.status != 200 && response.status != 204) {
      throw Exception('Erro ao atualizar prazo: Código de status ${response.status}');
    }

    debugPrint('Task deadline updated for ID: $taskId');
  }

  // Método para obter a próxima data com base na repetição
  DateTime? getNextDeadline(DateTime current, RepeatOption repeatOption) {
    final now = DateTime.now();
    DateTime? nextDeadline;

    switch (repeatOption) {
      case RepeatOption.never:
        return null;
      case RepeatOption.daily:
        nextDeadline = current.add(const Duration(days: 1));
        break;
      case RepeatOption.weekly:
        nextDeadline = current.add(const Duration(days: 7));
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
            nextDeadline = nextDeadline.add(const Duration(days: 7));
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
        }
      }
    }

    return nextDeadline;
  }

  // Método para atualizar o estado de conclusão da tarefa
  Future<void> updateTaskCompletion(int taskId, bool isCompleted) async {
    final response = await _client.from('todos').update({
      'completed': isCompleted,
    }).eq('id', taskId).execute();

    if (response.status != 200 && response.status != 204) {
      throw Exception('Erro ao atualizar tarefa: Código de status ${response.status}');
    }

    debugPrint('Task completion updated for ID: $taskId');
  }

  // Método para excluir uma tarefa
  Future<void> deleteTask(int taskId) async {
    final response = await _client.from('todos').delete().eq('id', taskId).execute();

    if (response.status != 200 && response.status != 204) {
      throw Exception('Erro ao excluir tarefa: Código de status ${response.status}');
    }

    debugPrint('Task deleted: $taskId');
  }

  void dispose() {
    _deadlineCheckTimer?.cancel();
    debugPrint('TaskService disposed');
  }
}
