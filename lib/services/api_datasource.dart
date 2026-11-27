import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/feed_page.dart';
import '../models/feed_post.dart';
import '../models/user_profile.dart';
import 'alumni_datasource.dart';

// Send JSON requests to the API and turn responses into profile/post objects.
class ApiDataSource implements AlumniDataSource {
  ApiDataSource(
    String baseUrl, {
    http.Client? client,
    this._allowInsecureLocalHttp = false,
    this._storage,
  }) : _baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final bool _allowInsecureLocalHttp;
  final FlutterSecureStorage? _storage;
  String? _token;
  Future<void> _storageWrites = Future<void>.value();
  // Prevent a slow login response from restoring a session after logout.
  int _sessionVersion = 0;

  String get _tokenKey => 'alumni_token:$_baseUrl';

  Future<void> _saveToken(String? token) {
    final storage = _storage;
    if (storage == null) return Future<void>.value();

    // Keep a pending login write from overwriting a subsequent logout.
    return _storageWrites = _storageWrites.then((_) async {
      try {
        await storage.write(key: _tokenKey, value: token);
      } on PlatformException {
        // Keep the session in memory if secure storage is unavailable.
      }
    });
  }

  String _requireToken() {
    return _token ??
        (throw DataSourceException(
          'Please sign in again.',
          sessionExpired: true,
        ));
  }

  Uri _endpoint(String path) {
    final base = Uri.tryParse(_baseUrl);
    if (base == null ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw DataSourceException('Set a valid API base URL.');
    }
    final localHttp =
        _allowInsecureLocalHttp &&
        base.scheme == 'http' &&
        _isLocalHost(base.host);
    if (base.scheme != 'https' && !localHttp) {
      throw DataSourceException('The API address must use HTTPS.');
    }
    return Uri.parse('$_baseUrl$path');
  }

  static bool _isLocalHost(String host) {
    if (host == 'localhost' || host == '::1') return true;
    final parts = host.split('.').map(int.tryParse).toList();
    if (parts.any((part) => part == null || part < 0 || part > 255)) {
      return false;
    }
    return switch (parts) {
      [10, _, _, _] || [127, _, _, _] || [192, 168, _, _] => true,
      [172, final second?, _, _] => second >= 16 && second <= 31,
      _ => false,
    };
  }

  // One shared request method handles JSON, headers, timeouts and readable errors.
  Future<T> _request<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) read, {
    Map<String, Object?>? body,
    String? bearer,
  }) async {
    final request = http.Request(method, _endpoint(path))
      ..followRedirects = false
      ..headers['Accept'] = 'application/json';
    if (bearer != null) request.headers['Authorization'] = 'Bearer $bearer';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 10));
      switch (response.statusCode) {
        // A failed login is different from an expired token on a signed-in request.
        case 401:
          if (bearer == null) {
            throw DataSourceException('Check your email and password.');
          }
          if (_token == bearer) {
            _token = null;
            await _saveToken(null);
          }
          throw DataSourceException(
            'Your session has expired.',
            sessionExpired: true,
          );
        case 403:
          throw DataSourceException(
            bearer == null
                ? 'Verify your email on the website before signing in.'
                : 'You do not have access. Check your email verification on the website.',
          );
        case 404:
          throw DataSourceException('This item is no longer available.');
        case 422:
          throw DataSourceException(_validationMessage(response));
        case 429:
          throw DataSourceException(
            'Too many attempts. Wait a minute and try again.',
          );
        case < 200 || >= 300:
          throw DataSourceException(
            'The server could not complete the request. Try again.',
          );
      }
      final payload = response.bodyBytes.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return read(payload);
    } on TimeoutException {
      throw DataSourceException('The request took too long. Please try again.');
    } on http.ClientException {
      throw DataSourceException(
        'Unable to connect. Check your connection and try again.',
      );
    } on FormatException {
      throw DataSourceException('The server returned an unreadable response.');
    } on TypeError {
      throw DataSourceException('The server returned an unreadable response.');
    }
  }

  static String _validationMessage(http.Response response) {
    // Laravel returns field errors as lists under 'errors'.
    try {
      final payload = jsonDecode(utf8.decode(response.bodyBytes));
      if (payload is Map && payload['errors'] is Map) {
        for (final messages in (payload['errors'] as Map).values) {
          if (messages is List &&
              messages.isNotEmpty &&
              messages.first is String) {
            return messages.first as String;
          }
        }
      }
    } on FormatException {
      // Use a readable fallback if the response is not JSON.
    }
    return 'Check the submitted information and try again.';
  }

  static UserProfile _profile(Map<String, dynamic> response) =>
      UserProfile.fromMap(response['data'] as Map<String, dynamic>);

  @override
  Future<UserProfile> signIn(String email, String password) async {
    final version = ++_sessionVersion;
    _token = null;
    await _saveToken(null);
    final signedIn = await _request('POST', '/login', (payload) {
      final token = payload['token'] as String;
      if (token.trim().isEmpty) throw const FormatException();
      return (token: token, profile: _profile(payload));
    }, body: {'login': email.trim(), 'password': password});
    if (version != _sessionVersion) {
      throw DataSourceException('Please sign in again.', sessionExpired: true);
    }
    _token = signedIn.token;
    await _saveToken(signedIn.token);
    if (version != _sessionVersion) {
      throw DataSourceException('Please sign in again.', sessionExpired: true);
    }
    return signedIn.profile;
  }

  @override
  Future<void> signOut() async {
    ++_sessionVersion;
    // Forget the token locally first, then ask the server to revoke it.
    final previous = _token;
    _token = null;
    await _saveToken(null);
    if (previous == null) return;
    try {
      await _request<void>('POST', '/logout', (_) {}, bearer: previous);
    } on DataSourceException catch (error) {
      if (!error.sessionExpired) rethrow;
    }
  }

  @override
  Future<UserProfile> readProfile() async =>
      _request('GET', '/me', _profile, bearer: _requireToken());

  @override
  Future<UserProfile> updateProfile(String name, String bio) async {
    final error =
        UserProfile.validateName(name) ?? UserProfile.validateBio(bio);
    if (error != null) throw DataSourceException(error);
    return _request(
      'PATCH',
      '/me',
      _profile,
      body: {'name': name.trim(), 'bio': bio},
      bearer: _requireToken(),
    );
  }

  @override
  Future<FeedPage> readFeed(int page) async => _request(
    'GET',
    '/feed?page=$page',
    (result) => FeedPage(
      posts: (result['data'] as List)
          .map((item) => FeedPost.fromMap(item as Map<String, dynamic>))
          .toList(),
      nextPage: result['next_page'] as int?,
    ),
    bearer: _requireToken(),
  );

  @override
  Future<FeedPost> readPost(int id) async => _request(
    'GET',
    '/feed/$id',
    (result) => FeedPost.fromMap(result['data'] as Map<String, dynamic>),
    bearer: _requireToken(),
  );

  @override
  void dispose() {
    ++_sessionVersion;
    _token = null;
    _client.close();
  }
}
