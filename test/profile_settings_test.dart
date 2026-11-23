import 'package:alumni_mobile/models/alumni_model.dart';
import 'package:alumni_mobile/models/settings_model.dart';
import 'package:alumni_mobile/models/user_profile.dart';
import 'package:alumni_mobile/services/alumni_datasource.dart';
import 'package:alumni_mobile/services/demo_datasource.dart';
import 'package:alumni_mobile/services/preferences_service.dart';
import 'package:alumni_mobile/views/widgets/profile_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// A predictable failing data source lets us test error handling without a server.
class FailingProfileSource extends DemoDataSource {
  int saveAttempts = 0;

  @override
  Future<UserProfile> updateProfile(String name, String bio) async {
    saveAttempts++;
    throw DataSourceException('Profile could not be saved.');
  }
}

// A shared in-memory store simulates settings being reopened without a phone.
class TestPreferenceStore {
  String theme = 'System';
  bool largerText = false;
  bool failNextSave = false;
}

class TestPreferences extends PreferencesService {
  final TestPreferenceStore store;
  TestPreferences(this.store);

  @override
  String get theme => store.theme;

  @override
  bool get largerText => store.largerText;

  @override
  Future<void> save(String theme, bool largerText) async {
    if (store.failNextSave) {
      store.failNextSave = false;
      throw StateError('Simulated storage failure');
    }
    store.theme = theme;
    store.largerText = largerText;
  }

  @override
  Future<void> close() async {}
}

void main() {
  testWidgets('Invalid name and bio are rejected before saving', (tester) async {
    final source = FailingProfileSource();
    final model = AlumniModel(source);
    await model.signIn('admin', 'Password1');
    addTearDown(model.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AlumniModel>.value(
        value: model,
        child: const MaterialApp(home: Scaffold(body: ProfileForm())),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '   ');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your name.'), findsOneWidget);
    expect(source.saveAttempts, 0);

    await tester.enterText(fields.at(0), 'Valid name');
    await tester.enterText(fields.at(1), 'x' * 1001);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Use 1000 characters or fewer.'), findsOneWidget);
    expect(source.saveAttempts, 0);
  });

  testWidgets('Failed save keeps the draft; Cancel restores saved values', (
    tester,
  ) async {
    final source = FailingProfileSource();
    final model = AlumniModel(source);
    await model.signIn('admin', 'Password1');
    addTearDown(model.dispose);

    final originalName = model.profile!.name;
    final originalBio = model.profile!.bio;

    await tester.pumpWidget(
      ChangeNotifierProvider<AlumniModel>.value(
        value: model,
        child: const MaterialApp(home: Scaffold(body: ProfileForm())),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Unsaved name');
    await tester.enterText(fields.at(1), 'Unsaved summary');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(source.saveAttempts, 1);
    expect(find.text('Profile could not be saved.'), findsOneWidget);
    expect(tester.widget<TextFormField>(fields.at(0)).controller!.text,
        'Unsaved name');
    expect(tester.widget<TextFormField>(fields.at(1)).controller!.text,
        'Unsaved summary');
    expect(model.profile!.name, originalName);
    expect(model.profile!.bio, originalBio);
    expect(find.text('Profile saved.'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(fields.at(0)).controller!.text,
        originalName);
    expect(tester.widget<TextFormField>(fields.at(1)).controller!.text,
        originalBio);
  });

  test('Failed preference save keeps previous settings and reports an error',
      () async {
    final store = TestPreferenceStore();
    final settings = SettingsModel(TestPreferences(store));
    addTearDown(settings.dispose);

    store.failNextSave = true;
    await settings.update('Dark', true);

    expect(settings.error, 'Could not save device settings. Try again.');
    expect(settings.theme, 'System');
    expect(settings.largerText, false);
    expect(settings.saving, false);
    expect(store.theme, 'System');
    expect(store.largerText, false);
  });

  test('Saved preferences are restored when settings model is recreated',
      () async {
    final store = TestPreferenceStore();
    final original = SettingsModel(TestPreferences(store));
    await original.update('Dark', true);
    expect(original.error, isNull);
    original.dispose();

    final reopened = SettingsModel(TestPreferences(store));
    addTearDown(reopened.dispose);
    expect(reopened.theme, 'Dark');
    expect(reopened.themeMode, ThemeMode.dark);
    expect(reopened.largerText, true);
  });
}
