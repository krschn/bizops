import 'package:flutter/material.dart';

class TransactionFormPage extends StatelessWidget {
  final String? transactionId;

  const TransactionFormPage({super.key, this.transactionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(transactionId == null ? 'New Transaction' : 'Edit Transaction'),
      ),
    );
  }
}
