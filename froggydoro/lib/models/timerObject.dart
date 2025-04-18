class TimerObject {
  final int id;
  final String name;
  final int workDuration;
  final int breakDuration;
  final int count;
  final int isPicked;

  TimerObject({
    required this.id,
    required this.name,
    required this.workDuration,
    required this.breakDuration,
    this.count = 4,
    this.isPicked = 0,
  });

  TimerObject copyWith({
    int? id,
    String? name,
    int? workDuration,
    int? breakDuration,
    int? count,
  }) {
    return TimerObject(
      id: id ?? this.id,
      name: name ?? this.name,
      workDuration: workDuration ?? this.workDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      count: count ?? this.count,
    );
  }
}
