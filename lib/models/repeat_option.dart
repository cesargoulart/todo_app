enum RepeatOption {
  never,
  daily,
  weekly,
  monthly;

  String get displayName {
    switch (this) {
      case RepeatOption.never:
        return 'Não repetir';
      case RepeatOption.daily:
        return 'Diariamente';
      case RepeatOption.weekly:
        return 'Semanalmente';
      case RepeatOption.monthly:
        return 'Mensalmente';
    }
  }

  String toJson() => name;
  
  static RepeatOption fromJson(String json) {
    return RepeatOption.values.firstWhere(
      (option) => option.name == json,
      orElse: () => RepeatOption.never,
    );
  }
}
