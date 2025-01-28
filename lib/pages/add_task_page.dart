import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../models/repeat_option.dart';
import '../widgets/deadline_picker_dialog.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({Key? key}) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TaskService _taskService = TaskService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  DateTime? _selectedDeadline;
  RepeatOption _selectedRepeatOption = RepeatOption.never;

  Future<void> _showDeadlinePicker() async {
    final result = await showDialog(
      context: context,
      builder: (context) => DeadlinePickerDialog(
        initialDate: _selectedDeadline,
        initialRepeatOption: _selectedRepeatOption,
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedDeadline = result['deadline'] as DateTime;
        _selectedRepeatOption = result['repeatOption'] as RepeatOption;
      });
    }
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
        repeatOption: _selectedRepeatOption,
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
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(_selectedDeadline == null 
                ? 'Definir prazo'
                : 'Prazo: ${_selectedDeadline!.toLocal().toString().split('.')[0]}'),
              trailing: _selectedDeadline != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _selectedDeadline = null;
                      _selectedRepeatOption = RepeatOption.never;
                    }),
                  )
                : null,
              onTap: _showDeadlinePicker,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _addTask,
                    child: const Text('Adicionar'),
                  ),
          ],
        ),
      ),
    );
  }
}
