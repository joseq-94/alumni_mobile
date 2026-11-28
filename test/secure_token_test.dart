import 'package:alumni_mobile/services/alumni_datasource.dart';
import 'package:alumni_mobile/services/api_datasource.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'api_test.dart' show expiredSession, jsonResponse, profile;

void main() {
  const baseUrl = 'https://example.com/api/mobile';
  const key = 'alumni_token:$baseUrl';
  const token = 'test-token';
  const storage = FlutterSecureStorage();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('sign-in saves the token and offline sign-out clears it', () async {
    final source = ApiDataSource(
      baseUrl,
      storage: storage,
      client: MockClient((request) async {
        if (request.url.path == '/api/mobile/login') {
          return jsonResponse({'token': token, 'data': profile});
        }

        expect(request.url.path, '/api/mobile/logout');
        expect(request.headers['Authorization'], 'Bearer $token');
        expect(await storage.read(key: key), isNull);
        throw http.ClientException('Offline');
      }),
    );
    addTearDown(source.dispose);

    await source.signIn('alex@example.com', 'test-password');
    expect(await storage.read(key: key), token);

    await expectLater(source.signOut(), throwsA(isA<DataSourceException>()));
    expect(await storage.read(key: key), isNull);
    await expectLater(source.readProfile(), throwsA(expiredSession));
  });

  test('an authenticated 401 clears the saved token', () async {
    final source = ApiDataSource(
      baseUrl,
      storage: storage,
      client: MockClient((request) async {
        if (request.url.path == '/api/mobile/login') {
          return jsonResponse({'token': token, 'data': profile});
        }

        expect(request.url.path, '/api/mobile/me');
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response('{}', 401);
      }),
    );
    addTearDown(source.dispose);

    await source.signIn('alex@example.com', 'test-password');
    await expectLater(source.readProfile(), throwsA(expiredSession));
    expect(await storage.read(key: key), isNull);
  });
}
