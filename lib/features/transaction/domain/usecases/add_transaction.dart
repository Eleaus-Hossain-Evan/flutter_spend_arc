import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../entities/transaction.dart';

class AddTransaction implements UseCase<Transaction, AddTransactionParams> {
  final TransactionRepository repository;

  AddTransaction(this.repository);

  @override
  Future<Either<Failure, Transaction>> call(AddTransactionParams params) =>
      repository.addTransaction(params.transaction);
}

class AddTransactionParams extends Equatable {
  final Transaction transaction;

  const AddTransactionParams({required this.transaction});

  @override
  List<Object?> get props => [transaction];
}
