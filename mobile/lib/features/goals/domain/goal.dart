class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.progressPercent,
  });

  final int id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final double progressPercent;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as int,
      name: json['name'] as String,
      targetAmount: double.parse(json['target_amount'].toString()),
      currentAmount: double.parse(json['current_amount'].toString()),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      progressPercent: double.parse(json['progress_percent'].toString()),
    );
  }
}
