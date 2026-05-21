import 'package:hive_ce/hive_ce.dart';

import '../../../../core/error/exceptions.dart';
import '../models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getAllTransactions();
  Future<void> cacheTransaction(TransactionModel model);
  Future<void> deleteTransaction(String id);
  Future<List<TransactionModel>> getPendingTransactions();
  Future<void> markSynced(String id);
  Future<void> replaceAll(List<TransactionModel> models);
  Future<void> clearAll();
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final Box<TransactionModel> box;

  TransactionLocalDataSourceImpl(this.box);

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    try {
      return box.values.toList();
    } catch (e) {
      throw CacheException('Failed to get transactions from local storage');
    }
  }

  @override
  Future<void> cacheTransaction(TransactionModel model) async {
    try {
      await box.put(model.id, model);
    } catch (e) {
      throw CacheException('Failed to cache transaction');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await box.delete(id);
    } catch (e) {
      throw CacheException('Failed to delete transaction');
    }
  }

  @override
  Future<List<TransactionModel>> getPendingTransactions() async {
    try {
      return box.values.where((transaction) => !transaction.isSynced).toList();
    } catch (e) {
      throw CacheException('Failed to get pending transactions');
    }
  }

  @override
  Future<void> markSynced(String id) async {
    try {
      final transaction = box.get(id);
      if (transaction != null) {
        final syncedTransaction = transaction.copyWith(isSynced: true);
        await box.put(id, syncedTransaction);
      }
    } catch (e) {
      throw CacheException('Failed to mark transaction as synced');
    }
  }

  @override
  Future<void> replaceAll(List<TransactionModel> models) async {
    try {
      await box.clear();
      for (final model in models) {
        await box.put(model.id, model);
      }
    } catch (e) {
      throw CacheException('Failed to replace all transactions');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await box.clear();
    } catch (e) {
      throw CacheException('Failed to clear transactions');
    }
  }
}
