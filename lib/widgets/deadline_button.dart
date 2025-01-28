import 'package:flutter/material.dart';
import 'deadline_picker_dialog.dart';
import 'package:intl/intl.dart';
import '../models/repeat_option.dart';

class DeadlineButton extends StatelessWidget {
  final DateTime? deadline;
  final Color color;
  final RepeatOption? repeatOption;
  final Function(DateTime?, RepeatOption?) onDeadlineChanged;

  const DeadlineButton({
    Key? key,
    required this.deadline,
    required this.color,
    this.repeatOption,
    required this.onDeadlineChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.calendar_today, color: color),
          if (deadline != null)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getDeadlineColor(deadline!),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      tooltip: deadline != null 
          ? 'Prazo: ${DateFormat('dd/MM/yyyy HH:mm').format(deadline!)}\n${repeatOption != RepeatOption.never ? 'Repete: ${repeatOption?.displayName}' : ''}'
          : 'Adicionar prazo',
      onPressed: () async {
        final result = await showDialog<Map<String, dynamic>?>(
          context: context,
          builder: (context) => DeadlinePickerDialog(
            initialDate: deadline,
            initialRepeatOption: repeatOption,
          ),
        );
        
        if (result != null) {
          onDeadlineChanged(
            result['deadline'] as DateTime?,
            result['repeatOption'] as RepeatOption,
          );
        }
      },
    );
  }

  Color _getDeadlineColor(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    final hours = difference.inHours;

    if (difference.isNegative) {
      return Colors.red;
    } else if (hours <= 24) {
      return Colors.red;
    } else if (hours <= 72) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
