import 'package:flutter_test/flutter_test.dart';

import 'package:bizops/core/utils/transaction_utils.dart';
import 'package:bizops/features/transactions/domain/entities/transaction_line.dart';

TransactionLine _line({
  required String id,
  required double lineTotal,
  bool isDeleted = false,
}) =>
    TransactionLine(
      id: id,
      transactionId: 'tx1',
      supplierId: 's1',
      supplierName: 'Supplier',
      productId: 'p1',
      productName: 'Product',
      unit: 'kg',
      quantity: 1,
      unitPrice: lineTotal,
      lineTotal: lineTotal,
      isDeleted: isDeleted,
      sortOrder: 0,
    );

void main() {
  group('computeGrandTotal', () {
    test('returns 0.0 for empty list', () {
      expect(computeGrandTotal([]), 0.0);
    });

    test('sums all active line totals', () {
      final lines = [
        _line(id: '1', lineTotal: 10.0),
        _line(id: '2', lineTotal: 20.0),
        _line(id: '3', lineTotal: 30.0),
      ];
      expect(computeGrandTotal(lines), 60.0);
    });

    test('excludes deleted lines', () {
      final lines = [
        _line(id: '1', lineTotal: 10.0),
        _line(id: '2', lineTotal: 20.0, isDeleted: true),
        _line(id: '3', lineTotal: 30.0),
      ];
      expect(computeGrandTotal(lines), 40.0);
    });

    test('returns single line total when only one active line', () {
      final lines = [_line(id: '1', lineTotal: 42.5)];
      expect(computeGrandTotal(lines), 42.5);
    });

    test('returns 0.0 when all lines are deleted', () {
      final lines = [
        _line(id: '1', lineTotal: 10.0, isDeleted: true),
        _line(id: '2', lineTotal: 20.0, isDeleted: true),
      ];
      expect(computeGrandTotal(lines), 0.0);
    });
  });
}
