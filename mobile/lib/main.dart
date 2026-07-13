import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/storage/offline_cache_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/providers/module_provider.dart';
import 'presentation/providers/sync_provider.dart';
import 'presentation/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await OfflineCacheService.init();
  } catch (e) {
    debugPrint('[main] Falha ao iniciar Hive: $e');
  }

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('[main] Falha ao iniciar notificacoes: $e');
  }

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  final authProvider = AuthProvider();
  await authProvider.bootstrap();

  final moduleProvider = ModuleProvider();
  await moduleProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: moduleProvider),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: const App(),
    ),
  );
}
