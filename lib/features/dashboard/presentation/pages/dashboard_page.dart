import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../budget/presentation/bloc/budget_bloc.dart';
import '../../../budget/presentation/bloc/budget_event.dart';
import '../../../budget/presentation/bloc/budget_state.dart';
import '../../../transaction/presentation/bloc/transaction_bloc.dart';
import '../../../transaction/presentation/bloc/transaction_event.dart';
import '../../../transaction/presentation/bloc/transaction_state.dart';
import '../../../transaction/presentation/pages/add_transaction_page.dart';
import '../widgets/arc_meter_painter.dart';
import '../widgets/spending_line_chart_painter.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<TransactionBloc>(),
        child: const AddTransactionPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              GetIt.instance<TransactionBloc>()..add(const LoadTransactions()),
        ),
        BlocProvider(
          create: (_) =>
              GetIt.instance<BudgetBloc>()..add(const LoadBudget()),
        ),
      ],
      child: _DashboardContent(showAddTransaction: _showAddTransaction),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final void Function(BuildContext) showAddTransaction;

  const _DashboardContent({required this.showAddTransaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpendArc'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/transactions'),
            icon: const Icon(Icons.list),
            label: const Text('All'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                Expanded(child: _buildArcSection(context)),
                Expanded(child: _buildChartSection(context)),
              ],
            );
          }
          return Column(
            children: [
              Expanded(flex: 3, child: _buildArcSection(context)),
              Expanded(flex: 4, child: _buildChartSection(context)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTransaction(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildArcSection(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        if (state is BudgetLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is BudgetLoaded) {
          if (state.budget.limit == 0) {
            return const Center(child: Text('Set your budget'));
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ArcMeterWidget(percentage: state.percentage),
              const SizedBox(height: 8),
              Text(
                '\$${state.spent.toStringAsFixed(0)} / ${state.budget.formattedLimit}',
                style: theme.textTheme.bodyLarge,
              ),
              if (!state.isUnderBudget)
                Text(
                  'Over budget by \$${(state.spent - state.budget.limit).toStringAsFixed(0)}',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
            ],
          );
        }
        if (state is BudgetError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildChartSection(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoaded) {
          if (state.transactions.isEmpty) {
            return Center(
              child: Text(
                'No transactions yet',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spending Trend',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SpendingLineChart(
                    transactions: state.transactions,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
