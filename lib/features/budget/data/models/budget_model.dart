import '../../domain/entities/budget.dart';

class BudgetModel extends Budget {
  @override
  final String id;

  @override
  final double limit;

  @override
  final DateTime month;

  const BudgetModel({
    required this.id,
    required this.limit,
    required this.month,
  }) : super(id: id, limit: limit, month: month);

  factory BudgetModel.fromEntity(Budget budget) {
    return BudgetModel(id: budget.id, limit: budget.limit, month: budget.month);
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      limit: (json['limit'] as num).toDouble(),
      month: DateTime.parse(json['month']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'limit': limit, 'month': month.toIso8601String()};
  }

  @override
  BudgetModel copyWith({String? id, double? limit, DateTime? month}) {
    return BudgetModel(
      id: id ?? this.id,
      limit: limit ?? this.limit,
      month: month ?? this.month,
    );
  }
}
