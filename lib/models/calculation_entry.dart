import 'package:hive/hive.dart';

part 'calculation_entry.g.dart';

@HiveType(typeId: 0)
class CalculationEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String rawTranscript;

  @HiveField(2)
  final String expression;

  @HiveField(3)
  final String result;

  @HiveField(4)
  final DateTime timestamp;

  CalculationEntry({
    required this.id,
    required this.rawTranscript,
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[timestamp.month - 1]} ${timestamp.day}';
  }
}
