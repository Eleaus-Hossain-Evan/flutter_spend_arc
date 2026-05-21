import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../entities/transaction.dart';

class DeleteTransaction implements UseCase<Unit, DeleteTransactionParams> {
  final TransactionRepository repository;

  DeleteTransaction(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteTransactionParams params) =>
      repository.deleteTransaction(params.id);
}

class SyncTransactions implements UseCase<Unit, NoParams> {
  final TransactionRepository repository;

  SyncTransactions(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      repository.syncPendingTransactions();
}

class GetPendingTransactions implements UseCase<List<Transaction>, NoParams> {
  final TransactionRepository repository;

  GetPendingTransactions(this.repository);

  @override
  Future<Either<Failure, List<Transaction>>> call(NoParams params) =>
      repository.getPendingTransactions();
}

class DeleteTransactionParams extends Equatable {
  final String id;

  const DeleteTransactionParams({required this.id});

  @override
  List<Object?> get props => [id];
}
