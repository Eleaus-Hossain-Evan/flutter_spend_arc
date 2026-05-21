import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  final String id;
  final double limit;
  final DateTime month;

  const Budget({
    required this.id,
    required this.limit,
    required this.month,
  });

  Budget copyWith({
    String? id,
    double? limit,
    DateTime? month,
  }) {
    return Budget(
      id: id ?? this.id,
      limit: limit ?? this.limit,
      month: month ?? this.month,
    );
  }

  String get formattedLimit {
    return '\$${limit.toStringAsFixed(2)}';
  }

  String get formattedMonth {
    return '${month.month}/${month.year}';
  }

  bool get isValid => limit > 0;

  static Budget createDefault() {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month, 1);
    return Budget(
      id: 'current_budget',
      limit: 10000.0, // Default budget
      month: month,
    );
  }

  @override
  List<Object?> get props => [id, limit, month];
}