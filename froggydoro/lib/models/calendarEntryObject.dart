class CalendarEntryObject {
  final int id;
  final DateTime date;
  final int duration;
  final String type;
  final String status;

  CalendarEntryObject({
    required this.id,
    required this.date,
    required this.duration,
    required this.type,
    required this.status,
  });

  CalendarEntryObject copyWith({
    int? id,
    DateTime? date,
    int? duration,
    String? type,
    String? status,
  }) {
    return CalendarEntryObject(
      id: id ?? this.id,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }
}
