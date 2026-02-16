import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/labeled_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/supplier.dart';
import '../bloc/supplier_bloc.dart';
import '../bloc/supplier_event.dart';
import '../bloc/supplier_state.dart';

class SupplierFormPage extends StatefulWidget {
  const SupplierFormPage({super.key, this.supplierId, this.supplier});

  final String? supplierId;
  final Supplier? supplier;

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  late final TextEditingController _nameController;
  late final SupplierBloc _bloc;

  bool get _isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<SupplierBloc>();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _save() {
    final now = DateTime.now();
    final id = widget.supplier?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final supplier = Supplier(
      id: id,
      name: _nameController.text.trim(),
      isDeleted: false,
      createdAt: widget.supplier?.createdAt ?? now,
      updatedAt: now,
    );
    _bloc.add(SupplierSaveRequested(supplier));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<SupplierBloc, SupplierState>(
        bloc: _bloc,
        listener: (context, state) {
          if (state is SupplierSaveSuccess) {
            context.pop();
          } else if (state is SupplierError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          }
        },
        child: BlocBuilder<SupplierBloc, SupplierState>(
          bloc: _bloc,
          builder: (context, state) {
            final isSaving = state is SupplierSaving;
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                title: Text(_isEditing ? 'Edit Supplier' : 'New Supplier'),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(
                    color: AppColors.divider,
                    height: 1,
                    thickness: 1,
                  ),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  LabeledField(
                    label: 'Name',
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Supplier name',
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: _isEditing ? 'Save Changes' : 'Add Supplier',
                    onPressed: isSaving ? null : _save,
                    isLoading: isSaving,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
