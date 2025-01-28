import 'package:flutter/material.dart';

class HideLongDeadlineButton extends StatelessWidget {
  final bool hideLongDeadlines;
  final VoidCallback onToggle;

  const HideLongDeadlineButton({
    Key? key,
    required this.hideLongDeadlines,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        hideLongDeadlines ? Icons.visibility_off : Icons.visibility,
        color: hideLongDeadlines ? Colors.grey.shade800 : Colors.blue.shade700,
      ),
      tooltip: hideLongDeadlines ? 'Mostrar Todos' : 'Ocultar Longos',
      onPressed: onToggle,
    );
  }
}