import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_loading_widget.dart';
import '../../../../shared/widgets/labeled_field.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/transaction_line.dart';
import '../bloc/transaction_form_bloc/transaction_form_bloc.dart';
import '../bloc/transaction_form_bloc/transaction_form_event.dart';
import '../bloc/transaction_form_bloc/transaction_form_state.dart';
import '../widgets/transaction_line_deleted_row.dart';
import '../widgets/transaction_line_form_row.dart';
import '../widgets/transaction_total_bar.dart';

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({super.key, this.transactionId});

  final String? transactionId;

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  late final TransactionFormBloc _bloc;

  bool get _isEditing => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<TransactionFormBloc>();
    _bloc.add(
      TransactionFormInitialized(
        existingTransactionId: widget.transactionId,
      ),
    );
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _showAddLineSheet(TransactionFormReady state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _AddLineSheet(
        state: state,
        onAdd: (line) {
          _bloc.add(TransactionLineAdded(line));
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  void _showEditLineSheet(TransactionLine line) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _EditLineSheet(
        line: line,
        onSave: (newQuantity) {
          _bloc.add(
            TransactionLineEdited(lineId: line.id, newQuantity: newQuantity),
          );
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<TransactionFormBloc, TransactionFormState>(
        bloc: _bloc,
        listener: (context, state) {
          if (state is TransactionFormSaveSuccess) {
            context.pop();
          } else if (state is TransactionFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          }
        },
        child: BlocBuilder<TransactionFormBloc, TransactionFormState>(
          bloc: _bloc,
          builder: (context, state) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                title: Text(
                  _isEditing ? 'Edit Transaction' : 'New Transaction',
                ),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(
                    color: AppColors.divider,
                    height: 1,
                    thickness: 1,
                  ),
                ),
                actions: [
                  if (state is TransactionFormReady)
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () =>
                          _bloc.add(const TransactionSaveRequested()),
                    ),
                ],
              ),
              body: switch (state) {
                TransactionFormLoading() => const AppLoadingWidget(),
                TransactionFormSaving() => const AppLoadingWidget(),
                TransactionFormReady() => _ReadyBody(
                    state: state,
                    onAddLine: () => _showAddLineSheet(state),
                    onEditLine: (line) => _showEditLineSheet(line),
                    onRemoveLine: (lineId) =>
                        _bloc.add(TransactionLineRemoved(lineId)),
                    onRestoreLine: (lineId) =>
                        _bloc.add(TransactionLineRestored(lineId)),
                  ),
                TransactionFormError() => _ReadyBody(
                    state: TransactionFormReady(
                      lines: const [],
                      availableProducts: const [],
                      availableSuppliers: const [],
                      grandTotal: 0,
                    ),
                    onAddLine: () {},
                    onEditLine: (_) {},
                    onRemoveLine: (_) {},
                    onRestoreLine: (_) {},
                  ),
                _ => const SizedBox.shrink(),
              },
            );
          },
        ),
      ),
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.state,
    required this.onAddLine,
    required this.onEditLine,
    required this.onRemoveLine,
    required this.onRestoreLine,
  });

  final TransactionFormReady state;
  final VoidCallback onAddLine;
  final void Function(TransactionLine line) onEditLine;
  final void Function(String lineId) onRemoveLine;
  final void Function(String lineId) onRestoreLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              ...state.lines.map((line) {
                if (line.isDeleted) {
                  return TransactionLineDeletedRow(
                    key: ValueKey(line.id),
                    line: line,
                    onRestore: () => onRestoreLine(line.id),
                  );
                }
                return TransactionLineFormRow(
                  key: ValueKey(line.id),
                  line: line,
                  onEdit: () => onEditLine(line),
                  onDelete: () => onRemoveLine(line.id),
                );
              }),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: onAddLine,
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text(
                    'Add Line',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        TransactionTotalBar(grandTotal: state.grandTotal),
      ],
    );
  }
}

class _AddLineSheet extends StatefulWidget {
  const _AddLineSheet({required this.state, required this.onAdd});

  final TransactionFormReady state;
  final void Function(TransactionLine) onAdd;

  @override
  State<_AddLineSheet> createState() => _AddLineSheetState();
}

class _AddLineSheetState extends State<_AddLineSheet> {
  String? _selectedSupplierId;
  String? _selectedProductId;
  final _readingController = TextEditingController();
  final _readingFocusNode = FocusNode();
  final List<double> _readings = [];
  bool _readingHasError = false;
  bool _supplierError = false;
  bool _productError = false;

  static const _uuid = Uuid();

  @override
  void dispose() {
    _readingController.dispose();
    _readingFocusNode.dispose();
    super.dispose();
  }

  Product? get _selectedProduct {
    if (_selectedProductId == null) return null;
    final matches =
        widget.state.availableProducts.where((p) => p.id == _selectedProductId);
    return matches.isEmpty ? null : matches.first;
  }

  String _formatNumber(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  // Strip a leading numeric prefix from a unit string: "1 kg" → "kg", "kg" → "kg"
  String _unitLabel(String unit) =>
      unit.replaceFirst(RegExp(r'^\d+(\.\d+)?\s*'), '');

  void _addReading() {
    final hasSupplier = _selectedSupplierId != null;
    final hasProduct = _selectedProductId != null;
    if (!hasSupplier || !hasProduct) {
      setState(() {
        _supplierError = !hasSupplier;
        _productError = !hasProduct;
      });
      return;
    }
    final value = double.tryParse(_readingController.text.trim());
    if (value == null || value <= 0) {
      setState(() => _readingHasError = true);
      return;
    }
    setState(() {
      _readings.add(value);
      _readingController.clear();
      _readingHasError = false;
    });
    _readingFocusNode.requestFocus();
  }

  void _confirm() {
    final supplierId = _selectedSupplierId;
    final product = _selectedProduct;
    if (supplierId == null || product == null || _readings.isEmpty) return;

    final supplier =
        widget.state.availableSuppliers.firstWhere((s) => s.id == supplierId);
    final totalQty = _readings.fold(0.0, (a, b) => a + b);
    final unitPrice = product.price;

    widget.onAdd(
      TransactionLine(
        id: _uuid.v4(),
        transactionId: '',
        supplierId: supplier.id,
        supplierName: supplier.name,
        productId: product.id,
        productName: product.name,
        unit: product.unit,
        quantity: totalQty,
        unitPrice: unitPrice,
        lineTotal: totalQty * unitPrice,
        isDeleted: false,
        sortOrder: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliers =
        widget.state.availableSuppliers.where((s) => !s.isDeleted).toList();
    final products =
        widget.state.availableProducts.where((p) => !p.isDeleted).toList();

    final selectedProduct = _selectedProduct;
    final totalQty = _readings.fold(0.0, (a, b) => a + b);
    final unitPrice = selectedProduct?.price ?? 0.0;
    final lineTotal = totalQty * unitPrice;
    final canConfirm = _selectedSupplierId != null &&
        _selectedProductId != null &&
        _readings.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Line',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Supplier',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedSupplierId,
                hint: const Text('Select supplier'),
                decoration: InputDecoration(
                  errorText: _supplierError ? 'Required' : null,
                ),
                items: suppliers
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedSupplierId = v;
                  _supplierError = false;
                }),
              ),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Product',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedProductId,
                hint: const Text('Select product'),
                decoration: InputDecoration(
                  errorText: _productError ? 'Required' : null,
                ),
                items: products
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedProductId = v;
                  _productError = false;
                }),
              ),
            ),
            if (selectedProduct != null) ...[
              const SizedBox(height: 8),
              Text(
                'Price: ₱${_formatNumber(selectedProduct.price)} / ${_unitLabel(selectedProduct.unit)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _readingController,
                    focusNode: _readingFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter reading',
                      errorText:
                          _readingHasError ? 'Enter a positive number' : null,
                    ),
                    onChanged: (_) {
                      if (_readingHasError) {
                        setState(() => _readingHasError = false);
                      }
                    },
                    onFieldSubmitted: (_) => _addReading(),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                    ),
                    onPressed: _addReading,
                    tooltip: 'Add reading',
                  ),
                ),
              ],
            ),
            if (_readings.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._readings.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        _formatNumber(entry.value),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                      if (selectedProduct != null)
                        Text(
                          ' ${_unitLabel(selectedProduct.unit)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _readings.removeAt(entry.key)),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 8),
              Text(
                'Total: ${_formatNumber(totalQty)} ${_unitLabel(selectedProduct?.unit ?? '')}'
                '  ×  ₱${_formatNumber(unitPrice)}'
                '  =  ₱${_formatNumber(lineTotal)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: canConfirm ? _confirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                disabledBackgroundColor: AppColors.textDisabled,
                minimumSize: const Size.fromHeight(48),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add to Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditLineSheet extends StatefulWidget {
  const _EditLineSheet({required this.line, required this.onSave});

  final TransactionLine line;
  final void Function(double newQuantity) onSave;

  @override
  State<_EditLineSheet> createState() => _EditLineSheetState();
}

class _EditLineSheetState extends State<_EditLineSheet> {
  late final TextEditingController _qtyController;
  bool _hasError = false;

  String _formatNumber(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  String _unitLabel(String unit) =>
      unit.replaceFirst(RegExp(r'^\d+(\.\d+)?\s*'), '');

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: _formatNumber(widget.line.quantity),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _save() {
    final value = double.tryParse(_qtyController.text.trim());
    if (value == null || value <= 0) {
      setState(() => _hasError = true);
      return;
    }
    widget.onSave(value);
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit Line',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${line.supplierName} · ${line.productName} · ₱${_formatNumber(line.unitPrice)} / ${_unitLabel(line.unit)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Quantity (${_unitLabel(line.unit)})',
            child: TextFormField(
              controller: _qtyController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0',
                errorText: _hasError ? 'Enter a positive number' : null,
              ),
              onChanged: (_) {
                if (_hasError) setState(() => _hasError = false);
              },
              onFieldSubmitted: (_) => _save(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              minimumSize: const Size.fromHeight(48),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
