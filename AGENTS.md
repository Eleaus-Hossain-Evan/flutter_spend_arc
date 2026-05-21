# SpendArc — Agent Guide

## Project Status

Scaffold only (default Flutter counter app). PRD.md is the build specification. Everything in `lib/features/` needs to be created.

## Source of Truth

`PRD.md` — all architecture decisions, data models, folder structure, and implementation order are defined there.

## Dependencies to Add

Before any feature work, run `flutter pub add` for each:
`flutter_bloc get_it dartz equatable hive hive_flutter uuid connectivity_plus bloc_test mocktail hive_generator build_runner`

Hive is used instead of sqflite (no schema migrations needed, works with isolates).

## Architecture

- **Clean Architecture**: 3 layers per feature — `domain/` (pure Dart), `data/`, `presentation/`
- **State Management**: flutter_bloc with Events/States per feature
- **DI**: get_it with `registerFactory` for BLoCs (fresh instance per page, prevents crash on navigation), `registerLazySingleton` for use cases/repos (stateless, safe to share)
- **Local Storage**: Hive — register adapters and open boxes before `runApp()`
- **Fake Remote**: In-memory store with intentional 10% random failure rate (demonstrates optimistic rollback)

## Key Conventions

- Use `Either<Failure, Type>` (dartz) as return type for all repository methods
- `Failure` subtypes extend `Equatable` — UI/BLoCs never see raw exceptions
- Every use case has exactly one public method: `call()`
- Domain layer (`lib/features/*/domain/`) must have **zero** Flutter imports
- `copyWith()` on entities required for optimistic rollback
- `StreamSubscription` **must** be cancelled in BLoC's `close()` override
- CustomPainters: `shouldRepaint` only on data change (not every frame)

## Critical Implementation Details

- **Diff for background sync**: Must be a **top-level function** (not instance method) — `compute()` requires it for isolate spawning
- **Inter-BLoC communication**: BudgetBloc receives TransactionBloc's stream via constructor injection (decoupled — no direct import of TransactionBloc)
- **Optimistic updates**: BLoC emits new state immediately, then persists — rolls back on failure
- **Sync pipeline**: Instant local load → emit → background sync (with isolate diff) → reload
- **Weekly sync**: Called via `SyncTransactions` event, auto-triggered when `ConnectivityService` detects reconnection

## Testing

- Run: `flutter test` (all tests under `test/`)
- 7 tests specified in PRD Phase 8: 2 use case unit, 2 bloc tests, 1 diff unit, 2 widget tests
- Use `mocktail` for mocks, `blocTest` for BLoC tests
- Widget tests: `tester.pumpWidget(MaterialApp(home: ...))`
- BLoC tests: use `seed:` for initial state, `act:` to dispatch events, `expect:` for state sequence

## Project Skills

Skills in `.agents/skills/` override default behavior. Key ones:
- `clean-architecture` — folder structure, layers, DI rules
- `flutter-bloc-patterns` — BLoC creation, optimistic updates, inter-BLoC wiring
- `flutter-app-infrastructure` — Hive setup, get_it bootstrap, ConnectivityService
- `flutter-testing-patterns` — blocTest, mocktail, widget test patterns
- `flutter-animations-custom-painter` — CustomPainter arc/line-chart/particle, spring-swipe delete
- `flutter-routing-go-router` — simple MaterialApp routes (no go_router needed)
- `flutter-ui-design-system` — Material defaults, no custom tokens
- `flutter-localization-i18n` — NOT USED (PRD doesn't require it)

## Polish Requirements (mandatory before bonus)

- Empty state handling (no transactions)
- Budget limit == 0 → "Set your budget" prompt
- `isSynced == false` → clock icon on list item
- Every `AnimationController` must be `dispose()`d
