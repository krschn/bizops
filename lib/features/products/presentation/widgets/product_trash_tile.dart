import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../domain/entities/product.dart';

class ProductTrashTile extends StatelessWidget {
  const ProductTrashTile({
    super.key,
    required this.product,
    required this.onRestore,
    required this.onPermanentDelete,
  });

  final Product product;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        product.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.trashAccent,
              decoration: TextDecoration.lineThrough,
            ),
      ),
      subtitle: Text(
        '${product.price.toStringAsFixed(2)} / ${product.unit}',
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
                    'This will permanently delete "${product.name}". This action cannot be undone.',
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
