import 'package:hive_flutter/hive_flutter.dart';

// Save theme and text size on this device in both API and demo modes.
class PreferencesService {
  Box<dynamic>? _box;
  String? startupError;
  String get theme =>
      _box?.get('theme', defaultValue: 'System') as String? ?? 'System';
  bool get largerText =>
      _box?.get('largerText', defaultValue: false) as bool? ?? false;
  Future<void> initialise() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox('alumni_preferences');
    } catch (_) {
      startupError =
          'Device settings could not be opened. Please restart the app.';
    }
  }

  Future<void> save(String theme, bool largerText) async {
    if (_box == null) throw StateError('Settings storage is unavailable.');
    await _box!.putAll({'theme': theme, 'largerText': largerText});
  }

  Future<void> close() async {
    await _box?.close();
  }
}
