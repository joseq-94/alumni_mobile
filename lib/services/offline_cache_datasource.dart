import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/feed_page.dart';
import '../models/feed_post.dart';
import '../models/user_profile.dart';
import 'alumni_datasource.dart';

// Tells the screens whether they are showing data saved on this device.
class OfflineStatus extends ChangeNotifier {
  bool _showingSavedData = false;
  bool get showingSavedData => _showingSavedData;

  void _update(bool value) {
    if (_showingSavedData == value) return;
    _showingSavedData = value;
    notifyListeners();
  }
}

// Wraps the API source without changing it. Successful results are saved on
// the device; when the connection fails, the last saved profile, feed pages
// and opened posts are returned instead. Profile changes are never saved
// offline, and everything saved is deleted at logout.
class OfflineCacheDataSource implements AlumniDataSource {
  OfflineCacheDataSource(this._inner, this._box, this.status);

  static const boxName = 'alumni_offline_cache';
  static const offlineSaveMessage = "You're offline. Connect to save changes.";

  // ApiDataSource reports network failures with these messages. The tests in
  // test/offline_cache_test.dart check them against the real ApiDataSource.
  static const _offlineMessagePrefixes = [
    'Unable to connect.',
    'The request took too long.',
  ];

  final AlumniDataSource _inner;
  final Box<dynamic> _box;
  final OfflineStatus status;

  // Returns null if device storage cannot be opened; the app then runs online
  // without a cache.
  static Future<OfflineCacheDataSource?> open(
    AlumniDataSource inner,
    OfflineStatus status,
  ) async {
    try {
      return OfflineCacheDataSource(inner, await Hive.openBox(boxName), status);
    } catch (_) {
      return null;
    }
  }

  static bool isOfflineError(Object error) =>
      error is DataSourceException &&
      !error.sessionExpired &&
      _offlineMessagePrefixes.any((prefix) => error.message.startsWith(prefix));

  // A failed cache write must never break a successful online request.
  static Future<void> _safely(Future<Object?> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Keep going without saving.
    }
  }

  static Map<String, dynamic> _map(Object? value) =>
      Map<String, dynamic>.from(value as Map);

  static Map<String, dynamic> _profileMap(UserProfile profile) => {
    'id': profile.id,
    'name': profile.name,
    'email': profile.email,
    'bio': profile.bio,
    'picture_url': profile.pictureUrl,
  };

  // Saved data belongs to one account; a different account starts empty.
  Future<void> _remember(UserProfile profile) async {
    if (_box.get('owner') != profile.id) {
      await _box.clear();
      await _box.put('owner', profile.id);
    }
    await _box.put('profile', _profileMap(profile));
  }

  // Try the API first. Only a network failure falls back to the saved copy;
  // every other error (expired session, validation, 404) is passed on.
  Future<T> _readWithCache<T>({
    required Future<T> Function() request,
    required Future<void> Function(T result) save,
    required T? Function() saved,
  }) async {
    try {
      final result = await request();
      await _safely(() => save(result));
      status._update(false);
      return result;
    } catch (error) {
      if (!isOfflineError(error)) rethrow;
      T? copy;
      try {
        copy = saved();
      } catch (_) {
        copy = null;
      }
      if (copy == null) rethrow;
      status._update(true);
      return copy;
    }
  }

  // Used at startup with ApiDataSource.restoreSession. Restoring still needs a
  // connection, because Laravel must confirm the saved token.
  Future<UserProfile?> restoreSession(
    Future<UserProfile?> Function() restore,
  ) async {
    final profile = await restore();
    if (profile == null) {
      await _safely(_box.clear);
    } else {
      await _safely(() => _remember(profile));
      status._update(false);
    }
    return profile;
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    final profile = await _inner.signIn(email, password);
    await _safely(() => _remember(profile));
    status._update(false);
    return profile;
  }

  @override
  Future<void> signOut() async {
    status._update(false);
    await _safely(_box.clear);
    await _inner.signOut();
  }

  @override
  Future<UserProfile> readProfile() => _readWithCache(
    request: _inner.readProfile,
    save: _remember,
    saved: () {
      final value = _box.get('profile');
      return value == null ? null : UserProfile.fromMap(_map(value));
    },
  );

  @override
  Future<UserProfile> updateProfile(String name, String bio) async {
    try {
      final updated = await _inner.updateProfile(name, bio);
      await _safely(() => _remember(updated));
      status._update(false);
      return updated;
    } catch (error) {
      if (!isOfflineError(error)) rethrow;
      throw DataSourceException(offlineSaveMessage);
    }
  }

  @override
  Future<FeedPage> readFeed(int page) => _readWithCache(
    request: () => _inner.readFeed(page),
    save: (result) async {
      // A fresh first page replaces the saved feed so old pages do not mix in.
      if (page == 1) {
        await _box.deleteAll(
          _box.keys
              .where((key) => key is String && key.startsWith('feed:'))
              .toList(),
        );
      }
      await _box.put('feed:$page', {
        'posts': [for (final post in result.posts) post.toMap()],
        'next_page': result.nextPage,
      });
    },
    saved: () {
      final value = _box.get('feed:$page');
      if (value == null) return null;
      final saved = _map(value);
      return FeedPage(
        posts: [
          for (final post in saved['posts'] as List)
            FeedPost.fromMap(_map(post)),
        ],
        nextPage: saved['next_page'] as int?,
      );
    },
  );

  @override
  Future<FeedPost> readPost(int id) => _readWithCache(
    request: () => _inner.readPost(id),
    save: (post) => _box.put('post:$id', post.toMap()),
    saved: () {
      final value = _box.get('post:$id');
      return value == null ? null : FeedPost.fromMap(_map(value));
    },
  );

  @override
  void dispose() {
    _inner.dispose();
    _box.close();
  }
}
