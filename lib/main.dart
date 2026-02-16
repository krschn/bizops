import 'package:flutter/material.dart';

import 'core/di/injection.dart';
import 'core/routing/app_router.dart';
import 'core/storage/hive_initializer.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  await configureDependencies();
  runApp(const BizOpsApp());
}

class BizOpsApp extends StatelessWidget {
  const BizOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BizOps',
      theme: AppTheme.light(),
      routerConfig: AppRouter.config,
      debugShowCheckedModeBanner: false,
    );
  }
}
