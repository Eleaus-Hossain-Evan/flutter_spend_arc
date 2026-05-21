import 'package:equatable/equatable.dart';

import '../../../transaction/domain/entities/transaction.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();
}

class LoadBudget extends BudgetEvent {
  const LoadBudget();

  @override
  List<Object?> get props => [];
}

class RecalculateBudget extends BudgetEvent {
  final List<Transaction> transactions;

  const RecalculateBudget(this.transactions);

  @override
  List<Object?> get props => [transactions];
}
