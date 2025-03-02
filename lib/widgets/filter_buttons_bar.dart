import 'package:flutter/material.dart';
import 'hide_long_deadline_button.dart';
import 'toggle_completed_button.dart';

class FilterButtonsBar extends StatelessWidget {
  final bool hideCompleted;
  final bool hideLongDeadlines;
  final VoidCallback onToggleCompleted;
  final VoidCallback onToggleLongDeadlines;

  const FilterButtonsBar({
    Key? key,
    required this.hideCompleted,
    required this.hideLongDeadlines,
    required this.onToggleCompleted,
    required this.onToggleLongDeadlines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        HideLongDeadlineButton(
          hideLongDeadlines: hideLongDeadlines,
          onToggle: onToggleLongDeadlines,
          color: Colors.green[700]!,
        ),
        const SizedBox(width: 16),
        ToggleCompletedButton(
          hideCompleted: hideCompleted,
          onToggle: onToggleCompleted,
          color: Colors.blue[700]!,
        ),
      ],
    );
  }
}
