import 'dart:math';

import '../../../../core/error/exceptions.dart';
import '../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> fetchAll();
  Future<TransactionModel> pushTransaction(TransactionModel model);
  Future<void> deleteTransaction(String id);
  Future<List<TransactionModel>> fetchPendingTransactions();
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  // In-memory store — simulates a server
  static final List<Map<String, dynamic>> _store = [];

  @override
  Future<List<TransactionModel>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 800)); // simulate latency
    return _store.map((j) => TransactionModel.fromJson(j)).toList();
  }

  @override
  Future<TransactionModel> pushTransaction(TransactionModel model) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Simulate 10% failure rate to test rollback
    if (Random().nextInt(10) == 0) {
      throw NetworkException('Simulated network error');
    }

    _store.removeWhere((j) => j['id'] == model.id);
    _store.add(model.toJson());
    return model;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _store.removeWhere((j) => j['id'] == id);
  }

  @override
  Future<List<TransactionModel>> fetchPendingTransactions() async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Simulate getting pending transactions from server
    final pending = _store.where((j) => !(j['isSynced'] ?? false)).toList();
    return pending.map((j) => TransactionModel.fromJson(j)).toList();
  }

  // Helper method for testing - clear the store
  static void clearStore() {
    _store.clear();
  }

  // Helper method for testing - add initial data
  static void addInitialData(List<TransactionModel> transactions) {
    _store.clear();
    for (final transaction in transactions) {
      _store.add(transaction.toJson());
    }
  }
}
