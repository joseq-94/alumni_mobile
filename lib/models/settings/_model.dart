import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class SettingsModel extends ChangeNotifier {
  final PreferencesService preferences;
  late String theme;
  late bool largerText;
  String? error;
  bool saving = false;
  bool _disposed = false;
  SettingsModel(this.preferences) {
    theme = preferences.theme;
    largerText = preferences.largerText;
    error = preferences.startupError;
  }
  ThemeMode get themeMode {
    if (theme == 'Light') return ThemeMode.light;
    if (theme == 'Dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> update(String newTheme, bool newLargerText) async {
    if (saving) return;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await preferences.save(newTheme, newLargerText);
      if (_disposed) return;
      theme = newTheme;
      largerText = newLargerText;
    } catch (_) {
      if (_disposed) return;
      error = 'Could not save device settings. Try again.';
    }
    saving = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    preferences.close();
    super.dispose();
  }
}
