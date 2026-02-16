import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/transaction_line.dart';

class TransactionLineDeletedRow extends StatelessWidget {
  const TransactionLineDeletedRow({
    super.key,
    required this.line,
    required this.onRestore,
  });

  final TransactionLine line;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.supplierName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.trashAccent,
                        decoration: TextDecoration.lineThrough,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  line.productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.trashAccent,
                        decoration: TextDecoration.lineThrough,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${line.quantity} ${line.unit.replaceFirst(RegExp(r'^\d+(\.\d+)?\s*'), '')} × ₱${line.unitPrice % 1 == 0 ? line.unitPrice.toInt() : line.unitPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.trashAccent,
                        decoration: TextDecoration.lineThrough,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.restore,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: onRestore,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
