import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/labeled_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.productId, this.product});

  final String? productId;
  final Product? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _unitController;
  late final ProductBloc _bloc;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ProductBloc>();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product != null
          ? (widget.product!.price % 1 == 0
              ? widget.product!.price.toInt().toString()
              : widget.product!.price.toStringAsFixed(2))
          : '',
    );
    _unitController = TextEditingController(text: widget.product?.unit ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _save() {
    final now = DateTime.now();
    final id = widget.product?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final product = Product(
      id: id,
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      unit: _unitController.text.trim(),
      isDeleted: false,
      createdAt: widget.product?.createdAt ?? now,
      updatedAt: now,
    );
    _bloc.add(ProductSaveRequested(product));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<ProductBloc, ProductState>(
        bloc: _bloc,
        listener: (context, state) {
          if (state is ProductSaveSuccess) {
            context.pop();
          } else if (state is ProductError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<ProductBloc, ProductState>(
          bloc: _bloc,
          builder: (context, state) {
            final isSaving = state is ProductSaving;
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                title: Text(_isEditing ? 'Edit Product' : 'New Product'),
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
                        hintText: 'Product name',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Price',
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Unit',
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. kg, pcs, litre',
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: _isEditing ? 'Save Changes' : 'Add Product',
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
