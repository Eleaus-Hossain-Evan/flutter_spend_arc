import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum TransactionCategory { food, transport, bills, shopping, other }

class Transaction extends Equatable {
  final String id;
  final String title;
  final double amount;
  final TransactionCategory category;
  final DateTime date;
  final bool isSynced;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.isSynced,
  });

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionCategory? category,
    DateTime? date,
    bool? isSynced,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get categoryName {
    return category.name.capitalize;
  }

  @override
  List<Object?> get props => [id, title, amount, category, date, isSynced];

  factory Transaction.create({
    required String title,
    required double amount,
    required TransactionCategory category,
    DateTime? date,
    bool isSynced = false,
  }) {
    return Transaction(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      category: category,
      date: date ?? DateTime.now(),
      isSynced: isSynced,
    );
  }
}

extension StringExtension on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
