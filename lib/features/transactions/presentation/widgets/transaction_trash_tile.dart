import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../domain/entities/transaction.dart';

class TransactionTrashTile extends StatelessWidget {
  const TransactionTrashTile({
    super.key,
    required this.transaction,
    required this.onRestore,
    required this.onPermanentDelete,
  });

  final Transaction transaction;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;

  @override
  Widget build(BuildContext context) {
    final date = transaction.transactedAt;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return ListTile(
      title: Text(
        dateStr,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.trashAccent,
              decoration: TextDecoration.lineThrough,
            ),
      ),
      subtitle: Text(
        '₱${transaction.grandTotal % 1 == 0 ? transaction.grandTotal.toInt() : transaction.grandTotal.toStringAsFixed(2)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.trashAccent,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.restore, color: AppColors.primary),
            onPressed: onRestore,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: AppColors.error),
            onPressed: () async {
              final confirmed = await ConfirmDeleteDialog.show(
                context,
                title: 'Permanently Delete',
                content:
                    'This will permanently delete the transaction from $dateStr. This action cannot be undone.',
              );
              if (confirmed == true) {
                onPermanentDelete();
              }
            },
          ),
        ],
      ),
    );
  }
}
