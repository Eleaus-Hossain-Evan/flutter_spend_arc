# SpendArc — Flutter Assessment PRD
**Project:** Senior Flutter Developer Assessment — Taghyeer Technologies  
**Time Budget:** 5 hours  
**Total Points:** 100 pts  

---

## Table of Contents
1. [App Overview](#1-app-overview)
2. [Data Models](#2-data-models)
3. [Folder Structure](#3-folder-structure)
4. [Step-by-Step Build Plan](#4-step-by-step-build-plan)
   - Phase 0 — Project Bootstrap
   - Phase 1 — Domain Layer (Clean Architecture core)
   - Phase 2 — Data Layer (Local + Fake Remote)
   - Phase 3 — DI Wiring (get_it)
   - Phase 4 — BLoC Layer
   - Phase 5 — UI Screens
   - Phase 6 — Custom Animations
   - Phase 7 — Offline-First + Write Queue
   - Phase 8 — Tests
   - Phase 9 — Polish & Bonus
5. [Decision Reference](#5-decision-reference)
6. [Verbal Interview Cheatsheet](#6-verbal-interview-cheatsheet)

---

## 1. App Overview

**SpendArc** is a personal finance tracker. Users add spending transactions, set a monthly budget, and see visual feedback via an animated arc meter and line chart.

### Screens (3 total)

| Screen | Route | Purpose |
|--------|-------|---------|
| Dashboard | `/` | Arc meter + line chart + particle burst |
| Transactions | `/transactions` | Scrollable list, swipe-to-delete |
| Add Transaction | `/add` (bottom sheet) | Form to add a new transaction |

### Core Concepts

| Concept | Description |
|---------|-------------|
| **Transaction** | A single spending entry: title, amount, category, date |
| **Budget** | A monthly spending limit set by the user |
| **Sync State** | Each transaction can be `synced` or `pending` (queued for upload) |

---

## 2. Data Models

### Transaction Entity (Domain layer — pure Dart)
```
id:         String        — UUID
title:      String        — e.g. "Lunch at Bashundhara"
amount:     double        — e.g. 450.0
category:   String        — Food | Transport | Bills | Shopping | Other
date:       DateTime
isSynced:   bool          — false = pending in write queue
```

### Budget Entity (Domain layer — pure Dart)
```
id:         String        — fixed value "current_budget"
limit:      double        — monthly spending cap, e.g. 20000.0
month:      DateTime      — first day of the tracked month
```

### TransactionModel (Data layer — extends/maps from Entity)
- Adds `toJson()` / `fromJson()` for fake remote
- Adds `toHive()` / `fromHive()` for local storage

### BudgetModel (Data layer)
- Same pattern as TransactionModel

---

## 3. Folder Structure

```
lib/
├── core/
│   ├── error/
│   │   ├── failures.dart          — Failure sealed class hierarchy
│   │   └── exceptions.dart        — Raw exceptions (cache, network)
│   ├── usecases/
│   │   └── usecase.dart           — abstract UseCase<Type, Params> interface
│   └── di/
│       └── injection_container.dart  — get_it setup
│
├── features/
│   ├── transaction/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── transaction.dart
│   │   │   ├── repositories/
│   │   │   │   └── transaction_repository.dart   — abstract
│   │   │   └── usecases/
│   │   │       ├── get_transactions.dart
│   │   │       ├── add_transaction.dart
│   │   │       └── delete_transaction.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── transaction_model.dart
│   │   │   ├── datasources/
│   │   │   │   ├── transaction_local_datasource.dart
│   │   │   │   └── transaction_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── transaction_repository_impl.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── transaction_bloc.dart
│   │       │   ├── transaction_event.dart
│   │       │   └── transaction_state.dart
│   │       ├── pages/
│   │       │   ├── transaction_list_page.dart
│   │       │   └── add_transaction_page.dart
│   │       └── widgets/
│   │           ├── transaction_list_item.dart
│   │           └── swipe_delete_item.dart
│   │
│   ├── budget/
│   │   ├── domain/
│   │   │   ├── entities/budget.dart
│   │   │   ├── repositories/budget_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_budget.dart
│   │   │       └── set_budget.dart
│   │   ├── data/  (same pattern)
│   │   └── presentation/
│   │       └── bloc/
│   │           ├── budget_bloc.dart
│   │           ├── budget_event.dart
│   │           └── budget_state.dart
│   │
│   └── dashboard/
│       └── presentation/
│           ├── pages/
│           │   └── dashboard_page.dart
│           └── widgets/
│               ├── arc_meter_painter.dart
│               ├── spending_line_chart_painter.dart
│               └── particle_burst_overlay.dart
│
└── main.dart
```

---

## 4. Step-by-Step Build Plan

Each phase is independently completable. Check off as you go.

---

### Phase 0 — Project Bootstrap
**Time estimate: 15 min**  
**Module coverage: All**

#### Step 0.1 — Create project & add dependencies
```yaml
# pubspec.yaml
dependencies:
  flutter_bloc: ^8.1.6
  get_it: ^8.0.2
  dartz: ^0.10.1
  equatable: ^2.0.5
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  uuid: ^4.4.0
  connectivity_plus: ^6.0.3

dev_dependencies:
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
  hive_generator: ^2.0.1
  build_runner: ^2.4.9
  flutter_test:
    sdk: flutter
```

**Decision:** Use Hive (not sqflite). Reason: no SQL schema migrations needed, simpler API for this scope, and Hive boxes work well with isolates.

#### Step 0.2 — Initialize Hive in main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<BudgetModel>('budget');
  await initDependencies(); // get_it setup
  runApp(const SpendArcApp());
}
```

#### Step 0.3 — Set up app router (simple Navigator 2.0 or just MaterialApp routes)
Routes: `/` → DashboardPage, `/transactions` → TransactionListPage  
Add Transaction opens as a `showModalBottomSheet`.

---

### Phase 1 — Domain Layer
**Time estimate: 30 min**  
**Module coverage: Module 1 (Clean Architecture) — 20%**

This is the skeleton everything else depends on. Build it first, completely, before touching data or UI.

#### Step 1.1 — Define Failures
```dart
// core/error/failures.dart
abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]);
}

class CacheFailure extends Failure { ... }
class NetworkFailure extends Failure { ... }
class NotFoundFailure extends Failure { ... }
```

**Rule:** UI and BLoC only ever see `Failure` subtypes. Never raw exceptions.

#### Step 1.2 — Define UseCase interface
```dart
// core/usecases/usecase.dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable { ... }
```

**Rule:** Every use case has exactly one public method: `call()`. Nothing else.

#### Step 1.3 — Transaction Entity
```dart
// features/transaction/domain/entities/transaction.dart
class Transaction extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isSynced;

  const Transaction({...});

  Transaction copyWith({...}); // needed for optimistic rollback

  @override
  List<Object?> get props => [id, title, amount, category, date, isSynced];
}
```

#### Step 1.4 — Budget Entity
```dart
class Budget extends Equatable {
  final String id;
  final double limit;
  final DateTime month;
  ...
}
```

#### Step 1.5 — Abstract Repositories
```dart
// features/transaction/domain/repositories/transaction_repository.dart
abstract class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> getTransactions();
  Future<Either<Failure, Transaction>> addTransaction(Transaction transaction);
  Future<Either<Failure, Unit>> deleteTransaction(String id);
  Future<Either<Failure, Unit>> syncPendingTransactions();
}

// features/budget/domain/repositories/budget_repository.dart
abstract class BudgetRepository {
  Future<Either<Failure, Budget>> getBudget();
  Future<Either<Failure, Unit>> setBudget(Budget budget);
}
```

#### Step 1.6 — Use Cases
Create one file per use case:

**GetTransactionsUseCase**
```dart
class GetTransactions implements UseCase<List<Transaction>, NoParams> {
  final TransactionRepository repository;
  GetTransactions(this.repository);

  @override
  Future<Either<Failure, List<Transaction>>> call(NoParams params) =>
      repository.getTransactions();
}
```

**AddTransactionUseCase**
```dart
class AddTransaction implements UseCase<Transaction, AddTransactionParams> {
  ...
  @override
  Future<Either<Failure, Transaction>> call(AddTransactionParams params) =>
      repository.addTransaction(params.transaction);
}

class AddTransactionParams extends Equatable {
  final Transaction transaction;
  ...
}
```

**DeleteTransactionUseCase**
```dart
class DeleteTransaction implements UseCase<Unit, DeleteTransactionParams> {
  ...
}

class DeleteTransactionParams extends Equatable {
  final String id;
  ...
}
```

**GetBudgetUseCase** and **SetBudgetUseCase** — same pattern.

**Verification checkpoint:** At this point, `lib/features/*/domain/` has zero Flutter imports. Run `grep -r "package:flutter" lib/features/*/domain/` — should return nothing.

---

### Phase 2 — Data Layer
**Time estimate: 40 min**  
**Module coverage: Module 1 + Module 4 (Offline-First)**

#### Step 2.1 — TransactionModel
```dart
// Extends the domain entity, adds serialization
@HiveType(typeId: 0)
class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.category,
    required super.date,
    required super.isSynced,
  });

  factory TransactionModel.fromEntity(Transaction t) => TransactionModel(...);

  // For fake remote (JSON)
  factory TransactionModel.fromJson(Map<String, dynamic> json) => ...;
  Map<String, dynamic> toJson() => {...};
}
```

Run `flutter pub run build_runner build` after adding `@HiveType` and `@HiveField` annotations.

#### Step 2.2 — Local Data Source
```dart
abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getAllTransactions();
  Future<void> cacheTransaction(TransactionModel model);
  Future<void> deleteTransaction(String id);
  Future<List<TransactionModel>> getPendingTransactions(); // isSynced == false
  Future<void> markSynced(String id);
  Future<void> replaceAll(List<TransactionModel> models); // used by background sync
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final Box<TransactionModel> box;
  TransactionLocalDataSourceImpl(this.box);

  @override
  Future<List<TransactionModel>> getAllTransactions() async =>
      box.values.toList();

  @override
  Future<void> cacheTransaction(TransactionModel model) async =>
      box.put(model.id, model);

  // ... etc
}
```

#### Step 2.3 — Fake Remote Data Source
```dart
abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> fetchAll();
  Future<TransactionModel> pushTransaction(TransactionModel model);
  Future<void> deleteTransaction(String id);
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
    if (Random().nextInt(10) == 0) throw NetworkException();
    _store.removeWhere((j) => j['id'] == model.id);
    _store.add(model.toJson());
    return model;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _store.removeWhere((j) => j['id'] == id);
  }
}
```

**Decision note:** The 10% random failure is intentional — it lets you demo and test the optimistic rollback path without a real backend.

#### Step 2.4 — Repository Implementation
```dart
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource local;
  final TransactionRemoteDataSource remote;

  TransactionRepositoryImpl({required this.local, required this.remote});

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions() async {
    try {
      // INSTANT local load — never await remote here
      final localData = await local.getAllTransactions();
      return Right(localData);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Transaction>> addTransaction(Transaction t) async {
    try {
      // 1. Save locally with isSynced=false
      final model = TransactionModel.fromEntity(t.copyWith(isSynced: false));
      await local.cacheTransaction(model);
      // 2. Try to push remotely
      try {
        final synced = await remote.pushTransaction(model);
        await local.markSynced(synced.id);
        return Right(synced.copyWith(isSynced: true));
      } on NetworkException {
        // stays in write queue (isSynced=false) — will be retried later
        return Right(model);
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
}
```

#### Step 2.5 — Background Sync (with diffing + isolate)
This is a standalone method called after the initial local load. Lives in the repository or a dedicated `SyncService`.

```dart
// In TransactionRepositoryImpl
Future<void> backgroundSync() async {
  try {
    final remoteList = await remote.fetchAll();
    final localList = await local.getAllTransactions();

    // Run diff in isolate — not on main thread
    final delta = await compute(_computeDiff, _DiffInput(remoteList, localList));

    for (final t in delta.toAdd) await local.cacheTransaction(t);
    for (final t in delta.toUpdate) await local.cacheTransaction(t);
    for (final id in delta.toDelete) await local.deleteTransaction(id);
  } catch (_) {
    // Background sync failure is silent — user already has local data
  }
}

// Top-level function required for compute()
_DiffOutput _computeDiff(_DiffInput input) {
  final remoteMap = {for (final t in input.remote) t.id: t};
  final localMap = {for (final t in input.local) t.id: t};

  final toAdd = input.remote.where((t) => !localMap.containsKey(t.id)).toList();
  final toUpdate = input.remote
      .where((t) => localMap.containsKey(t.id) && t != localMap[t.id])
      .toList();
  final toDelete = localMap.keys.where((id) => !remoteMap.containsKey(id)).toList();

  return _DiffOutput(toAdd: toAdd, toUpdate: toUpdate, toDelete: toDelete);
}
```

**Why top-level?** `compute()` requires the function to be a top-level or static function — it gets spawned in a separate `Isolate` and cannot close over instance state.

---

### Phase 3 — DI Wiring with get_it
**Time estimate: 20 min**  
**Module coverage: Module 1 (DI)**

#### Step 3.1 — injection_container.dart
```dart
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── External ──────────────────────────────────────────
  final transactionBox = await Hive.openBox<TransactionModel>('transactions');
  final budgetBox = await Hive.openBox<BudgetModel>('budget');

  sl.registerLazySingleton(() => transactionBox);
  sl.registerLazySingleton(() => budgetBox);

  // ── Data sources ──────────────────────────────────────
  sl.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSourceImpl(),
  );

  // ── Repositories ──────────────────────────────────────
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(local: sl(), remote: sl()),
  );
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(local: sl()),
  );

  // ── Use cases ─────────────────────────────────────────
  sl.registerLazySingleton(() => GetTransactions(sl()));
  sl.registerLazySingleton(() => AddTransaction(sl()));
  sl.registerLazySingleton(() => DeleteTransaction(sl()));
  sl.registerLazySingleton(() => GetBudget(sl()));
  sl.registerLazySingleton(() => SetBudget(sl()));

  // ── BLoCs ─────────────────────────────────────────────
  // Use registerFactory so each BLoC gets a fresh instance per page
  sl.registerFactory(() => TransactionBloc(
    getTransactions: sl(),
    addTransaction: sl(),
    deleteTransaction: sl(),
  ));
  sl.registerFactory(() => BudgetBloc(
    getBudget: sl(),
    setBudget: sl(),
    transactionStream: sl<TransactionBloc>().stream, // inter-BLoC wiring
  ));
}
```

**Decision — `registerFactory` vs `registerLazySingleton` for BLoCs:**  
Use `registerFactory` for BLoCs. Each time a page is created, it gets a fresh BLoC. If you used `registerLazySingleton`, a closed BLoC after navigation would crash.  
Use `registerLazySingleton` for use cases and repositories — they are stateless and safe to share.

---

### Phase 4 — BLoC Layer
**Time estimate: 45 min**  
**Module coverage: Module 3 (BLoC) — 20%**

#### Step 4.1 — TransactionBloc Events
```dart
abstract class TransactionEvent extends Equatable {}

class LoadTransactions extends TransactionEvent { ... }
class AddTransactionEvent extends TransactionEvent {
  final Transaction transaction;
  ...
}
class DeleteTransactionEvent extends TransactionEvent {
  final String id;
  ...
}
class SyncTransactions extends TransactionEvent { ... }
```

#### Step 4.2 — TransactionBloc States
```dart
abstract class TransactionState extends Equatable {}

class TransactionInitial extends TransactionState { ... }
class TransactionLoading extends TransactionState { ... }
class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  ...
}
class TransactionError extends TransactionState {
  final String message;
  ...
}
```

#### Step 4.3 — TransactionBloc Implementation
```dart
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactions getTransactions;
  final AddTransaction addTransaction;
  final DeleteTransaction deleteTransaction;

  TransactionBloc({
    required this.getTransactions,
    required this.addTransaction,
    required this.deleteTransaction,
  }) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
    on<AddTransactionEvent>(_onAdd);
    on<DeleteTransactionEvent>(_onDelete);
  }

  Future<void> _onLoad(LoadTransactions event, Emitter emit) async {
    emit(TransactionLoading());
    final result = await getTransactions(NoParams());
    result.fold(
      (failure) => emit(TransactionError(_mapFailure(failure))),
      (transactions) => emit(TransactionLoaded(transactions)),
    );
  }

  // OPTIMISTIC ADD
  Future<void> _onAdd(AddTransactionEvent event, Emitter emit) async {
    final currentState = state;
    if (currentState is! TransactionLoaded) return;

    // 1. Optimistic: show immediately
    final optimisticList = [event.transaction, ...currentState.transactions];
    emit(TransactionLoaded(optimisticList));

    // 2. Persist
    final result = await addTransaction(AddTransactionParams(event.transaction));
    result.fold(
      (failure) {
        // Rollback: restore previous list
        emit(TransactionLoaded(currentState.transactions));
      },
      (saved) {
        // Replace optimistic with saved (has correct isSynced flag)
        final updated = optimisticList
          .map((t) => t.id == saved.id ? saved : t)
          .toList();
        emit(TransactionLoaded(updated));
      },
    );
  }

  // OPTIMISTIC DELETE
  Future<void> _onDelete(DeleteTransactionEvent event, Emitter emit) async {
    final currentState = state;
    if (currentState is! TransactionLoaded) return;

    final previousList = currentState.transactions;

    // 1. Optimistic: remove immediately
    final optimisticList = previousList
      .where((t) => t.id != event.id)
      .toList();
    emit(TransactionLoaded(optimisticList));

    // 2. Persist
    final result = await deleteTransaction(DeleteTransactionParams(event.id));
    result.fold(
      (failure) {
        // Rollback: restore the deleted item
        emit(TransactionLoaded(previousList));
      },
      (_) { /* success — nothing to do */ },
    );
  }
}
```

#### Step 4.4 — BudgetBloc with Inter-BLoC Communication
```dart
class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final GetBudget getBudget;
  final SetBudget setBudget;
  late final StreamSubscription<TransactionState> _transactionSubscription;

  BudgetBloc({
    required this.getBudget,
    required this.setBudget,
    required Stream<TransactionState> transactionStream,
  }) : super(BudgetInitial()) {
    on<LoadBudget>(_onLoad);
    on<RecalculateBudget>(_onRecalculate);

    // Listen to TransactionBloc's stream — react to list changes
    _transactionSubscription = transactionStream.listen((transactionState) {
      if (transactionState is TransactionLoaded) {
        add(RecalculateBudget(transactionState.transactions));
      }
    });
  }

  Future<void> _onLoad(LoadBudget event, Emitter emit) async {
    final result = await getBudget(NoParams());
    result.fold(
      (failure) => emit(BudgetError(_mapFailure(failure))),
      (budget) => emit(BudgetLoaded(budget: budget, spent: 0)),
    );
  }

  void _onRecalculate(RecalculateBudget event, Emitter emit) {
    final currentState = state;
    if (currentState is! BudgetLoaded) return;

    final now = DateTime.now();
    final spent = event.transactions
      .where((t) => t.date.month == now.month && t.date.year == now.year)
      .fold(0.0, (sum, t) => sum + t.amount);

    emit(currentState.copyWith(spent: spent));
  }

  // CRITICAL: Cancel subscription on close — this will be asked in verbal interview
  @override
  Future<void> close() {
    _transactionSubscription.cancel();
    return super.close();
  }
}
```

#### Step 4.5 — BudgetState
```dart
class BudgetLoaded extends BudgetState {
  final Budget budget;
  final double spent;

  double get remaining => budget.limit - spent;
  double get percentage => (spent / budget.limit).clamp(0.0, 1.0);
  bool get isUnderBudget => spent < budget.limit;

  BudgetLoaded copyWith({double? spent}) => BudgetLoaded(
    budget: budget,
    spent: spent ?? this.spent,
  );
}
```

---

### Phase 5 — UI Screens
**Time estimate: 30 min**  
**Module coverage: Foundation for Module 2**

#### Step 5.1 — Dashboard Page
```dart
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<TransactionBloc>()..add(LoadTransactions())),
        BlocProvider(create: (_) => sl<BudgetBloc>()..add(LoadBudget())),
      ],
      child: Scaffold(
        body: Column(children: [
          // Arc meter + particle burst area
          BlocBuilder<BudgetBloc, BudgetState>(
            builder: (context, state) {
              if (state is BudgetLoaded) {
                return ArcMeterWidget(percentage: state.percentage);
              }
              return const SizedBox();
            },
          ),
          // Line chart area
          BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              if (state is TransactionLoaded) {
                return SpendingLineChart(transactions: state.transactions);
              }
              return const SizedBox();
            },
          ),
        ]),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTransaction(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

#### Step 5.2 — Transaction List Page
```dart
class TransactionListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoaded) {
          return ListView.builder(
            itemCount: state.transactions.length,
            itemBuilder: (ctx, i) => SwipeDeleteItem(
              key: ValueKey(state.transactions[i].id),
              transaction: state.transactions[i],
              onDelete: () => context.read<TransactionBloc>()
                .add(DeleteTransactionEvent(state.transactions[i].id)),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
```

#### Step 5.3 — Add Transaction Bottom Sheet
```dart
// Fields: title (TextField), amount (TextField numeric), 
// category (DropdownButton), date (DatePicker)
// On submit: context.read<TransactionBloc>().add(AddTransactionEvent(transaction))
```

---

### Phase 6 — Custom Animations
**Time estimate: 75 min (largest investment)**  
**Module coverage: Module 2 — 35%**

#### Step 6.1 — Arc Meter (CustomPainter)

```dart
class ArcMeterPainter extends CustomPainter {
  final double percentage;    // 0.0 → 1.0
  final Color fillColor;
  final Color trackColor;

  ArcMeterPainter({
    required this.percentage,
    required this.fillColor,
    required this.trackColor,
    // IMPORTANT: Pass animation value as repaint notifier
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    const strokeWidth = 20.0;
    const startAngle = pi * 0.75;       // starts at bottom-left
    const sweepAngle = pi * 1.5;        // 270 degrees total

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw track (background arc)
    paint.color = trackColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepAngle, false, paint,
    );

    // Draw fill (progress arc)
    paint.color = fillColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepAngle * percentage, false, paint,
    );

    // Draw spend text in center
    final textPainter = TextPainter(
      text: TextSpan(text: '${(percentage * 100).toInt()}%', ...),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  // CRITICAL: Only repaint when percentage changes — not every frame
  @override
  bool shouldRepaint(ArcMeterPainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
```

**Wrap in AnimatedWidget:**
```dart
class ArcMeterWidget extends StatefulWidget {
  final double percentage;
  ...
}

class _ArcMeterWidgetState extends State<ArcMeterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animation = Tween<double>(begin: 0, end: widget.percentage)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(ArcMeterWidget old) {
    super.didUpdateWidget(old);
    if (old.percentage != widget.percentage) {
      _animation = Tween<double>(begin: old.percentage, end: widget.percentage)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => CustomPaint(
        painter: ArcMeterPainter(percentage: _animation.value, ...),
        size: const Size(240, 240),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

#### Step 6.2 — Spending Line Chart (CustomPainter)

Key implementation points:
- Aggregate transactions by day into a `List<Offset>` (day index → total spend)
- Normalize Y values: `normalizedY = (amount / maxAmount) * chartHeight`
- Draw X and Y axis lines first
- Draw the line using `Path()` with `path.lineTo()` for straight or `path.quadraticBezierTo()` for smooth curves
- Animate the path drawing: use a `_progressAnimation` (0.0 → 1.0) and in `paint()` extract a sub-path using `PathMetrics`

```dart
@override
void paint(Canvas canvas, Size size) {
  // ... draw axes ...
  
  // Animate path drawing using PathMetrics
  final pathMetric = _fullPath.computeMetrics().first;
  final extractedPath = pathMetric.extractPath(0, pathMetric.length * progress);
  canvas.drawPath(extractedPath, linePaint);
}

@override
bool shouldRepaint(LineChartPainter old) => old.progress != progress;
```

#### Step 6.3 — Spring-Swipe Delete

```dart
class SwipeDeleteItem extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback onDelete;
  ...
}

class _SwipeDeleteItemState extends State<SwipeDeleteItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta.dx);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() > 100) {
      // Spring out and delete
      final simulation = SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 200, damping: 20),
        _dragOffset,
        -400.0,  // target offscreen
        details.velocity.pixelsPerSecond.dx / 400,
      );
      _controller.animateWith(simulation).then((_) => widget.onDelete());
    } else {
      // Snap back with spring
      final simulation = SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 500, damping: 25),
        _dragOffset, 0.0, 0.0,
      );
      _controller.animateWith(simulation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Transform.translate(
        offset: Offset(_dragOffset, 0),
        child: TransactionListItem(transaction: widget.transaction),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

#### Step 6.4 — Particle Burst Overlay

Trigger condition: `BudgetLoaded` state where `isUnderBudget == true` and a new transaction was just added.

```dart
class ParticleBurstOverlay extends StatefulWidget {
  final bool trigger;
  ...
}

class _Particle {
  Offset position;
  Offset velocity;
  Color color;
  double opacity;
}

class _ParticleBurstState extends State<ParticleBurstOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _controller.addListener(_updateParticles);
  }

  void _launch() {
    final rng = Random();
    _particles.clear();
    for (int i = 0; i < 40; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 100 + rng.nextDouble() * 200;
      _particles.add(_Particle(
        position: Offset.zero,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: Colors.primaries[rng.nextInt(Colors.primaries.length)],
        opacity: 1.0,
      ));
    }
    _controller.forward(from: 0);
  }

  void _updateParticles() {
    final t = _controller.value;
    setState(() {
      for (final p in _particles) {
        p.position += p.velocity * 0.016; // approx frame delta
        p.opacity = (1 - t).clamp(0, 1);
      }
    });
  }

  @override
  void didUpdateWidget(ParticleBurstOverlay old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !old.trigger) _launch();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(_particles),
      child: widget.child,
    );
  }
}
```

---

### Phase 7 — Offline-First & Write Queue
**Time estimate: 30 min**  
**Module coverage: Module 4 — 15%**

This phase wires connectivity detection to the sync mechanism already built in Phase 2.

#### Step 7.1 — ConnectivityService

```dart
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onlineStream =>
      _connectivity.onConnectivityChanged
          .map((result) => result != ConnectivityResult.none);

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

#### Step 7.2 — Wire connectivity to sync in TransactionBloc

```dart
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  late final StreamSubscription<bool> _connectivitySubscription;

  TransactionBloc({...}) : super(TransactionInitial()) {
    // ... existing event handlers ...
    on<SyncTransactions>(_onSync);

    // Auto-trigger sync when device comes back online
    _connectivitySubscription = sl<ConnectivityService>()
        .onlineStream
        .where((online) => online)  // only when going online
        .listen((_) => add(SyncTransactions()));
  }

  Future<void> _onSync(SyncTransactions event, Emitter emit) async {
    await syncPendingTransactionsUseCase(NoParams());
    // After sync, reload to reflect updated isSynced flags
    add(LoadTransactions());
  }

  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    return super.close();
  }
}
```

#### Step 7.3 — Background sync after initial local load

In `_onLoad`, after emitting the local data, kick off the background sync and apply delta:

```dart
Future<void> _onLoad(LoadTransactions event, Emitter emit) async {
  // Step 1: Instant local load
  final localResult = await getTransactions(NoParams());
  localResult.fold(
    (f) => emit(TransactionError(_mapFailure(f))),
    (transactions) => emit(TransactionLoaded(transactions)),
  );

  // Step 2: Background sync (doesn't block — no await on whole flow)
  await sl<TransactionRepositoryImpl>().backgroundSync();

  // Step 3: Reload after sync to show updated data
  final refreshed = await getTransactions(NoParams());
  refreshed.fold((_) {}, (transactions) => emit(TransactionLoaded(transactions)));
}
```

---

### Phase 8 — Tests
**Time estimate: 30 min**  
**Module coverage: Module 5 — 10%**

#### Step 8.1 — Unit Test: GetTransactionsUseCase
```dart
void main() {
  late GetTransactions usecase;
  late MockTransactionRepository mockRepo;

  setUp(() {
    mockRepo = MockTransactionRepository();
    usecase = GetTransactions(mockRepo);
  });

  test('should return list of transactions from repository', () async {
    when(() => mockRepo.getTransactions())
        .thenAnswer((_) async => Right([tTransaction]));

    final result = await usecase(NoParams());

    expect(result, Right([tTransaction]));
    verify(() => mockRepo.getTransactions()).called(1);
  });
}
```

#### Step 8.2 — Unit Test: AddTransactionUseCase
```dart
test('should call addTransaction on repository with correct params', () async {
  when(() => mockRepo.addTransaction(any()))
      .thenAnswer((_) async => Right(tTransaction));

  final result = await usecase(AddTransactionParams(tTransaction));

  expect(result, Right(tTransaction));
  verify(() => mockRepo.addTransaction(tTransaction)).called(1);
});
```

#### Step 8.3 — BLoC Test: Optimistic Delete + Rollback
```dart
blocTest<TransactionBloc, TransactionState>(
  'emits optimistic delete then rolls back on failure',
  build: () {
    when(() => mockDeleteUseCase(any()))
        .thenAnswer((_) async => Left(NetworkFailure()));
    return bloc;
  },
  seed: () => TransactionLoaded([tTransaction]),
  act: (b) => b.add(DeleteTransactionEvent(tTransaction.id)),
  expect: () => [
    TransactionLoaded([]),         // optimistic remove
    TransactionLoaded([tTransaction]), // rollback
  ],
);
```

#### Step 8.4 — BLoC Test: BudgetBloc recalculates on stream update
```dart
test('recalculates spent when transaction stream emits', () async {
  final controller = StreamController<TransactionState>();
  final bloc = BudgetBloc(
    getBudget: mockGetBudget,
    setBudget: mockSetBudget,
    transactionStream: controller.stream,
  );

  bloc.emit(BudgetLoaded(budget: tBudget, spent: 0));
  controller.add(TransactionLoaded([tTransaction])); // amount: 500
  await Future.delayed(Duration.zero);

  expect(bloc.state, isA<BudgetLoaded>()
      .having((s) => (s as BudgetLoaded).spent, 'spent', 500.0));

  await bloc.close();
  await controller.close();
});
```

#### Step 8.5 — Unit Test: Diff algorithm
```dart
test('compute diff correctly identifies adds, updates, and deletes', () {
  final remote = [tTransactionA, tTransactionB_updated];
  final local = [tTransactionA, tTransactionB_original, tTransactionC];

  final result = computeDiff(remote, local);

  expect(result.toAdd, isEmpty);
  expect(result.toUpdate, [tTransactionB_updated]);
  expect(result.toDelete, [tTransactionC.id]);
});
```

#### Step 8.6 — Widget Test: ArcMeterWidget renders
```dart
testWidgets('ArcMeterWidget renders at correct percentage', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: ArcMeterWidget(percentage: 0.6),
  ));

  expect(find.byType(CustomPaint), findsOneWidget);

  final painter = tester.widget<CustomPaint>(find.byType(CustomPaint))
      .painter as ArcMeterPainter;
  expect(painter.percentage, closeTo(0.6, 0.01));
});
```

#### Step 8.7 — Widget Test: SwipeDeleteItem triggers delete callback
```dart
testWidgets('swipe left triggers onDelete callback', (tester) async {
  bool deleted = false;
  await tester.pumpWidget(MaterialApp(
    home: SwipeDeleteItem(
      transaction: tTransaction,
      onDelete: () => deleted = true,
    ),
  ));

  await tester.drag(find.byType(SwipeDeleteItem), const Offset(-200, 0));
  await tester.pumpAndSettle();

  expect(deleted, isTrue);
});
```

Run all: `flutter test` — all 7 must pass.

---

### Phase 9 — Polish & Bonus (if time allows)
**Time estimate: remaining time**

#### Mandatory polish (do before bonus)
- Handle empty states (no transactions yet)
- Handle `BudgetLoaded` when `budget.limit == 0` (first launch — show a "Set your budget" prompt)
- Visual indicator on transaction list items where `isSynced == false` (e.g. a small clock icon)
- Make sure `dispose()` is called on every `AnimationController` — run the app in debug mode and check for "A was disposed..." warnings

#### Bonus A — Adaptive Layout
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return Row(children: [arcMeter, lineChart]);  // tablet: side-by-side
    }
    return Column(children: [arcMeter, lineChart]); // phone: stacked
  },
)
```

#### Bonus B — GLSL Shader
Create `assets/shaders/arc_glow.frag`, register in `pubspec.yaml` under `flutter.shaders`, load with `FragmentProgram.fromAsset()`. Apply as a shader mask on the arc meter widget.

#### Bonus C — GoRouter Deep Links
```dart
// Route: spendarc://transaction/:id
GoRoute(
  path: '/transaction/:id',
  builder: (context, state) => TransactionDetailPage(
    id: state.pathParameters['id']!,
  ),
),
```
Add `android:scheme="spendarc"` intent filter in `AndroidManifest.xml`.

---

## 5. Decision Reference

Quick reference for decisions you may be questioned on verbally:

| Decision | What you chose | Why |
|----------|---------------|-----|
| Local DB | Hive | No schema migration, fast reads, works with isolates |
| DI registration for BLoC | `registerFactory` | Prevents closed BLoC reuse across navigations |
| DI registration for UseCase/Repo | `registerLazySingleton` | Stateless — safe to share, created only once |
| Fake remote failure rate | 10% random | Enables demonstrating rollback without a real server |
| Diff algorithm location | Top-level function | `compute()` requires top-level or static — cannot close over `this` |
| Inter-BLoC communication | Stream injection in constructor | Decoupled — BudgetBloc doesn't import TransactionBloc |
| `shouldRepaint` | Only on data change | Prevents redundant `paint()` calls on every rebuild |
| `StreamSubscription` cancellation | In `close()` | BLoC lifecycle — `close()` is guaranteed to be called on BLoC disposal |

---