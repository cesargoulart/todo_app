import 'package:flutter/material.dart';

class HideOverdueButton extends StatefulWidget {
  final bool hideOverdue;
  final VoidCallback onToggleOverdue;
  final Color color;

  const HideOverdueButton({
    Key? key,
    required this.hideOverdue,
    required this.onToggleOverdue,
    required this.color,
  }) : super(key: key);

  @override
  State<HideOverdueButton> createState() => _HideOverdueButtonState();
}

class _HideOverdueButtonState extends State<HideOverdueButton> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(24), // Half of size for a circle
        onTap: widget.onToggleOverdue,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color, width: 2),
          ),
          child: Icon(
            widget.hideOverdue ? Icons.visibility_off : Icons.visibility,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}