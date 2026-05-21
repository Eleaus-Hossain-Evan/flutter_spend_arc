import 'dart:math';

import '../../../../core/error/exceptions.dart';
import '../models/budget_model.dart';

abstract class BudgetRemoteDataSource {
  Future<BudgetModel?> fetchBudget();
  Future<BudgetModel> pushBudget(BudgetModel budget);
  Future<void> updateBudgetLimit(String id, double newLimit);
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  // In-memory store — simulates a server
  static final Map<String, Map<String, dynamic>> _store = {};

  @override
  Future<BudgetModel?> fetchBudget() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final budgetData = _store['current_budget'];
    if (budgetData != null) {
      return BudgetModel.fromJson(budgetData);
    }
    return null;
  }

  @override
  Future<BudgetModel> pushBudget(BudgetModel budget) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Simulate 5% failure rate
    if (Random().nextInt(20) == 0) {
      throw NetworkException('Simulated network error');
    }

    _store[budget.id] = budget.toJson();
    return budget;
  }

  @override
  Future<void> updateBudgetLimit(String id, double newLimit) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final budgetData = _store[id];
    if (budgetData != null) {
      _store[id] = {...budgetData, 'limit': newLimit};
    } else {
      throw NotFoundException('Budget not found');
    }
  }

  // Helper method for testing - clear the store
  static void clearStore() {
    _store.clear();
  }

  // Helper method for testing - add initial data
  static void addInitialBudget(BudgetModel budget) {
    _store[budget.id] = budget.toJson();
  }
}
