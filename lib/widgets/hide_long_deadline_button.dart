import 'package:flutter/material.dart';

class HideLongDeadlineButton extends StatefulWidget {
  final bool hideLongDeadlines;
  final VoidCallback onToggle;
  final Color color;

  const HideLongDeadlineButton({
    Key? key,
    required this.hideLongDeadlines,
    required this.onToggle,
    required this.color,
  }) : super(key: key);

  @override
  State<HideLongDeadlineButton> createState() => _HideLongDeadlineButtonState();
}

class _HideLongDeadlineButtonState extends State<HideLongDeadlineButton> {
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
            widget.hideLongDeadlines ? Icons.visibility_off : Icons.visibility,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}