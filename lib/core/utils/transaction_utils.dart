import '../../features/transactions/domain/entities/transaction_line.dart';

double computeGrandTotal(List<TransactionLine> lines) =>
    lines.where((l) => !l.isDeleted).fold(0.0, (sum, l) => sum + l.lineTotal);
