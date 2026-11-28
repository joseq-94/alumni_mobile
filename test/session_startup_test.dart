import 'dart:async';
import 'dart:io';

import 'package:alumni_mobile/app.dart';
import 'package:alumni_mobile/main.dart' as app_entry;
import 'package:alumni_mobile/models/alumni_model.dart';
import 'package:alumni_mobile/models/settings_model.dart';
import 'package:alumni_mobile/services/api_datasource.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'api_test.dart' show jsonResponse, profile;
import 'widget_test.dart' show MemoryPreferences;

const baseUrl = 'https://example.com/api/mobile';
const key = 'alumni_token:$baseUrl';
const token = 'saved-token';
const storage = FlutterSecureStorage();

Future<void> openApp(WidgetTester tester, MockClient client) async {
  final source = ApiDataSource(baseUrl, client: client, storage: storage);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AlumniModel(source, restoreSavedSession: source.restoreSession)
                ..restoreSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsModel(MemoryPreferences()),
        ),
      ],
      child: const AlumniApp(),
    ),
  );
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({key: token}));

  testWidgets('Android opens the login form when no token is saved', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final prefsDir = Directory.systemTemp.createTempSync('alumni-prefs-');
    addTearDown(() async {
      await Hive.close();
      prefsDir.deleteSync(recursive: true);
    });

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.runAsync(() async {
        await Hive.openBox<dynamic>('alumni_preferences', path: prefsDir.path);
        await app_entry.main();
      });
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Retry'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('an expired saved token is cleared and login opens', (
    tester,
  ) async {
    await openApp(
      tester,
      MockClient((request) async {
        expect(request.url.path, '/api/mobile/me');
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response('{}', 401);
      }),
    );
    await tester.pumpAndSettle();

    expect(await storage.read(key: key), isNull);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('Retry keeps the saved token and opens Home after reconnecting', (
    tester,
  ) async {
    final firstCheck = Completer<http.Response>();
    final requestedPaths = <String>[];
    await openApp(
      tester,
      MockClient((request) async {
        final path = request.url.path;
        requestedPaths.add(path);
        expect(request.headers['Authorization'], 'Bearer $token');

        if (requestedPaths.length == 1) return firstCheck.future;
        if (path == '/api/mobile/me') return jsonResponse({'data': profile});
        expect(path, '/api/mobile/feed');
        return jsonResponse({'data': [], 'next_page': null});
      }),
    );

    expect(find.text('Checking your session...'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    firstCheck.completeError(http.ClientException('Offline'));
    await tester.pumpAndSettle();

    expect(await storage.read(key: key), token);
    expect(find.textContaining('Unable to connect'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(requestedPaths, [
      '/api/mobile/me',
      '/api/mobile/me',
      '/api/mobile/feed',
    ]);
  });
}
