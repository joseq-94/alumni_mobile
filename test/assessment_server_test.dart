import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../tool/assessment_server.dart';

void main() {
  late Directory directory;
  late File store;
  AssessmentServer? server;
  late http.Client client;
  late DateTime now;

  Future<void> start() async {
    server = await AssessmentServer.start(
      dataFile: store,
      webOrigin: 'http://localhost:7357',
      clock: () => now,
    );
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('assessment_api_test_');
    store = File('${directory.path}/assessment.json');
    client = http.Client();
    now = DateTime.utc(2026, 10, 31);
    await start();
  });

  tearDown(() async {
    client.close();
    await server?.close();
    server = null;
    await directory.delete(recursive: true);
  });

  Future<http.Response> request(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? body,
    String? origin,
  }) async {
    final url = Uri.parse('http://127.0.0.1:${server!.port}/api/mobile$path');
    final outbound = http.Request(method, url);
    if (token != null) outbound.headers['Authorization'] = 'Bearer $token';
    if (origin != null) outbound.headers['Origin'] = origin;
    if (body != null) {
      outbound.headers['Content-Type'] = 'application/json';
      outbound.body = jsonEncode(body);
    }
    return http.Response.fromStream(await client.send(outbound));
  }

  Map<String, dynamic> payload(http.Response response) =>
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

  Future<String> signIn([String login = 'admin']) async {
    final response = await request(
      'POST',
      '/login',
      body: {'login': login, 'password': 'Password1'},
    );
    expect(response.statusCode, 200);
    return payload(response)['token'] as String;
  }

  test('a session expires and logout invalidates it on the server', () async {
    expect((await request('GET', '/me')).statusCode, 401);
    final denied = await request(
      'POST',
      '/login',
      body: {'login': 'admin', 'password': 'bad password'},
    );
    expect(denied.statusCode, 401);

    final token = await signIn('  ADMIN  ');
    expect(payload(await request('GET', '/me', token: token))['data']['id'], 1);
    expect((await request('POST', '/logout', token: token)).statusCode, 204);
    expect((await request('GET', '/me', token: token)).statusCode, 401);

    final expiring = await signIn();
    now = now.add(const Duration(minutes: 30));
    expect((await request('GET', '/feed', token: expiring)).statusCode, 401);
  });

  test(
    'valid profile edits survive restart and stay with the signed-in user',
    () async {
      final admin = await signIn();
      final sam = await signIn('sam@example.com');
      for (final changes in [
        {'id': 2, 'name': 'Wrong account'},
        {'email': 'other@example.com'},
        {'name': '   '},
        {'bio': 'x' * 1001},
        {'name': null},
      ]) {
        expect(
          (await request(
            'PATCH',
            '/me',
            token: admin,
            body: changes,
          )).statusCode,
          422,
        );
      }
      final saved = await request(
        'PATCH',
        '/me',
        token: admin,
        body: {'name': '  Alex Updated  ', 'bio': 'Résumé'},
      );
      expect(saved.statusCode, 200);
      expect(payload(saved)['data'], containsPair('name', 'Alex Updated'));
      expect(payload(saved)['data'], containsPair('bio', 'Résumé'));
      expect(
        payload(await request('GET', '/me', token: sam))['data']['name'],
        'Sam Taylor',
      );
      expect(await store.readAsString(), isNot(contains(admin)));

      await server!.close();
      server = null;
      await start();
      expect((await request('GET', '/me', token: admin)).statusCode, 401);
      final newToken = await signIn();
      expect(
        payload(await request('GET', '/me', token: newToken))['data']['name'],
        'Alex Updated',
      );
    },
  );

  test(
    'the public feed is paginated and private details are withheld',
    () async {
      final token = await signIn('sam@example.com');
      final first = payload(await request('GET', '/feed?page=1', token: token));
      final second = payload(
        await request('GET', '/feed?page=2', token: token),
      );
      expect(first['next_page'], 2);
      expect(second['next_page'], isNull);
      expect(first['data'], hasLength(20));
      expect(second['data'], hasLength(10));
      final ids = [
        for (final page in [first, second])
          for (final post in page['data'] as List) post['id'],
      ];
      expect(ids, List.generate(30, (index) => 30 - index));
      expect(
        payload(await request('GET', '/feed/30', token: token))['data']['id'],
        30,
      );
      expect((await request('GET', '/feed/31', token: token)).statusCode, 404);
      expect((await request('GET', '/feed/999', token: token)).statusCode, 404);
      expect(
        (await request('GET', '/feed?page=0', token: token)).statusCode,
        422,
      );
      expect(
        payload(await request('GET', '/feed?page=999', token: token))['data'],
        isEmpty,
      );
    },
  );

  test('CORS permits the configured web origin only', () async {
    final approved = await request(
      'OPTIONS',
      '/me',
      origin: 'http://localhost:7357',
    );
    expect(approved.statusCode, 204);
    expect(
      approved.headers['access-control-allow-origin'],
      'http://localhost:7357',
    );
    expect(approved.headers['access-control-allow-methods'], contains('PATCH'));
    final other = await request(
      'OPTIONS',
      '/me',
      origin: 'http://localhost:9999',
    );
    expect(other.headers['access-control-allow-origin'], isNull);
  });
}
