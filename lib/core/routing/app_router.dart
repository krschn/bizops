import 'package:go_router/go_router.dart';

import '../../features/products/domain/entities/product.dart';
import '../../features/suppliers/domain/entities/supplier.dart';
import '../../features/shell/presentation/pages/app_shell_page.dart';
import '../../features/transactions/presentation/pages/transaction_list_page.dart';
import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import '../../features/products/presentation/pages/product_list_page.dart';
import '../../features/products/presentation/pages/product_form_page.dart';
import '../../features/suppliers/presentation/pages/supplier_list_page.dart';
import '../../features/suppliers/presentation/pages/supplier_form_page.dart';
import '../../features/payroll/presentation/pages/payroll_main_page.dart';
import '../../features/payroll/presentation/pages/employee_list_page.dart';
import '../../features/payroll/presentation/pages/employee_form_page.dart';
import '../../features/payroll/presentation/pages/payroll_entry_form_page.dart';
import '../../features/reports/presentation/pages/report_page.dart';

abstract class AppRouter {
  static final GoRouter config = GoRouter(
    initialLocation: '/transactions',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellPage(navigationShell: navigationShell),
        branches: [
          // Branch 0: Transactions
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionListPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const TransactionFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => TransactionFormPage(
                      transactionId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch 1: Products
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                builder: (context, state) => const ProductListPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const ProductFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ProductFormPage(
                      productId: state.pathParameters['id'],
                      product: state.extra as Product?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Suppliers
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/suppliers',
                builder: (context, state) => const SupplierListPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const SupplierFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => SupplierFormPage(
                      supplierId: state.pathParameters['id'],
                      supplier: state.extra as Supplier?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: Payroll
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/payroll',
                builder: (context, state) => const PayrollMainPage(),
                routes: [
                  GoRoute(
                    path: 'employees',
                    builder: (context, state) => const EmployeeListPage(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) => const EmployeeFormPage(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => EmployeeFormPage(
                          employeeId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'entry/new',
                    builder: (context, state) => const PayrollEntryFormPage(),
                  ),
                  GoRoute(
                    path: 'entry/:id',
                    builder: (context, state) => PayrollEntryFormPage(
                      entryId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch 4: Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
