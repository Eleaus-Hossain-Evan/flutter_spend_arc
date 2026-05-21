import 'package:flutter_spend_arc/features/budget/data/models/budget_model.dart';
import 'package:flutter_spend_arc/features/transaction/data/models/transaction_model.dart';
import 'package:hive_ce/hive_ce.dart';

import '../features/transaction/domain/entities/transaction.dart';

@GenerateAdapters([
  AdapterSpec<TransactionModel>(),
  AdapterSpec<BudgetModel>(),
])
part 'hive_adapters.g.dart';
