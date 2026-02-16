import 'package:flutter/material.dart';

class PayrollEntryFormPage extends StatelessWidget {
  final String? entryId;

  const PayrollEntryFormPage({super.key, this.entryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(entryId == null ? 'New Payroll Entry' : 'Edit Payroll Entry'),
      ),
    );
  }
}
