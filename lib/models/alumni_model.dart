import 'dart:collection';
import 'package:flutter/material.dart';
import '../services/alumni_datasource.dart';
import 'feed_post.dart';
import 'user_profile.dart';

// Shared account and feed state. notifyListeners() tells listening screens to rebuild.
class AlumniModel extends ChangeNotifier {
  final AlumniDataSource dataSource;
  final Future<UserProfile?> Function()? _restoreSavedSession;
  AlumniModel(this.dataSource, {this._restoreSavedSession});
  UserProfile? profile;
  final List<FeedPost> _posts = [];
  UnmodifiableListView<FeedPost> get posts => UnmodifiableListView(_posts);
  bool restoringSession = false;
  bool signingIn = false;
  bool loadingFeed = false;
  bool savingProfile = false;
  String? sessionRestoreError;
  String? signInError;
  String? feedError;
  String? profileError;
  int? nextPage;
  // Ignore old requests after logout or another login, even if they finish later.
  int _session = 0;
  bool _disposed = false;
  bool _isCurrent(int session) => !_disposed && session == _session;
  String _message(Object error) {
    if (error is DataSourceException) {
      if (error.sessionExpired) signOut();
      return error.message;
    }
    return 'Unable to connect. Please try again.';
  }

  Future<void> restoreSession() async {
    final restore = _restoreSavedSession;
    if (restore == null || restoringSession || signingIn || profile != null) {
      return;
    }

    final session = ++_session;
    restoringSession = true;
    sessionRestoreError = null;
    notifyListeners();
    try {
      final user = await restore();
      if (!_isCurrent(session)) return;
      profile = user;
    } catch (error) {
      if (!_isCurrent(session)) return;
      sessionRestoreError = error is DataSourceException
          ? error.message
          : 'Unable to restore your session. Please try again.';
    }
    restoringSession = false;
    notifyListeners();
    if (profile != null) await refreshFeed();
  }

  Future<void> signIn(String email, String password) async {
    if (signingIn || restoringSession) return;
    final session = ++_session;
    signingIn = true;
    sessionRestoreError = null;
    signInError = null;
    // Show the busy state immediately, before waiting for the server.
    notifyListeners();
    try {
      final user = await dataSource.signIn(email, password);
      if (!_isCurrent(session)) return;
      profile = user;
    } catch (error) {
      if (!_isCurrent(session)) return;
      signInError = _message(error);
    }
    if (!_isCurrent(session)) return;
    signingIn = false;
    notifyListeners();
    if (profile != null) await refreshFeed();
  }

  Future<void> signOut() async {
    ++_session;
    profile = null;
    _posts.clear();
    nextPage = null;
    restoringSession = false;
    sessionRestoreError = null;
    signingIn = loadingFeed = savingProfile = false;
    signInError = feedError = profileError = null;
    if (!_disposed) notifyListeners();
    try {
      await dataSource.signOut();
    } catch (_) {
      // Clear local data even when the server cannot be reached.
    }
  }

  Future<void> refreshFeed() => _loadFeed(1);
  Future<void> loadMore() async {
    if (nextPage != null) await _loadFeed(nextPage!);
  }

  Future<void> _loadFeed(int page) async {
    if (loadingFeed || profile == null) return;
    final session = _session;
    loadingFeed = true;
    feedError = null;
    notifyListeners();
    try {
      final result = await dataSource.readFeed(page);
      if (!_isCurrent(session)) return;
      // Refresh replaces the feed; later pages append posts without duplicate IDs.
      if (page == 1) _posts.clear();
      for (final post in result.posts) {
        if (!_posts.any((item) => item.id == post.id)) _posts.add(post);
      }
      nextPage = result.nextPage;
    } catch (error) {
      if (!_isCurrent(session)) return;
      feedError = _message(error);
    }
    if (!_isCurrent(session)) return;
    loadingFeed = false;
    notifyListeners();
  }

  Future<bool> saveProfile(String name, String bio) async {
    if (savingProfile || profile == null) return false;
    final session = _session;
    savingProfile = true;
    profileError = null;
    notifyListeners();
    bool saved = false;
    try {
      final updated = await dataSource.updateProfile(name.trim(), bio);
      if (!_isCurrent(session)) return false;
      // Use the returned saved record so every profile display shows the same result.
      profile = updated;
      saved = true;
    } catch (error) {
      if (!_isCurrent(session)) return false;
      profileError = _message(error);
    }
    if (!_isCurrent(session)) return false;
    savingProfile = false;
    notifyListeners();
    return saved;
  }

  @override
  void dispose() {
    _disposed = true;
    ++_session;
    dataSource.dispose();
    super.dispose();
  }
}
