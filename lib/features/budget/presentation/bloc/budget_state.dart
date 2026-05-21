import 'package:equatable/equatable.dart';

import '../../domain/entities/budget.dart';

abstract class BudgetState extends Equatable {
  const BudgetState();
}

class BudgetInitial extends BudgetState {
  const BudgetInitial();

  @override
  List<Object?> get props => [];
}

class BudgetLoading extends BudgetState {
  const BudgetLoading();

  @override
  List<Object?> get props => [];
}

class BudgetLoaded extends BudgetState {
  final Budget budget;
  final double spent;

  const BudgetLoaded({
    required this.budget,
    required this.spent,
  });

  double get remaining => budget.limit - spent;
  double get percentage => (spent / budget.limit).clamp(0.0, 1.0);
  bool get isUnderBudget => spent < budget.limit;

  BudgetLoaded copyWith({double? spent}) {
    return BudgetLoaded(
      budget: budget,
      spent: spent ?? this.spent,
    );
  }

  @override
  List<Object?> get props => [budget, spent];
}

class BudgetError extends BudgetState {
  final String message;

  const BudgetError(this.message);

  @override
  List<Object?> get props => [message];
}
