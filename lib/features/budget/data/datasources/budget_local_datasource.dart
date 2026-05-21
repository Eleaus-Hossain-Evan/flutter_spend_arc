import 'package:hive_ce/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../models/budget_model.dart';

abstract class BudgetLocalDataSource {
  Future<BudgetModel?> getBudget();
  Future<void> cacheBudget(BudgetModel budget);
  Future<void> updateBudgetLimit(double newLimit);
  Future<void> clearAll();
}

class BudgetLocalDataSourceImpl implements BudgetLocalDataSource {
  final Box<BudgetModel> box;

  BudgetLocalDataSourceImpl(this.box);

  @override
  Future<BudgetModel?> getBudget() async {
    try {
      return box.get('current_budget');
    } catch (e) {
      throw CacheException('Failed to get budget from local storage');
    }
  }

  @override
  Future<void> cacheBudget(BudgetModel budget) async {
    try {
      await box.put(budget.id, budget);
    } catch (e) {
      throw CacheException('Failed to cache budget');
    }
  }

  @override
  Future<void> updateBudgetLimit(double newLimit) async {
    try {
      final budget = box.get('current_budget');
      if (budget != null) {
        final updatedBudget = budget.copyWith(limit: newLimit);
        await box.put(budget.id, updatedBudget);
      }
    } catch (e) {
      throw CacheException('Failed to update budget limit');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await box.clear();
    } catch (e) {
      throw CacheException('Failed to clear budget');
    }
  }
}
