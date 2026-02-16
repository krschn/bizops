import 'package:flutter/material.dart';

class EmployeeFormPage extends StatelessWidget {
  final String? employeeId;

  const EmployeeFormPage({super.key, this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(employeeId == null ? 'New Employee' : 'Edit Employee'),
      ),
    );
  }
}
