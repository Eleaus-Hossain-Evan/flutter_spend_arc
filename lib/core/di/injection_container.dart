import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../features/budget/data/datasources/budget_local_datasource.dart';
import '../../features/budget/data/datasources/budget_remote_datasource.dart';
import '../../features/budget/data/models/budget_model.dart';
import '../../features/budget/data/repositories/budget_repository_impl.dart';
import '../../features/budget/domain/repositories/budget_repository.dart';
import '../../features/budget/domain/usecases/get_budget.dart';
import '../../features/budget/domain/usecases/set_budget.dart';
import '../../features/budget/presentation/bloc/budget_bloc.dart';
import '../../features/transaction/data/datasources/transaction_local_datasource.dart';
import '../../features/transaction/data/datasources/transaction_remote_datasource.dart';
import '../../features/transaction/data/models/transaction_model.dart';
import '../../features/transaction/data/repositories/transaction_repository_impl.dart';
import '../../features/transaction/domain/repositories/transaction_repository.dart';
import '../../features/transaction/domain/usecases/add_transaction.dart';
import '../../features/transaction/domain/usecases/delete_transaction.dart';
import '../../features/transaction/domain/usecases/get_pending_transactions.dart';
import '../../features/transaction/domain/usecases/get_transactions.dart';
import '../../features/transaction/domain/usecases/sync_transactions.dart';
import '../../features/transaction/presentation/bloc/transaction_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── External ──────────────────────────────────────────
  final transactionBox = await Hive.openBox<TransactionModel>('transactions');
  final budgetBox = await Hive.openBox<BudgetModel>('budget');

  sl.registerLazySingleton<Box<TransactionModel>>(() => transactionBox);
  sl.registerLazySingleton<Box<BudgetModel>>(() => budgetBox);

  // ── Data sources ──────────────────────────────────────
  sl.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImpl(sl<Box<TransactionModel>>()),
  );
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<BudgetLocalDataSource>(
    () => BudgetLocalDataSourceImpl(sl<Box<BudgetModel>>()),
  );
  sl.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSourceImpl(),
  );

  // ── Repositories ──────────────────────────────────────
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      local: sl<TransactionLocalDataSource>(),
      remote: sl<TransactionRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      local: sl<BudgetLocalDataSource>(),
      remote: sl<BudgetRemoteDataSource>(),
    ),
  );

  // ── Use cases ─────────────────────────────────────────
  sl.registerLazySingleton(() => GetTransactions(sl<TransactionRepository>()));
  sl.registerLazySingleton(() => AddTransaction(sl<TransactionRepository>()));
  sl.registerLazySingleton(
    () => DeleteTransaction(sl<TransactionRepository>()),
  );
  sl.registerLazySingleton(() => SyncTransactions(sl<TransactionRepository>()));
  sl.registerLazySingleton(
    () => GetPendingTransactions(sl<TransactionRepository>()),
  );
  sl.registerLazySingleton(() => GetBudget(sl<BudgetRepository>()));
  sl.registerLazySingleton(() => SetBudget(sl<BudgetRepository>()));

  // ── BLoCs ─────────────────────────────────────────────
  // Use registerFactory so each BLoC gets a fresh instance per page
  sl.registerFactory(
    () => TransactionBloc(
      getTransactions: sl(),
      addTransaction: sl(),
      deleteTransaction: sl(),
      syncTransactions: sl(),
    ),
  );
  sl.registerFactory(
    () => BudgetBloc(
      getBudget: sl(),
      setBudget: sl(),
      transactionStream: sl<TransactionBloc>().stream,
    ),
  );
}
