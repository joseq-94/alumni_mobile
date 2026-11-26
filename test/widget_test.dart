import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:alumni_mobile/app.dart';
import 'package:alumni_mobile/models/alumni_model.dart';
import 'package:alumni_mobile/models/settings_model.dart';
import 'package:alumni_mobile/services/demo_datasource.dart';
import 'package:alumni_mobile/services/api_datasource.dart';
import 'package:alumni_mobile/services/preferences_service.dart';

class MemoryPreferences extends PreferencesService {
  String savedTheme = 'System';
  bool savedLargerText = false;
  @override
  String get theme => savedTheme;
  @override
  bool get largerText => savedLargerText;
  @override
  Future<void> save(String theme, bool largerText) async {
    savedTheme = theme;
    savedLargerText = largerText;
  }

  @override
  Future<void> close() async {}
}

Future<void> startApp(WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlumniModel(DemoDataSource())),
        ChangeNotifierProvider(
          create: (_) => SettingsModel(MemoryPreferences()),
        ),
      ],
      child: const AlumniApp(),
    ),
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('platform sign in starts blank and requires an email', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                AlumniModel(ApiDataSource('https://example.com/api/mobile')),
          ),
          ChangeNotifierProvider(
            create: (_) => SettingsModel(MemoryPreferences()),
          ),
        ],
        child: const AlumniApp(),
      ),
    );
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields[0].controller!.text, isEmpty);
    expect(fields[1].controller!.text, isEmpty);
    expect(find.textContaining('Prototype demo accounts'), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, 'admin');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('sign in, view post, save/cancel profile and sign out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await startApp(tester);
    expect(find.text('admin'), findsOneWidget);
    await tester.tap(find.text('Read the feed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read more').first);
    await tester.pumpAndSettle();
    expect(find.text('Post'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Alex Updated');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Profile saved.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Unsaved');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Updated'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('NMTAFE Alumni'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('draft survives tabs and portrait/landscape layout changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await startApp(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Keep this draft');
    tester.testTextInput.hide();
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Keep this draft'), findsOneWidget);
    for (final size in [
      const Size(640, 360),
      const Size(800, 1280),
      const Size(1280, 800),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(find.text('Keep this draft'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
