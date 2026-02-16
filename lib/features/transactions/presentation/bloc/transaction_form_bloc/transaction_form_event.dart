import '../../../domain/entities/transaction_line.dart';

sealed class TransactionFormEvent {
  const TransactionFormEvent();
}

final class TransactionFormInitialized extends TransactionFormEvent {
  const TransactionFormInitialized({this.existingTransactionId});
  final String? existingTransactionId;
}

final class TransactionLineAdded extends TransactionFormEvent {
  const TransactionLineAdded(this.line);
  final TransactionLine line;
}

final class TransactionLineRemoved extends TransactionFormEvent {
  const TransactionLineRemoved(this.lineId);
  final String lineId;
}

final class TransactionLineRestored extends TransactionFormEvent {
  const TransactionLineRestored(this.lineId);
  final String lineId;
}

final class TransactionLineEdited extends TransactionFormEvent {
  const TransactionLineEdited({required this.lineId, required this.newQuantity});
  final String lineId;
  final double newQuantity;
}

final class TransactionSaveRequested extends TransactionFormEvent {
  const TransactionSaveRequested();
}
