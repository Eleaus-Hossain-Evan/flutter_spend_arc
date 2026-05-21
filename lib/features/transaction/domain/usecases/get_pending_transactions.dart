import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../entities/transaction.dart';

class GetPendingTransactions implements UseCase<List<Transaction>, NoParams> {
  final TransactionRepository repository;

  GetPendingTransactions(this.repository);

  @override
  Future<Either<Failure, List<Transaction>>> call(NoParams params) =>
      repository.getPendingTransactions();
}
