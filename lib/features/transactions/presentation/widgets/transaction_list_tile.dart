import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/transaction.dart';

class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    super.key,
    required this.transaction,
    required this.onTap,
    required this.onDelete,
  });

  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final activeLineCount =
        transaction.lines.where((l) => !l.isDeleted).length;
    final date = transaction.transactedAt;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return ListTile(
      onTap: onTap,
      title: Text(
        dateStr,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        '$activeLineCount line${activeLineCount == 1 ? '' : 's'}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₱${transaction.grandTotal % 1 == 0 ? transaction.grandTotal.toInt() : transaction.grandTotal.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.textSecondary,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
