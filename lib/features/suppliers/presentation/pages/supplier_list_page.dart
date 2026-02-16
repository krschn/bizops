import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_empty_state_widget.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading_widget.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../bloc/supplier_bloc.dart';
import '../bloc/supplier_event.dart';
import '../bloc/supplier_state.dart';
import '../widgets/supplier_list_tile.dart';

class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key});

  @override
  State<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends State<SupplierListPage> {
  late final SupplierBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<SupplierBloc>();
    _bloc.add(const SuppliersLoaded());
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
          title: const Text('Suppliers'),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(color: AppColors.divider, height: 1, thickness: 1),
          ),
        ),
        body: _ActiveList(bloc: _bloc),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () async {
            await context.push('/suppliers/new');
            if (context.mounted) {
              _bloc.add(const SuppliersLoaded());
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

  final SupplierBloc bloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupplierBloc, SupplierState>(
      bloc: bloc,
      builder: (context, state) {
        return switch (state) {
          SupplierLoading() => const AppLoadingWidget(),
          SupplierLoaded(suppliers: final suppliers) when suppliers.isEmpty =>
            const AppEmptyStateWidget(
              message: 'No suppliers yet. Tap + to add one.',
            ),
          SupplierLoaded(suppliers: final suppliers) => ListView.separated(
              itemCount: suppliers.length,
              separatorBuilder: (context, i) =>
                  const Divider(color: AppColors.divider, height: 1),
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
                return SupplierListTile(
                  supplier: supplier,
                  onEdit: () async {
                    await context.push(
                      '/suppliers/${supplier.id}',
                      extra: supplier,
                    );
                    if (context.mounted) {
                      bloc.add(const SuppliersLoaded());
                    }
                  },
                  onDelete: () async {
                    final confirmed = await ConfirmDeleteDialog.show(
                      context,
                      title: 'Delete Supplier',
                      content:
                          'Are you sure you want to delete "${supplier.name}"?',
                    );
                    if (confirmed == true && context.mounted) {
                      bloc.add(SupplierDeleteRequested(supplier.id));
                    }
                  },
                );
              },
            ),
          SupplierError(failure: final failure) => AppErrorWidget(
              message: failure.message,
              onRetry: () => bloc.add(const SuppliersLoaded()),
            ),
          _ => const AppEmptyStateWidget(
              message: 'No suppliers yet. Tap + to add one.',
            ),
        };
      },
    );
  }
}
