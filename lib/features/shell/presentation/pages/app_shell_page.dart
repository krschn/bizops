import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class AppShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellPage({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(color: AppColors.divider, height: 1),
          BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'Transactions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2),
                label: 'Products',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.store),
                label: 'Suppliers',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payments),
                label: 'Payroll',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Reports',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
