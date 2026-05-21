import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/budget_repository.dart';
import '../entities/budget.dart';

class GetBudget implements UseCase<Budget, NoParams> {
  final BudgetRepository repository;

  GetBudget(this.repository);

  @override
  Future<Either<Failure, Budget>> call(NoParams params) =>
      repository.getBudget();
}

