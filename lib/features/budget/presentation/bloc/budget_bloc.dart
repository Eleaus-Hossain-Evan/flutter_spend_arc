import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../transaction/presentation/bloc/transaction_state.dart';
import '../../domain/usecases/get_budget.dart';
import '../../domain/usecases/set_budget.dart';
import 'budget_event.dart';
import 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final GetBudget getBudget;
  final SetBudget setBudget;
  late final StreamSubscription<TransactionState> _transactionSubscription;

  BudgetBloc({
    required this.getBudget,
    required this.setBudget,
    required Stream<TransactionState> transactionStream,
  }) : super(const BudgetInitial()) {
    on<LoadBudget>(_onLoad);
    on<RecalculateBudget>(_onRecalculate);

    _transactionSubscription = transactionStream.listen((transactionState) {
      if (transactionState is TransactionLoaded) {
        add(RecalculateBudget(transactionState.transactions));
      }
    });
  }

  Future<void> _onLoad(LoadBudget event, Emitter emit) async {
    emit(const BudgetLoading());
    final result = await getBudget(const NoParams());
    result.fold(
      (failure) => emit(BudgetError(_mapFailure(failure))),
      (budget) => emit(BudgetLoaded(budget: budget, spent: 0)),
    );
  }

  void _onRecalculate(RecalculateBudget event, Emitter emit) {
    final currentState = state;
    if (currentState is! BudgetLoaded) return;

    final now = DateTime.now();
    final spent = event.transactions
        .where(
          (t) => t.date.month == now.month && t.date.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    emit(currentState.copyWith(spent: spent));
  }

  String _mapFailure(Object failure) {
    return failure.toString();
  }

  @override
  Future<void> close() {
    _transactionSubscription.cancel();
    return super.close();
  }
}
