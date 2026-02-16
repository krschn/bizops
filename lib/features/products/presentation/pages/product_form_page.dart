import 'package:flutter/material.dart';

class ProductFormPage extends StatelessWidget {
  final String? productId;

  const ProductFormPage({super.key, this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(productId == null ? 'New Product' : 'Edit Product'),
      ),
    );
  }
}
