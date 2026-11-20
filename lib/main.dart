import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'models/alumni_model.dart';
import 'models/settings_model.dart';
import 'services/hive_datasource.dart';
import 'services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = PreferencesService();
  await preferences.initialise();
  final dataSource = await HiveDataSource.createAsync();
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
