import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:alumni_mobile/models/feed_post.dart';
import 'package:alumni_mobile/models/user_profile.dart';
import 'package:alumni_mobile/services/demo_datasource.dart';

const _pageSize = 20;
const _routes = '/api/mobile';
const _sessionDuration = Duration(minutes: 30);

Future<void> main() async {
  final env = Platform.environment;
  final server = await AssessmentServer.start(
    host: env['ASSESSMENT_API_HOST'] ?? '127.0.0.1',
    port: int.parse(env['ASSESSMENT_API_PORT'] ?? '8080'),
    dataFile: File(
      env['ASSESSMENT_API_DATA'] ?? 'tool/runtime/assessment.json',
    ),
    webOrigin: env['ASSESSMENT_API_WEB_ORIGIN'],
  );
  stdout.writeln(
    'Assessment API listening at http://${server.address}:${server.port}$_routes',
  );

  final stopped = Completer<void>();
  void stop(ProcessSignal _) {
    if (!stopped.isCompleted) stopped.complete();
  }

  final signals = [
    ProcessSignal.sigint.watch().listen(stop),
    if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen(stop),
  ];
  try {
    await stopped.future;
  } finally {
    for (final signal in signals) {
      await signal.cancel();
    }
    await server.close();
    stdout.writeln('Assessment API stopped.');
  }
}

class AssessmentServer {
  AssessmentServer._(
    this._server,
    this._dataFile,
    this._profiles,
    this._posts,
    this._webOrigin,
    this._clock,
  ) {
    _publicPosts =
        [
          for (final post in _posts)
            if (post['visibility'] == 'public') FeedPost.fromMap(post),
        ]..sort((a, b) {
          final byDate = b.createdAt.compareTo(a.createdAt);
          return byDate == 0 ? b.id.compareTo(a.id) : byDate;
        });
    _requests = _serve();
  }

  final HttpServer _server;
  final File _dataFile;
  final Map<int, UserProfile> _profiles;
  final List<Map<String, dynamic>> _posts;
  final String? _webOrigin;
  final DateTime Function() _clock;
  final _random = Random.secure();
  final _sessions = <String, ({int userId, DateTime expiresAt})>{};
  late final List<FeedPost> _publicPosts;
  late final Future<void> _requests;

  String get address => _server.address.address;
  int get port => _server.port;

  static Future<AssessmentServer> start({
    String host = '127.0.0.1',
    int port = 0,
    required File dataFile,
    String? webOrigin,
    DateTime Function()? clock,
  }) async {
    final profiles = <int, UserProfile>{};
    final List<Map<String, dynamic>> posts;
    if (await dataFile.exists()) {
      final data =
          jsonDecode(await dataFile.readAsString()) as Map<String, dynamic>;
      for (final record in data['profiles'] as List) {
        final profile = UserProfile.fromMap(record as Map<String, dynamic>);
        profiles[profile.id] = profile;
      }
      posts = (data['posts'] as List).cast<Map<String, dynamic>>();
    } else {
      for (final profile in DemoDataSource.seedProfiles().values) {
        profiles[profile.id] = profile;
      }
      posts = [
        for (final post in DemoDataSource.seedPosts())
          {...post.toMap(), 'visibility': 'public'},
        {
          ...FeedPost(
            id: 31,
            title: 'Private assessment example',
            body:
                'This fictional post is visible only to the assessment server.',
            authorName: 'Alumni team',
            createdAt: DateTime.utc(2026, 10, 31),
          ).toMap(),
          'visibility': 'private',
        },
      ];
      await dataFile.parent.create(recursive: true);
      await _writeDatabase(dataFile, profiles, posts);
    }

    final server = await HttpServer.bind(host, port);
    return AssessmentServer._(
      server,
      dataFile,
      profiles,
      posts,
      webOrigin,
      clock ?? DateTime.now,
    );
  }

  Future<void> close() async {
    await _server.close(force: true);
    await _requests;
    _sessions.clear();
  }

  // Process each request in order so concurrent edits cannot overwrite
  // each other's persisted changes.
  Future<void> _serve() async {
    await for (final request in _server) {
      try {
        await _handle(request);
      } on SocketException {
        // A client disconnect must not stop the server.
      } on HttpException {
        // A client disconnect must not stop the server.
      }
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    final origin = request.headers.value('origin');
    if (_webOrigin != null && origin == _webOrigin) {
      response.headers.set('Access-Control-Allow-Origin', origin!);
      response.headers.set('Vary', 'Origin');
      response.headers.set(
        'Access-Control-Allow-Headers',
        'Authorization, Content-Type',
      );
      response.headers.set(
        'Access-Control-Allow-Methods',
        'GET, POST, PATCH, OPTIONS',
      );
    }
    try {
      final body = await _route(request);
      if (body == null) {
        response.statusCode = HttpStatus.noContent;
      } else {
        _json(response, HttpStatus.ok, body);
      }
    } on _Problem catch (error) {
      _json(response, error.status, {'error': error.message});
    } on FormatException {
      _json(response, HttpStatus.badRequest, {'error': 'Send a JSON object.'});
    } catch (error) {
      stderr.writeln('Assessment API request failed (${error.runtimeType}).');
      _json(response, HttpStatus.internalServerError, {
        'error': 'The request could not be completed.',
      });
    } finally {
      await response.close();
    }
  }

  Future<Map<String, Object?>?> _route(HttpRequest request) async {
    final segments = request.uri.pathSegments;
    if (segments case ['api', 'mobile', ...final resource]) {
      if (request.method == 'OPTIONS') return null;
      if ((request.method, resource) case ('POST', ['login'])) {
        return _login(await _readObject(request));
      }

      final authorization = request.headers.value(
        HttpHeaders.authorizationHeader,
      );
      final token = authorization != null && authorization.startsWith('Bearer ')
          ? authorization.substring('Bearer '.length)
          : null;
      final session = _sessions[token];
      if (session == null || !session.expiresAt.isAfter(_clock())) {
        _sessions.remove(token);
        throw const _Problem(HttpStatus.unauthorized, 'Please sign in again.');
      }
      final userId = session.userId;
      final profile = _profiles[userId]!;
      switch ((request.method, resource)) {
        case ('POST', ['logout']):
          _sessions.remove(token);
          return null;
        case ('GET', ['me']):
          return {'data': _profileJson(profile)};
        case ('PATCH', ['me']):
          return {
            'data': await _saveProfile(profile, await _readObject(request)),
          };
        case ('GET', ['feed']):
          final page = int.tryParse(request.uri.queryParameters['page'] ?? '1');
          if (page == null || page < 1) {
            throw const _Problem(
              HttpStatus.unprocessableEntity,
              'Use a positive page number.',
            );
          }
          return _feedPage(page);
        case ('GET', ['feed', final id]):
          for (final post in _publicPosts) {
            if (post.id.toString() == id) return {'data': post.toMap()};
          }
      }
    }
    throw const _Problem(
      HttpStatus.notFound,
      'This item is no longer available.',
    );
  }

  Map<String, Object?> _login(Map<String, dynamic> body) {
    final login = body['login'];
    final password = body['password'];
    if (login is! String || password is! String) {
      throw const _Problem(HttpStatus.badRequest, 'Send a login and password.');
    }
    final username = login.trim().toLowerCase();
    final email = username == 'admin' ? 'admin@example.com' : username;
    for (final profile in _profiles.values) {
      if (profile.email == email && password == 'Password1') {
        final now = _clock();
        _sessions.removeWhere((_, session) => !session.expiresAt.isAfter(now));
        final token = base64Url.encode(
          List.generate(32, (_) => _random.nextInt(256)),
        );
        _sessions[token] = (
          userId: profile.id,
          expiresAt: now.add(_sessionDuration),
        );
        return {'token': token, 'data': _profileJson(profile)};
      }
    }
    throw const _Problem(
      HttpStatus.unauthorized,
      'Check your username and password.',
    );
  }

  Future<Map<String, dynamic>> _saveProfile(
    UserProfile current,
    Map<String, dynamic> changes,
  ) async {
    if (changes.isEmpty ||
        changes.entries.any(
          (entry) =>
              (entry.key != 'name' && entry.key != 'bio') ||
              entry.value is! String,
        )) {
      throw const _Problem(
        HttpStatus.unprocessableEntity,
        'Only name and bio can be edited.',
      );
    }
    final name = (changes['name'] as String? ?? current.name).trim();
    final bio = changes['bio'] as String? ?? current.bio;
    final error =
        UserProfile.validateName(name) ?? UserProfile.validateBio(bio);
    if (error != null) throw _Problem(HttpStatus.unprocessableEntity, error);

    final updated = UserProfile(
      id: current.id,
      name: name,
      email: current.email,
      bio: bio,
      pictureUrl: current.pictureUrl,
    );
    final profiles = {..._profiles, updated.id: updated};
    await _writeDatabase(_dataFile, profiles, _posts);
    _profiles[updated.id] = updated;
    return _profileJson(updated);
  }

  Map<String, Object?> _feedPage(int page) {
    final pages = (_publicPosts.length + _pageSize - 1) ~/ _pageSize;
    return {
      'data': page > pages
          ? []
          : _publicPosts
                .skip((page - 1) * _pageSize)
                .take(_pageSize)
                .map((post) => post.toMap())
                .toList(),
      'next_page': page < pages ? page + 1 : null,
    };
  }

  static Future<Map<String, dynamic>> _readObject(HttpRequest request) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in request) {
      if (bytes.length + chunk.length > 16384) {
        throw const _Problem(
          HttpStatus.requestEntityTooLarge,
          'Request is too large.',
        );
      }
      bytes.add(chunk);
    }
    final decoded = jsonDecode(utf8.decode(bytes.takeBytes()));
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }

  static void _json(
    HttpResponse response,
    int status,
    Map<String, Object?> body,
  ) {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
  }

  static Map<String, dynamic> _profileJson(UserProfile profile) => {
    'id': profile.id,
    'email': profile.email,
    'picture_url': profile.pictureUrl,
    ...profile.toMap(),
  };

  static Future<void> _writeDatabase(
    File file,
    Map<int, UserProfile> profiles,
    List<Map<String, dynamic>> posts,
  ) async {
    final next = File('${file.path}.tmp');
    await next.writeAsString(
      jsonEncode({
        'profiles': profiles.values.map(_profileJson).toList(),
        'posts': posts,
      }),
      flush: true,
    );
    await next.rename(file.path);
  }
}

class _Problem implements Exception {
  const _Problem(this.status, this.message);

  final int status;
  final String message;
}
