import 'package:flutter/material.dart';

class HideOverdueButton extends StatefulWidget {
  final bool hideOverdue;
  final VoidCallback onToggleOverdue;

  const HideOverdueButton({
    Key? key,
    required this.hideOverdue,
    required this.onToggleOverdue,
  }) : super(key: key);

  @override
  State<HideOverdueButton> createState() => _HideOverdueButtonState();
}

class _HideOverdueButtonState extends State<HideOverdueButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.onToggleOverdue,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.hideOverdue ? Icons.visibility_off : Icons.visibility),
          const SizedBox(width: 8),
          Text(widget.hideOverdue ? 'Show Overdue' : 'Hide Overdue'),
        ],
      ),
    );
  }
}