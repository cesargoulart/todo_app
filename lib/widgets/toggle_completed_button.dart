import 'package:flutter/material.dart';

class ToggleCompletedButton extends StatefulWidget {
  final bool hideCompleted;
  final VoidCallback onToggle;
  final Color color;

  const ToggleCompletedButton({
    Key? key,
    required this.hideCompleted,
    required this.onToggle,
    required this.color,
  }) : super(key: key);

  @override
  State<ToggleCompletedButton> createState() => _ToggleCompletedButtonState();
}

class _ToggleCompletedButtonState extends State<ToggleCompletedButton> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(24), // Half of size for a circle
        onTap: widget.onToggle,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color, width: 2),
          ),
          child: Icon(
            widget.hideCompleted ? Icons.visibility : Icons.visibility_off,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}