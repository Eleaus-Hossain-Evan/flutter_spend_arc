import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> getTransactions();
  Future<Either<Failure, Transaction>> addTransaction(Transaction transaction);
  Future<Either<Failure, Unit>> deleteTransaction(String id);
  Future<Either<Failure, Unit>> syncPendingTransactions();
  Future<Either<Failure, List<Transaction>>> getPendingTransactions();
}
