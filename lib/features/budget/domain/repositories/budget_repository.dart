import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/budget.dart';

abstract class BudgetRepository {
  Future<Either<Failure, Budget>> getBudget();
  Future<Either<Failure, Unit>> setBudget(Budget budget);
  Future<Either<Failure, Unit>> updateBudgetLimit(double newLimit);
}
