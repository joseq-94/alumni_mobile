import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/alumni_model.dart';
import 'models/settings_model.dart';
import 'views/login_page.dart';
import 'views/app_shell.dart';
import 'theme/app_theme.dart';

class AlumniApp extends StatelessWidget {
  const AlumniApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Alumni',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: settings.largerText
                    ? TextScaler.linear(media.textScaler.scale(1) * 1.2)
                    : media.textScaler,
              ),
              child: child!,
            );
          },
          home: Consumer<AlumniModel>(
            builder: (context, model, child) {
              return model.profile == null
                  ? const LoginPage()
                  : AppShell(key: ValueKey(model.profile!.id));
            },
          ),
        );
      },
    );
  }
}
