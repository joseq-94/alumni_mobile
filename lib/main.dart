import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'models/alumni_model.dart';
import 'models/settings_model.dart';
import 'services/api_datasource.dart';
import 'services/hive_datasource.dart';
import 'services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = PreferencesService();
  await preferences.initialise();
  const useApi = bool.fromEnvironment('ALUMNI_USE_API');
  final dataSource = useApi
      ? ApiDataSource(
          const String.fromEnvironment('ALUMNI_API_BASE_URL'),
          allowInsecureLocalHttp:
              kDebugMode &&
              const bool.fromEnvironment('ALUMNI_ALLOW_LOCAL_HTTP'),
        )
      : await HiveDataSource.createAsync();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlumniModel(dataSource)),
        ChangeNotifierProvider(create: (_) => SettingsModel(preferences)),
      ],
      child: const AlumniApp(),
    ),
  );
}
