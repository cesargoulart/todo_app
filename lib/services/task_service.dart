import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/repeat_option.dart';

class TaskService {
  final SupabaseClient _client = Supabase.instance.client;

  // Método para adicionar uma tarefa
  Future<void> addTask(String title, String description, {DateTime? deadline, RepeatOption repeatOption = RepeatOption.never}) async {
    final response = await _client.from('todos').insert({
      'title': title,
      'description': description,
      'completed': false,
      'deadline': deadline?.toIso8601String(),
      'repeat_option': repeatOption.toJson(),
    }).execute();

    // Checa apenas se a inserção foi bem-sucedida com base no status
    if (response.status != 200 && response.status != 201) {
      throw Exception('Erro ao adicionar tarefa: Código de status ${response.status}');
    }

    // Mensagem opcional para debug
    print('Tarefa adicionada com sucesso!');
  }

  // Método para buscar todas as tarefas
  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final response = await _client.from('todos').select().execute();

    // Verifica se a resposta contém dados válidos
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
    final response = await _client.from('todos').update({
      'deadline': deadline?.toIso8601String(),
      'repeat_option': repeatOption.toJson(),
    }).eq('id', taskId).execute();

    if (response.status != 200 && response.status != 204) {
      throw Exception('Erro ao atualizar prazo: Código de status ${response.status}');
    }

    print('Prazo e repetição atualizados com sucesso!');
  }

  // Método para obter a próxima data com base na repetição
  DateTime? getNextDeadline(DateTime current, RepeatOption repeatOption) {
    switch (repeatOption) {
      case RepeatOption.never:
        return null;
      case RepeatOption.daily:
        return current.add(const Duration(days: 1));
      case RepeatOption.weekly:
        return current.add(const Duration(days: 7));
      case RepeatOption.monthly:
        return DateTime(
          current.year,
          current.month + 1,
          current.day,
          current.hour,
          current.minute,
        );
    }
  }

  // Método para atualizar o estado de conclusão da tarefa
  Future<void> updateTaskCompletion(int taskId, bool isCompleted) async {
    final response = await _client.from('todos').update({
      'completed': isCompleted,
    }).eq('id', taskId).execute();

    if (response.status != 200 && response.status != 204) {
      throw Exception('Erro ao atualizar tarefa: Código de status ${response.status}');
    }

    print('Tarefa atualizada com sucesso!');
  }

  // Método para excluir uma tarefa
  Future<void> deleteTask(int taskId) async {
    final response = await _client.from('todos').delete().eq('id', taskId).execute();

    if (response.status != 200 && response.status != 204) {
      throw Exception('Erro ao excluir tarefa: Código de status ${response.status}');
    }

    print('Tarefa excluída com sucesso!');
  }
}
