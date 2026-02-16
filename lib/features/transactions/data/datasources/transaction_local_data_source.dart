import 'package:hive/hive.dart';

import '../models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getAll();
  Future<List<TransactionModel>> getDeleted();
  Future<TransactionModel?> getById(String id);
  Future<void> save(TransactionModel model);
  Future<void> deleteById(String id);
  Future<List<TransactionModel>> getByDateRange(DateTime from, DateTime to);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  const TransactionLocalDataSourceImpl(this._box);

  final Box<TransactionModel> _box;

  @override
  Future<List<TransactionModel>> getAll() async {
    final models =
        _box.values.where((m) => !m.isDeleted).toList();
    models.sort((a, b) => b.transactedAtMillis.compareTo(a.transactedAtMillis));
    return models;
  }

  @override
  Future<List<TransactionModel>> getDeleted() async =>
      _box.values.where((m) => m.isDeleted).toList();

  @override
  Future<TransactionModel?> getById(String id) async =>
      _box.values.firstWhereOrNull((m) => m.id == id);

  @override
  Future<void> save(TransactionModel model) async =>
      _box.put(model.id, model);

  @override
  Future<void> deleteById(String id) async {
    final model = _box.values.firstWhereOrNull((m) => m.id == id);
    await model?.delete();
  }

  @override
  Future<List<TransactionModel>> getByDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final fromMillis = from.millisecondsSinceEpoch;
    final toMillis = to.millisecondsSinceEpoch;
    return _box.values
        .where(
          (m) =>
              !m.isDeleted &&
              m.transactedAtMillis >= fromMillis &&
              m.transactedAtMillis <= toMillis,
        )
        .toList();
  }
}

extension _IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
