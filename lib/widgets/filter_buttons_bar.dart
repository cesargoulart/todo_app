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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          HideLongDeadlineButton(
            hideLongDeadlines: hideLongDeadlines,
            onToggle: onToggleLongDeadlines,
          ),
          ToggleCompletedButton(
            hideCompleted: hideCompleted,
            onToggle: onToggleCompleted,
          ),
        ],
      ),
    );
  }
}
