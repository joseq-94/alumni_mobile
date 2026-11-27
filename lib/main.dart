import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'models/alumni_model.dart';
import 'models/settings_model.dart';
import 'models/user_profile.dart';
import 'services/api_datasource.dart';
import 'services/alumni_datasource.dart';
import 'services/hive_datasource.dart';
import 'services/offline_cache_datasource.dart';
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
  // Keep saved copies of API data for reading without a connection.
  const useOfflineCache = bool.fromEnvironment(
    'ALUMNI_OFFLINE_CACHE',
    defaultValue: true,
  );
  final api = useApi
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
      : null;
  final offlineStatus = OfflineStatus();
  final cache = api != null && useOfflineCache
      ? await OfflineCacheDataSource.open(api, offlineStatus)
      : null;
  final AlumniDataSource dataSource =
      cache ?? api ?? await HiveDataSource.createAsync();
  // Session restore still goes to the API; the cache records the restored account.
  final restoreApi = storage != null ? api?.restoreSession : null;
  final Future<UserProfile?> Function()? restoreSavedSession =
      restoreApi == null || cache == null
      ? restoreApi
      : () => cache.restoreSession(restoreApi);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AlumniModel(
            dataSource,
            restoreSavedSession: restoreSavedSession,
          )..restoreSession(),
        ),
        ChangeNotifierProvider(create: (_) => SettingsModel(preferences)),
        ChangeNotifierProvider(create: (_) => offlineStatus),
      ],
      child: const AlumniApp(),
    ),
  );
}
