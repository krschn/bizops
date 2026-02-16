sealed class TransactionListEvent {
  const TransactionListEvent();
}

final class TransactionsLoaded extends TransactionListEvent {
  const TransactionsLoaded();
}

final class TransactionsTrashLoaded extends TransactionListEvent {
  const TransactionsTrashLoaded();
}

final class TransactionDeleteRequested extends TransactionListEvent {
  const TransactionDeleteRequested(this.id);
  final String id;
}

final class TransactionRestoreRequested extends TransactionListEvent {
  const TransactionRestoreRequested(this.id);
  final String id;
}

final class TransactionPermanentDeleteRequested extends TransactionListEvent {
  const TransactionPermanentDeleteRequested(this.id);
  final String id;
}
