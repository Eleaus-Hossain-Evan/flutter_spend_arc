import 'package:equatable/equatable.dart';

import '../models/transaction_model.dart';

class DiffInput extends Equatable {
  final List<TransactionModel> remote;
  final List<TransactionModel> local;

  const DiffInput({required this.remote, required this.local});

  @override
  List<Object?> get props => [remote, local];
}

class DiffOutput extends Equatable {
  final List<TransactionModel> toAdd;
  final List<TransactionModel> toUpdate;
  final List<String> toDelete;

  const DiffOutput({
    required this.toAdd,
    required this.toUpdate,
    required this.toDelete,
  });

  @override
  List<Object?> get props => [toAdd, toUpdate, toDelete];
}
