import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/swipe_delete_item.dart';

class TransactionListPage extends StatelessWidget {
  const TransactionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<TransactionBloc>()..add(const LoadTransactions()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Transactions')),
        body: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            if (state is TransactionLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TransactionError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is TransactionLoaded) {
              if (state.transactions.isEmpty) {
                return const Center(child: Text('No transactions yet'));
              }
              return ListView.builder(
                itemCount: state.transactions.length,
                itemBuilder: (ctx, i) => SwipeDeleteItem(
                  key: ValueKey(state.transactions[i].id),
                  transaction: state.transactions[i],
                  onDelete: () => context
                      .read<TransactionBloc>()
                      .add(DeleteTransactionEvent(state.transactions[i].id)),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
