// In add_task_page.dart
import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../models/repeat_option.dart';
import '../models/repeat_settings.dart';
import '../widgets/deadline_picker_dialog.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TaskService _taskService = TaskService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  DateTime? _selectedDeadline;
  RepeatSettings? _repeatSettings;

  Future<void> _showDeadlinePicker() async {
    final result = await showDialog(
      context: context,
      builder: (context) => DeadlinePickerDialog(
        initialDate: _selectedDeadline,
        initialRepeatSettings: _repeatSettings,
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedDeadline = result['deadline'] as DateTime?;
        _repeatSettings = result['repeatSettings'] as RepeatSettings?;
      });
    }
  }

  String _getRepeatSummary() {
    if (_repeatSettings == null || _repeatSettings!.option == RepeatOption.never) {
      return 'Não repete';
    }
    
    String summary = _repeatSettings!.option.displayName;
    
    // Add weekly days if applicable
    if (_repeatSettings!.option == RepeatOption.weekly && 
        _repeatSettings!.selectedDays != null &&
        _repeatSettings!.selectedDays!.isNotEmpty) {
      List<String> weekDays = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      final days = _repeatSettings!.selectedDays!.map((d) => weekDays[d]).join(', ');
      summary += ' ($days)';
    }
    
    // Add repetition limits if applicable
    if (_repeatSettings!.repeatCount != null) {
      summary += ' - ${_repeatSettings!.repeatCount} vezes';
    } else if (_repeatSettings!.endDate != null) {
      final endDateStr = _repeatSettings!.endDate!.toLocal().toString().split(' ')[0];
      summary += ' - até $endDateStr';
    }
    
    return summary;
  }

  Future<void> _addTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.addTask(
        _titleController.text,
        _descriptionController.text,
        deadline: _selectedDeadline,
        repeatSettings: _repeatSettings,
      );

      // Mostra uma mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefa adicionada com sucesso!')),
      );

      // Volta para a tela principal e sinaliza que uma nova tarefa foi adicionada
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar tarefa: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Tarefa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Deadline and repetition section
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prazo & Repetição',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(_selectedDeadline == null 
                        ? 'Definir prazo'
                        : 'Prazo: ${_selectedDeadline!.toLocal().toString().split('.')[0]}'),
                      subtitle: _repeatSettings != null && _repeatSettings!.option != RepeatOption.never
                        ? Text(_getRepeatSummary())
                        : null,
                      trailing: _selectedDeadline != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _selectedDeadline = null;
                              _repeatSettings = null;
                            }),
                          )
                        : null,
                      onTap: _showDeadlinePicker,
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Add button
            SizedBox(
              width: double.infinity,
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: () {
                      if (_titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('O título é obrigatório')),
                        );
                        return;
                      }
                      _addTask();
                    },
                    child: const Text('Adicionar Tarefa'),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}