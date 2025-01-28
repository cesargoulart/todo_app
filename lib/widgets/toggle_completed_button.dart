import 'package:flutter/material.dart';

class ToggleCompletedButton extends StatelessWidget {
  final bool hideCompleted;
  final VoidCallback onToggle;

  const ToggleCompletedButton({
    Key? key,
    required this.hideCompleted,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        hideCompleted ? Icons.visibility : Icons.visibility_off,
        color: hideCompleted ? Colors.grey.shade800 : Colors.blue.shade700,
      ),
      tooltip: hideCompleted ? 'Mostrar Completadas' : 'Ocultar Completadas',
      onPressed: onToggle,
    );
  }
}