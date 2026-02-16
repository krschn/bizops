import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_empty_state_widget.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading_widget.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../widgets/product_list_tile.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late final ProductBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ProductBloc>();
    _bloc.add(const ProductsLoaded());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text('Products'),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(color: AppColors.divider, height: 1, thickness: 1),
          ),
        ),
        body: _ActiveList(bloc: _bloc),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () async {
            await context.push('/products/new');
            if (context.mounted) {
              _bloc.add(const ProductsLoaded());
            }
          },
          child: const Icon(Icons.add, color: AppColors.textOnPrimary),
        ),
      ),
    );
  }
}

class _ActiveList extends StatelessWidget {
  const _ActiveList({required this.bloc});

  final ProductBloc bloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      bloc: bloc,
      builder: (context, state) {
        return switch (state) {
          ProductLoading() => const AppLoadingWidget(),
          ProductLoaded(products: final products) when products.isEmpty =>
            const AppEmptyStateWidget(
              message: 'No products yet. Tap + to add one.',
            ),
          ProductLoaded(products: final products) => ListView.separated(
              itemCount: products.length,
              separatorBuilder: (context, i) =>
                  const Divider(color: AppColors.divider, height: 1),
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductListTile(
                  product: product,
                  onEdit: () async {
                    await context.push(
                      '/products/${product.id}',
                      extra: product,
                    );
                    if (context.mounted) {
                      bloc.add(const ProductsLoaded());
                    }
                  },
                  onDelete: () async {
                    final confirmed = await ConfirmDeleteDialog.show(
                      context,
                      title: 'Delete Product',
                      content:
                          'Are you sure you want to delete "${product.name}"?',
                    );
                    if (confirmed == true && context.mounted) {
                      bloc.add(ProductDeleteRequested(product.id));
                    }
                  },
                );
              },
            ),
          ProductError(message: final message) => AppErrorWidget(
              message: message,
              onRetry: () => bloc.add(const ProductsLoaded()),
            ),
          _ => const AppEmptyStateWidget(
              message: 'No products yet. Tap + to add one.',
            ),
        };
      },
    );
  }
}
