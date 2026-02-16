import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_empty_state_widget.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading_widget.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../bloc/transaction_list_bloc/transaction_list_bloc.dart';
import '../bloc/transaction_list_bloc/transaction_list_event.dart';
import '../bloc/transaction_list_bloc/transaction_list_state.dart';
import '../widgets/transaction_list_tile.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  late final TransactionListBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<TransactionListBloc>();
    _bloc.add(const TransactionsLoaded());
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
          title: const Text('Transactions'),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(color: AppColors.divider, height: 1, thickness: 1),
          ),
        ),
        drawer: Drawer(
          backgroundColor: AppColors.background,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: AppColors.primary),
                child: Text(
                  'BizOps',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2,
                    color: AppColors.textSecondary),
                title: const Text('Products'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/products');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.store, color: AppColors.textSecondary),
                title: const Text('Suppliers'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/suppliers');
                },
              ),
              const Divider(color: AppColors.divider, height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.textSecondary),
                title: const Text('Trash'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/manage');
                },
              ),
            ],
          ),
        ),
        body: BlocBuilder<TransactionListBloc, TransactionListState>(
          bloc: _bloc,
          builder: (context, state) {
            return switch (state) {
              TransactionListLoading() => const AppLoadingWidget(),
              TransactionListLoaded(transactions: final txs) when txs.isEmpty =>
                const AppEmptyStateWidget(
                  message: 'No transactions yet. Tap + to add one.',
                ),
              TransactionListLoaded(transactions: final txs) =>
                ListView.separated(
                  itemCount: txs.length,
                  separatorBuilder: (context, i) =>
                      const Divider(color: AppColors.divider, height: 1),
                  itemBuilder: (context, index) {
                    final tx = txs[index];
                    return TransactionListTile(
                      transaction: tx,
                      onTap: () async {
                        await context.push('/transactions/${tx.id}');
                        if (context.mounted) {
                          _bloc.add(const TransactionsLoaded());
                        }
                      },
                      onDelete: () async {
                        final date = tx.transactedAt;
                        final dateStr =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        final confirmed = await ConfirmDeleteDialog.show(
                          context,
                          title: 'Delete Transaction',
                          content:
                              'Are you sure you want to delete the transaction from $dateStr?',
                        );
                        if (confirmed == true && context.mounted) {
                          _bloc.add(TransactionDeleteRequested(tx.id));
                        }
                      },
                    );
                  },
                ),
              TransactionListError(failure: final failure) => AppErrorWidget(
                  message: failure.message,
                  onRetry: () => _bloc.add(const TransactionsLoaded()),
                ),
              _ => const AppEmptyStateWidget(
                  message: 'No transactions yet. Tap + to add one.',
                ),
            };
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () async {
            await context.push('/transactions/new');
            if (mounted) {
              _bloc.add(const TransactionsLoaded());
            }
          },
          child: const Icon(Icons.add, color: AppColors.textOnPrimary),
        ),
      ),
    );
  }
}
