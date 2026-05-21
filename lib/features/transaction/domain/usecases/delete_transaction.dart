import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/transaction_repository.dart';

class DeleteTransaction implements UseCase<Unit, DeleteTransactionParams> {
  final TransactionRepository repository;

  DeleteTransaction(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteTransactionParams params) =>
      repository.deleteTransaction(params.id);
}

class DeleteTransactionParams extends Equatable {
  final String id;

  const DeleteTransactionParams({required this.id});

  @override
  List<Object?> get props => [id];
}
