import 'package:flutter/material.dart';
import '../models/repeat_option.dart';

class DeadlinePickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final RepeatOption? initialRepeatOption;

  const DeadlinePickerDialog({
    Key? key,
    this.initialDate,
    this.initialRepeatOption,
  }) : super(key: key);

  @override
  State<DeadlinePickerDialog> createState() => _DeadlinePickerDialogState();
}

class _DeadlinePickerDialogState extends State<DeadlinePickerDialog> {
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late RepeatOption selectedRepeatOption;

  @override
  void initState() {
    super.initState();
    // Ensure the initial date is not before now
    final now = DateTime.now();
    selectedDate = widget.initialDate?.isBefore(now) ?? true 
        ? now 
        : widget.initialDate!.toLocal();
    selectedTime = TimeOfDay.fromDateTime(selectedDate);
    selectedRepeatOption = widget.initialRepeatOption ?? RepeatOption.never;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecionar Prazo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: CalendarDatePicker(
                    initialDate: selectedDate.isBefore(now) ? now : selectedDate,
                    firstDate: now,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    onDateChanged: (date) {
                      setState(() {
                        selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.repeat),
                  title: DropdownButton<RepeatOption>(
                    value: selectedRepeatOption,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: RepeatOption.values.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option.displayName),
                      );
                    }).toList(),
                    onChanged: (RepeatOption? value) {
                      if (value != null) {
                        setState(() {
                          selectedRepeatOption = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(selectedTime.format(context)),
                  onTap: () async {
                    final TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = time;
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 32,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancelar', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 32,
                      child: TextButton(
                        onPressed: widget.initialDate != null ? () {
                          Navigator.of(context).pop(null); // Remove deadline
                        } : null,
                        child: const Text('Remover', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 32,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () {
                          final deadline = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          Navigator.of(context).pop({
                            'deadline': deadline,
                            'repeatOption': selectedRepeatOption,
                          });
                        },
                        child: const Text('Confirmar', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
