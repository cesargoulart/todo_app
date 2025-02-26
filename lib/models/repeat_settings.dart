// In a new file: lib/models/repeat_settings.dart
import 'repeat_option.dart';

class RepeatSettings {
  final RepeatOption option;
  final List<int>? selectedDays;  // For weekly repetition
  final int? repeatCount;         // Number of times to repeat (null = forever)
  final DateTime? endDate;        // Date after which to stop repeating (null = no end date)
  
  const RepeatSettings({
    required this.option,
    this.selectedDays,
    this.repeatCount,
    this.endDate,
  });
  
  // Convenience constructor for non-repeating tasks
  factory RepeatSettings.never() {
    return RepeatSettings(option: RepeatOption.never);
  }
  
  // Convert to/from JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'option': option.toJson(),
      'selectedDays': selectedDays,
      'repeatCount': repeatCount,
      'endDate': endDate?.toIso8601String(),
    };
  }
  
  factory RepeatSettings.fromJson(Map<String, dynamic> json) {
    return RepeatSettings(
      option: RepeatOption.fromJson(json['option']),
      selectedDays: json['selectedDays'] != null ? List<int>.from(json['selectedDays']) : null,
      repeatCount: json['repeatCount'],
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }
}