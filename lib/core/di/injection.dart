import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Registrations added here as features are built (Plans 02–07).
  // Example pattern:
  //   getIt.registerLazySingleton<ProductRepository>(
  //     () => ProductRepositoryImpl(getIt()),
  //   );
}
