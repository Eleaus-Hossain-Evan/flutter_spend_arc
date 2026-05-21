import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/transaction_repository.dart';

class SyncTransactions implements UseCase<Unit, NoParams> {
  final TransactionRepository repository;

  SyncTransactions(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      repository.syncPendingTransactions();
}
