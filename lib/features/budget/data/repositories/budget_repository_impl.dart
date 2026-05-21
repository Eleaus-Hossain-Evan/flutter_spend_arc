import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_local_datasource.dart';
import '../datasources/budget_remote_datasource.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetLocalDataSource local;
  final BudgetRemoteDataSource remote;

  BudgetRepositoryImpl({required this.local, required this.remote});

  @override
  Future<Either<Failure, Budget>> getBudget() async {
    try {
      // Try to get from local first for instant load
      var budget = await local.getBudget();

      if (budget == null) {
        // If not in local, try remote
        budget = await remote.fetchBudget();
        if (budget != null) {
          await local.cacheBudget(budget);
        }
      }

      if (budget == null) {
        return Left(NotFoundFailure('Budget not found'));
      }

      return Right(budget.toEntity());
    } on CacheException {
      return Left(CacheFailure());
    } on NetworkException {
      // If remote fails, try to return cached version
      try {
        final cachedBudget = await local.getBudget();
        if (cachedBudget != null) {
          return Right(cachedBudget.toEntity());
        }
        return Left(NotFoundFailure('Budget not found'));
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, Unit>> setBudget(Budget budget) async {
    try {
      final model = BudgetModel.fromEntity(budget);

      // Save locally first
      await local.cacheBudget(model);

      // Try to push remotely
      try {
        await remote.pushBudget(model);
      } on NetworkException {
        // Remote failed, but local is saved - will sync later
      }

      return const Right(unit);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> updateBudgetLimit(double newLimit) async {
    try {
      // Update locally first
      await local.updateBudgetLimit(newLimit);

      // Try to push remotely
      try {
        await remote.updateBudgetLimit('current_budget', newLimit);
      } on NetworkException {
        // Remote failed, but local is updated - will sync later
      }

      return const Right(unit);
    } on CacheException {
      return Left(CacheFailure());
    } on NotFoundException {
      return Left(NotFoundFailure('Budget not found'));
    }
  }
}

extension BudgetModelExtension on BudgetModel {
  Budget toEntity() {
    return Budget(id: this.id, limit: limit, month: month);
  }
}
