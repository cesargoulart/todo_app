import 'package:flutter/material.dart';
import '../models/repeat_option.dart';
import '../models/repeat_settings.dart';
import 'deadline_picker_dialog.dart';
import 'package:intl/intl.dart';

class DeadlineButton extends StatelessWidget {
  final DateTime? deadline;
  final RepeatSettings? repeatSettings;
  final Color color;
  final Function(DateTime?, RepeatSettings?) onDeadlineChanged;

  const DeadlineButton({
    super.key,
    this.deadline,
    this.repeatSettings,
    required this.color,
    required this.onDeadlineChanged,
  });

  String _formatDeadline(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final nextWeek = DateTime(now.year, now.month, now.day + 7);

    // Within 24 hours
    if (date.isBefore(tomorrow)) {
      return 'Hoje, ${DateFormat.Hm().format(date)}';
    }
    
    // Within the next 7 days
    if (date.isBefore(nextWeek)) {
      return DateFormat('E, HH:mm').format(date);
    }
    
    // Further than next week
    return DateFormat('dd/MM, HH:mm').format(date);
  }

  Widget _buildRepeatIcon() {
    if (repeatSettings == null || repeatSettings!.option == RepeatOption.never) {
      return const SizedBox.shrink();
    }

    IconData icon;
    switch (repeatSettings!.option) {
      case RepeatOption.daily:
        icon = Icons.update;
        break;
      case RepeatOption.weekly:
        icon = Icons.calendar_view_week;
        break;
      case RepeatOption.monthly:
        icon = Icons.calendar_month;
        break;
      case RepeatOption.yearly:
        icon = Icons.event;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Icon(
        icon,
        size: 14,
        color: color.withOpacity(0.7),
      ),
    );
  }

  String _getTooltipText() {
    if (deadline == null) {
      return 'Definir prazo';
    }

    final dateText = _formatDeadline(deadline!);

    if (repeatSettings == null || repeatSettings!.option == RepeatOption.never) {
      return 'Prazo: $dateText';
    }

    // Build repeat info text
    String repeatText = repeatSettings!.option.displayName;
    
    // Add weekly days if applicable
    if (repeatSettings!.option == RepeatOption.weekly && 
        repeatSettings!.selectedDays != null &&
        repeatSettings!.selectedDays!.isNotEmpty) {
      final List<String> dayNames = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      final days = repeatSettings!.selectedDays!.map((d) => dayNames[d]).join(', ');
      repeatText += ' ($days)';
    }
    
    // Add repetition limits if applicable
    if (repeatSettings!.repeatCount != null) {
      repeatText += '\n${repeatSettings!.repeatCount} vezes no total';
    } else if (repeatSettings!.endDate != null) {
      final endDateStr = DateFormat('dd/MM/yyyy').format(repeatSettings!.endDate!);
      repeatText += '\nAté $endDateStr';
    }

    return 'Prazo: $dateText\nRepete: $repeatText';
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _getTooltipText(),
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final result = await showDialog(
            context: context,
            builder: (context) => DeadlinePickerDialog(
              initialDate: deadline,
              initialRepeatSettings: repeatSettings,
            ),
          );
          
          if (result != null) {
            if (result is Map<String, dynamic>) {
              final DateTime? newDeadline = result['deadline'];
              final RepeatSettings? newRepeatSettings = result['repeatSettings'];
              onDeadlineChanged(newDeadline, newRepeatSettings);
            } else if (result == null) {
              // This handles the case when user clicks "Remove" in the dialog
              onDeadlineChanged(null, null);
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
            color: Colors.white.withOpacity(0.9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRepeatIcon(),
              Icon(
                deadline != null ? Icons.access_time : Icons.add_alarm,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                deadline != null
                    ? _formatDeadline(deadline!)
                    : 'Prazo',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}