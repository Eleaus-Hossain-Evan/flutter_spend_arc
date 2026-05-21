import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

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

class SetBudget implements UseCase<Unit, SetBudgetParams> {
  final BudgetRepository repository;

  SetBudget(this.repository);

  @override
  Future<Either<Failure, Unit>> call(SetBudgetParams params) =>
      repository.setBudget(params.budget);
}

class UpdateBudgetLimit implements UseCase<Unit, UpdateBudgetLimitParams> {
  final BudgetRepository repository;

  UpdateBudgetLimit(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateBudgetLimitParams params) =>
      repository.updateBudgetLimit(params.newLimit);
}

class SetBudgetParams extends Equatable {
  final Budget budget;

  const SetBudgetParams({required this.budget});

  @override
  List<Object?> get props => [budget];
}

class UpdateBudgetLimitParams extends Equatable {
  final double newLimit;

  const UpdateBudgetLimitParams({required this.newLimit});

  @override
  List<Object?> get props => [newLimit];
}
