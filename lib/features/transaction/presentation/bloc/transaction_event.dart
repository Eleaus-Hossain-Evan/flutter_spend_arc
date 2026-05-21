import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
}

class LoadTransactions extends TransactionEvent {
  const LoadTransactions();

  @override
  List<Object?> get props => [];
}

class AddTransactionEvent extends TransactionEvent {
  final Transaction transaction;

  const AddTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteTransactionEvent extends TransactionEvent {
  final String id;

  const DeleteTransactionEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class SyncTransactions extends TransactionEvent {
  const SyncTransactions();

  @override
  List<Object?> get props => [];
}
