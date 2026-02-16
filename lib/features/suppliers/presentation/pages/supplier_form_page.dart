import 'package:flutter/material.dart';

class SupplierFormPage extends StatelessWidget {
  final String? supplierId;

  const SupplierFormPage({super.key, this.supplierId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(supplierId == null ? 'New Supplier' : 'Edit Supplier'),
      ),
    );
  }
}
