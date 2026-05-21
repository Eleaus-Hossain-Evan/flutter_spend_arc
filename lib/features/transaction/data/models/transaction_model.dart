import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  @override
  final String id;

  @override
  final String title;

  @override
  final double amount;

  @override
  final TransactionCategory category;

  @override
  final DateTime date;

  @override
  final bool isSynced;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.isSynced,
  }) : super(
         id: id,
         title: title,
         amount: amount,
         category: category,
         date: date,
         isSynced: isSynced,
       );

  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      category: transaction.category,
      date: transaction.date,
      isSynced: transaction.isSynced,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      category: TransactionCategory.values.firstWhere(
        (category) => category.name == json['category'],
        orElse: () => TransactionCategory.other,
      ),
      date: DateTime.parse(json['date']),
      isSynced: json['isSynced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  @override
  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionCategory? category,
    DateTime? date,
    bool? isSynced,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
