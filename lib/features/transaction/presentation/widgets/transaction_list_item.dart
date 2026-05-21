import 'package:flutter/material.dart';

import '../../domain/entities/transaction.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _categoryColor,
        child: Text(
          transaction.categoryName[0],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(transaction.title, style: theme.textTheme.titleMedium),
      subtitle: Text(
        transaction.categoryName,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.formattedAmount,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                transaction.formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          if (!transaction.isSynced)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.access_time, size: 16, color: theme.colorScheme.outline),
            ),
        ],
      ),
    );
  }

  Color get _categoryColor {
    switch (transaction.category) {
      case TransactionCategory.food:
        return Colors.orange;
      case TransactionCategory.transport:
        return Colors.blue;
      case TransactionCategory.bills:
        return Colors.red;
      case TransactionCategory.shopping:
        return Colors.purple;
      case TransactionCategory.other:
        return Colors.grey;
    }
  }
}
