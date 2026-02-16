import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_empty_state_widget.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading_widget.dart';
import '../../../transactions/presentation/bloc/transaction_list_bloc/transaction_list_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_list_bloc/transaction_list_event.dart';
import '../../../transactions/presentation/bloc/transaction_list_bloc/transaction_list_state.dart';
import '../../../transactions/presentation/widgets/transaction_trash_tile.dart';

class ManagePage extends StatefulWidget {
  const ManagePage({super.key});

  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  late final TransactionListBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<TransactionListBloc>();
    _bloc.add(const TransactionsTrashLoaded());
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
          title: const Text('Manage'),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(
              color: AppColors.divider,
              height: 1,
              thickness: 1,
            ),
          ),
        ),
        body: BlocBuilder<TransactionListBloc, TransactionListState>(
          bloc: _bloc,
          builder: (context, state) {
            return switch (state) {
              TransactionListLoading() => const AppLoadingWidget(),
              TransactionListTrashLoaded(transactions: final txs)
                  when txs.isEmpty =>
                const AppEmptyStateWidget(message: 'Trash is empty.'),
              TransactionListTrashLoaded(transactions: final txs) =>
                ListView.separated(
                  itemCount: txs.length,
                  separatorBuilder: (context, i) =>
                      const Divider(color: AppColors.divider, height: 1),
                  itemBuilder: (context, index) {
                    final tx = txs[index];
                    return TransactionTrashTile(
                      transaction: tx,
                      onRestore: () =>
                          _bloc.add(TransactionRestoreRequested(tx.id)),
                      onPermanentDelete: () =>
                          _bloc.add(TransactionPermanentDeleteRequested(tx.id)),
                    );
                  },
                ),
              TransactionListError(failure: final failure) => AppErrorWidget(
                  message: failure.message,
                  onRetry: () => _bloc.add(const TransactionsTrashLoaded()),
                ),
              _ => const AppEmptyStateWidget(message: 'Trash is empty.'),
            };
          },
        ),
      ),
    );
  }
}
