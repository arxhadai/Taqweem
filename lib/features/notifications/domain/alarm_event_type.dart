enum AlarmEventType {
  prayer,
  sehriStart,
  iftarStart,
  sehriReminder,
  iftarReminder,
}

extension AlarmEventTypeX on AlarmEventType {
  String get name {
    return toString().split('.').last;
  }

  static AlarmEventType fromName(String name) {
    return AlarmEventType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AlarmEventType.prayer,
    );
  }
}
