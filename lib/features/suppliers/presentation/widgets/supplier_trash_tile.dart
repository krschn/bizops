import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../domain/entities/supplier.dart';

class SupplierTrashTile extends StatelessWidget {
  const SupplierTrashTile({
    super.key,
    required this.supplier,
    required this.onRestore,
    required this.onPermanentDelete,
  });

  final Supplier supplier;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        supplier.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.trashAccent,
              decoration: TextDecoration.lineThrough,
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
                    'This will permanently delete "${supplier.name}". This action cannot be undone.',
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
