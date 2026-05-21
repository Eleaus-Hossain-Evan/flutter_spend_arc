import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_datasource.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';
import '../sync/diff_models.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource local;
  final TransactionRemoteDataSource remote;

  TransactionRepositoryImpl({required this.local, required this.remote});

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions() async {
    try {
      // INSTANT local load — never await remote here
      final localData = await local.getAllTransactions();
      final transactions = localData.map((model) => model.toEntity()).toList();
      return Right(transactions);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Transaction>> addTransaction(
    Transaction transaction,
  ) async {
    try {
      // 1. Save locally with isSynced=false
      final model = TransactionModel.fromEntity(
        transaction.copyWith(isSynced: false),
      );
      await local.cacheTransaction(model);

      // 2. Try to push remotely
      try {
        final synced = await remote.pushTransaction(model);
        await local.markSynced(synced.id);
        return Right(synced.toEntity());
      } on NetworkException {
        // stays in write queue (isSynced=false) — will be retried later
        return Right(model.toEntity());
      }
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTransaction(String id) async {
    try {
      await local.deleteTransaction(id);
      try {
        await remote.deleteTransaction(id);
      } on NetworkException {
        // Acceptable — if remote fails, local is already deleted
      }
      return const Right(unit);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> syncPendingTransactions() async {
    try {
      final pending = await local.getPendingTransactions();
      for (final t in pending) {
        try {
          await remote.pushTransaction(t);
          await local.markSynced(t.id);
        } on NetworkException {
          // leave it pending, will retry next time
        }
      }
      return const Right(unit);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getPendingTransactions() async {
    try {
      final localData = await local.getPendingTransactions();
      final transactions = localData.map((model) => model.toEntity()).toList();
      return Right(transactions);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  // Background sync with diffing + isolate
  Future<void> backgroundSync() async {
    try {
      final remoteList = await remote.fetchAll();
      final localList = await local.getAllTransactions();

      // Run diff in isolate — not on main thread
      final delta = await compute(
        _computeDiff,
        DiffInput(remote: remoteList, local: localList),
      );

      for (final t in delta.toAdd) await local.cacheTransaction(t);
      for (final t in delta.toUpdate) await local.cacheTransaction(t);
      for (final id in delta.toDelete) await local.deleteTransaction(id);
    } catch (_) {
      // Background sync failure is silent — user already has local data
    }
  }

  // Top-level function required for compute() - cannot be in class
  static DiffOutput _computeDiff(DiffInput input) {
    final remoteMap = {for (final t in input.remote) t.id: t};
    final localMap = {for (final t in input.local) t.id: t};

    final toAdd = input.remote
        .where((t) => !localMap.containsKey(t.id))
        .toList();
    final toUpdate = input.remote
        .where((t) => localMap.containsKey(t.id) && t != localMap[t.id])
        .toList();
    final toDelete = localMap.keys
        .where((id) => !remoteMap.containsKey(id))
        .toList();

    return DiffOutput(toAdd: toAdd, toUpdate: toUpdate, toDelete: toDelete);
  }
}

extension TransactionModelExtension on TransactionModel {
  Transaction toEntity() {
    return Transaction(
      id: this.id,
      title: title,
      amount: amount,
      category: category,
      date: date,
      isSynced: isSynced,
    );
  }
}
