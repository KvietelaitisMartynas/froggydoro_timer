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
}
