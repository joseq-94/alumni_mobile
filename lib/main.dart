import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'models/alumni_model.dart';
import 'models/settings_model.dart';
import 'services/api_datasource.dart';
import 'services/hive_datasource.dart';
import 'services/preferences_service.dart';

// Start storage first, choose the data source, then share the models with all screens.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = PreferencesService();
  await preferences.initialise();
  // Build-time flags come from VS Code or --dart-define; restart to apply changes.
  const useApi = bool.fromEnvironment('ALUMNI_USE_API', defaultValue: true);
  final storage = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? const FlutterSecureStorage()
      : null;
  final dataSource = useApi
      ? ApiDataSource(
          const String.fromEnvironment(
            'ALUMNI_API_BASE_URL',
            defaultValue: 'http://127.0.0.1:8000/api/mobile',
          ),
          // Only a debug build with explicit permission may use a local HTTP server.
          allowInsecureLocalHttp:
              kDebugMode &&
              const bool.fromEnvironment('ALUMNI_ALLOW_LOCAL_HTTP'),
          storage: storage,
        )
      : await HiveDataSource.createAsync();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AlumniModel(
            dataSource,
            restoreSavedSession: storage != null && dataSource is ApiDataSource
                ? dataSource.restoreSession
                : null,
          )..restoreSession(),
        ),
        ChangeNotifierProvider(create: (_) => SettingsModel(preferences)),
      ],
      child: const AlumniApp(),
    ),
  );
}
