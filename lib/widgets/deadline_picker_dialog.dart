import 'package:flutter/material.dart';
import '../models/repeat_option.dart';
import '../models/repeat_settings.dart';

class DeadlinePickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final RepeatSettings? initialRepeatSettings;

  const DeadlinePickerDialog({
    Key? key,
    this.initialDate,
    this.initialRepeatSettings,
  }) : super(key: key);

  @override
  State<DeadlinePickerDialog> createState() => _DeadlinePickerDialogState();
}

class _DeadlinePickerDialogState extends State<DeadlinePickerDialog> {
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late RepeatOption selectedRepeatOption;
  final Set<int> selectedDays = <int>{};
  int? repeatCount;
  DateTime? endDate;
  bool showAdvancedOptions = false;

  final List<String> weekDays = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom'
  ];

  @override
  void initState() {
    super.initState();
    // Ensure the initial date is not before now
    final now = DateTime.now();
    selectedDate = widget.initialDate?.isBefore(now) ?? true
        ? now
        : widget.initialDate!.toLocal();
    selectedTime = TimeOfDay.fromDateTime(selectedDate);

    // Initialize from repeat settings if provided
    if (widget.initialRepeatSettings != null) {
      selectedRepeatOption = widget.initialRepeatSettings!.option;
      if (widget.initialRepeatSettings!.selectedDays != null) {
        selectedDays.addAll(widget.initialRepeatSettings!.selectedDays!);
      }
      repeatCount = widget.initialRepeatSettings!.repeatCount;
      endDate = widget.initialRepeatSettings!.endDate;
      showAdvancedOptions = selectedRepeatOption != RepeatOption.never;
    } else {
      selectedRepeatOption = RepeatOption.never;
    }
  }

  // Helper method to show a number picker dialog
  Future<void> _showNumberPickerDialog() async {
    int value = repeatCount ?? 1;

    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Quantas vezes repetir?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed:
                          value > 1 ? () => setState(() => value--) : null,
                    ),
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      child: Text(
                        value.toString(),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed:
                          value < 100 ? () => setState(() => value++) : null,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(value),
                child: const Text('OK'),
              ),
            ],
          );
        });
      },
    );

    if (result != null) {
      setState(() {
        repeatCount = result;
        // If we set a repeat count, clear the end date
        if (result > 0) {
          endDate = null;
        }
      });
    }
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
                    initialDate:
                        selectedDate.isBefore(now) ? now : selectedDate,
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

                // Repetition options
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
                          if (value != RepeatOption.weekly) {
                            selectedDays.clear();
                          } else if (selectedDays.isEmpty) {
                            // If switching to weekly and no days selected, select the current day
                            selectedDays.add(selectedDate.weekday);
                          }

                          // Show advanced options if repeating
                          showAdvancedOptions = value != RepeatOption.never;
                        });
                      }
                    },
                  ),
                ),

                // Weekly day selection
                if (selectedRepeatOption == RepeatOption.weekly)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Repetir nestes dias:',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(7, (index) {
                            final dayNumber = index + 1;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selectedDays.contains(dayNumber)) {
                                    selectedDays.remove(dayNumber);
                                  } else {
                                    selectedDays.add(dayNumber);
                                  }
                                });
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selectedDays.contains(dayNumber)
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.withOpacity(0.2),
                                ),
                                child: Center(
                                  child: Text(
                                    weekDays[index],
                                    style: TextStyle(
                                      color: selectedDays.contains(dayNumber)
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                // Time picker
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

                // Advanced repetition options
                if (showAdvancedOptions &&
                    selectedRepeatOption != RepeatOption.never)
                  ExpansionTile(
                    title: const Text('Opções Avançadas de Repetição',
                        style: TextStyle(fontSize: 14)),
                    children: [
                      // Repeat count option
                      ListTile(
                        title: const Text('Repetir quantas vezes?'),
                        subtitle: repeatCount == null
                            ? const Text('Sempre')
                            : Text('$repeatCount vezes'),
                        trailing: const Icon(Icons.edit),
                        onTap: _showNumberPickerDialog,
                      ),

                      // End date option
                      ListTile(
                        title: const Text('Data final'),
                        subtitle: endDate == null
                            ? const Text('Sem data final')
                            : Text(
                                'Termina em ${endDate!.toLocal().toString().split(' ')[0]}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: endDate ??
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 5)),
                          );

                          if (pickedDate != null) {
                            setState(() {
                              endDate = pickedDate;
                              // If we set an end date, clear the repeat count
                              repeatCount = null;
                            });
                          }
                        },
                      ),

                      // Clear limitations button
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              repeatCount = null;
                              endDate = null;
                            });
                          },
                          child: const Text('Limpar Limitações'),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 32,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancelar',
                            style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 32,
                      child: TextButton(
                        onPressed: widget.initialDate != null
                            ? () {
                                Navigator.of(context)
                                    .pop(null); // Remove deadline
                              }
                            : null,
                        child: const Text('Remover',
                            style: TextStyle(fontSize: 14)),
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

                          // Create RepeatSettings object
                          final settings = RepeatSettings(
                            option: selectedRepeatOption,
                            selectedDays: selectedRepeatOption ==
                                    RepeatOption.weekly
                                ? () {
                                    final sortedList = selectedDays.toList();
                                    sortedList.sort();
                                    return sortedList;
                                  }()
                                : null,
                            repeatCount: repeatCount,
                            endDate: endDate,
                          );

                          Navigator.of(context).pop({
                            'deadline': deadline,
                            'repeatSettings': settings,
                          });
                        },
                        child: const Text('Confirmar',
                            style: TextStyle(fontSize: 14)),
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
