import 'dart:async';
import 'dart:convert';

import 'package:alumni_mobile/services/alumni_datasource.dart';
import 'package:alumni_mobile/services/api_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const profile = {
  'id': 1,
  'name': 'Alex',
  'email': 'alex@example.com',
  'bio': 'Résumé',
  'picture_url': null,
};

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('sign in sends POST and uses the returned profile', () async {
    final source = ApiDataSource(
      'https://example.com/api/mobile/',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/mobile/login');
        expect(request.headers['Authorization'], isNull);
        expect(jsonDecode(request.body), {
          'login': 'Alex',
          'password': ' Password ',
        });
        return jsonResponse({'token': 'fictional-token', 'data': profile});
      }),
    );
    addTearDown(source.dispose);

    final signedIn = await source.signIn(' Alex ', ' Password ');
    expect(signedIn.id, 1);
    expect(signedIn.bio, 'Résumé');
  });

  test(
    'authenticated requests send the token and PATCH only editable fields',
    () async {
      final requests = <String>[];
      final source = ApiDataSource(
        'https://example.com/api/mobile',
        client: MockClient((request) async {
          final path = request.url.path;
          requests.add('${request.method} $path');
          if (path.endsWith('/login')) {
            return jsonResponse({'token': 'fictional-token', 'data': profile});
          }
          expect(request.headers['Authorization'], 'Bearer fictional-token');
          if (request.method == 'PATCH') {
            expect(jsonDecode(request.body), {
              'name': 'Alex',
              'bio': 'New bio',
            });
            return jsonResponse({
              'data': {...profile, 'bio': 'New bio'},
            });
          }
          if (path.endsWith('/logout')) return http.Response('', 204);
          if (path.endsWith('/feed')) {
            expect(request.url.queryParameters['page'], '2');
            return jsonResponse({'data': [], 'next_page': null});
          }
          return jsonResponse({'data': profile});
        }),
      );
      addTearDown(source.dispose);
      await source.signIn('Alex', 'example');
      expect((await source.readProfile()).id, 1);
      expect((await source.updateProfile(' Alex ', 'New bio')).bio, 'New bio');
      expect((await source.readFeed(2)).nextPage, isNull);
      await source.signOut();
      await expectLater(source.readProfile(), throwsA(expiredSession));
      expect(requests, [
        'POST /api/mobile/login',
        'GET /api/mobile/me',
        'PATCH /api/mobile/me',
        'GET /api/mobile/feed',
        'POST /api/mobile/logout',
      ]);
    },
  );

  test(
    'invalid login is distinct from expiry and a 401 clears the session',
    () async {
      var attempts = 0;
      var profileRequests = 0;
      final source = ApiDataSource(
        'https://example.com/api/mobile',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/login')) {
            if (++attempts == 1) return http.Response('{}', 401);
            return jsonResponse({'token': 'fictional-token', 'data': profile});
          }
          profileRequests++;
          return http.Response('{}', 401);
        }),
      );
      addTearDown(source.dispose);

      await expectLater(
        source.signIn('Alex', 'wrong'),
        throwsA(
          isA<DataSourceException>().having(
            (e) => e.sessionExpired,
            'expired',
            false,
          ),
        ),
      );
      await source.signIn('Alex', 'example');
      await expectLater(source.readProfile(), throwsA(expiredSession));
      await expectLater(source.readProfile(), throwsA(expiredSession));
      expect(profileRequests, 1);
    },
  );

  test('private or missing posts do not expire the session', () async {
    final source = ApiDataSource(
      'https://example.com/api/mobile',
      client: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/login')) {
          return jsonResponse({'token': 'fictional-token', 'data': profile});
        }
        if (path.endsWith('/31')) return http.Response('{}', 403);
        if (path.endsWith('/999')) return http.Response('{}', 404);
        return jsonResponse({'data': profile});
      }),
    );
    addTearDown(source.dispose);
    await source.signIn('Alex', 'example');
    for (final id in [31, 999]) {
      await expectLater(
        source.readPost(id),
        throwsA(
          isA<DataSourceException>().having(
            (e) => e.sessionExpired,
            'expired',
            false,
          ),
        ),
      );
    }
    expect((await source.readProfile()).id, 1);
  });

  test('HTTP works only for a local address with explicit opt-in', () async {
    for (final (url, allowHttp, succeeds) in [
      ('http://10.0.2.2:8080/api/mobile', false, false),
      ('http://10.0.2.2:8080/api/mobile', true, true),
      ('http://192.168.1.42:8080/api/mobile', true, true),
      ('http://[::1]:8080/api/mobile', true, true),
      ('http://example.com/api/mobile', true, false),
      ('https://example.com/api/mobile', false, true),
    ]) {
      var contacted = false;
      final source = ApiDataSource(
        url,
        allowInsecureLocalHttp: allowHttp,
        client: MockClient((_) async {
          contacted = true;
          return jsonResponse({'token': 'fictional-token', 'data': profile});
        }),
      );
      addTearDown(source.dispose);
      final result = source.signIn('Alex', 'example');
      if (succeeds) {
        expect((await result).id, 1);
      } else {
        await expectLater(result, throwsA(isA<DataSourceException>()));
      }
      expect(contacted, succeeds, reason: url);
    }
  });

  test(
    'timeouts, network failures, and malformed responses report an error',
    () async {
      for (final (response, message)
          in <(Future<http.Response> Function(), String)>[
            (() async => throw TimeoutException('test timeout'), 'too long'),
            (
              () async => throw http.ClientException('test disconnect'),
              'Unable to connect',
            ),
            (() async => http.Response('[1]', 200), 'unreadable'),
          ]) {
        final source = ApiDataSource(
          'https://example.com/api/mobile',
          client: MockClient((_) => response()),
        );
        addTearDown(source.dispose);
        await expectLater(
          source.signIn('Alex', 'example'),
          throwsA(
            isA<DataSourceException>().having(
              (e) => e.message,
              'message',
              contains(message),
            ),
          ),
        );
      }
    },
  );

  test('a pending login cannot restore a session after local logout', () async {
    final response = Completer<http.Response>();
    final source = ApiDataSource(
      'https://example.com/api/mobile',
      client: MockClient((_) => response.future),
    );
    addTearDown(source.dispose);
    final login = source.signIn('Alex', 'example');
    await source.signOut();
    response.complete(
      jsonResponse({'token': 'fictional-token', 'data': profile}),
    );
    await expectLater(login, throwsA(expiredSession));
    await expectLater(source.readProfile(), throwsA(expiredSession));
  });
}

final expiredSession = isA<DataSourceException>().having(
  (error) => error.sessionExpired,
  'expired',
  true,
);
