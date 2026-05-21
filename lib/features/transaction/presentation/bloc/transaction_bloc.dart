import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/sync_transactions.dart' as sync_use_case;
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactions getTransactions;
  final AddTransaction addTransaction;
  final DeleteTransaction deleteTransaction;
  final sync_use_case.SyncTransactions syncTransactions;

  TransactionBloc({
    required this.getTransactions,
    required this.addTransaction,
    required this.deleteTransaction,
    required this.syncTransactions,
  }) : super(const TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
    on<AddTransactionEvent>(_onAdd);
    on<DeleteTransactionEvent>(_onDelete);
    on<SyncTransactions>(_onSync);
  }

  Future<void> _onLoad(LoadTransactions event, Emitter emit) async {
    emit(const TransactionLoading());
    final result = await getTransactions(const NoParams());
    result.fold(
      (failure) => emit(TransactionError(_mapFailure(failure))),
      (transactions) => emit(TransactionLoaded(transactions)),
    );
  }

  Future<void> _onAdd(AddTransactionEvent event, Emitter emit) async {
    final currentState = state;
    if (currentState is! TransactionLoaded) return;

    final optimisticList = [event.transaction, ...currentState.transactions];
    emit(TransactionLoaded(optimisticList));

    final result = await addTransaction(
      AddTransactionParams(transaction: event.transaction),
    );
    result.fold(
      (failure) => emit(TransactionLoaded(currentState.transactions)),
      (saved) {
        final updated = optimisticList
            .map((t) => t.id == saved.id ? saved : t)
            .toList();
        emit(TransactionLoaded(updated));
      },
    );
  }

  Future<void> _onDelete(DeleteTransactionEvent event, Emitter emit) async {
    final currentState = state;
    if (currentState is! TransactionLoaded) return;

    final previousList = currentState.transactions;
    emit(
      TransactionLoaded(
        previousList.where((t) => t.id != event.id).toList(),
      ),
    );

    final result = await deleteTransaction(
      DeleteTransactionParams(id: event.id),
    );
    result.fold(
      (failure) => emit(TransactionLoaded(previousList)),
      (_) {},
    );
  }

  Future<void> _onSync(SyncTransactions event, Emitter emit) async {
    final result = await syncTransactions(const NoParams());
    result.fold(
      (failure) => null,
      (_) => add(const LoadTransactions()),
    );
  }

  String _mapFailure(Object failure) {
    return failure.toString();
  }
}
