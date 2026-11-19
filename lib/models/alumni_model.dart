import 'dart:collection';
import 'package:flutter/material.dart';
import '../services/alumni_datasource.dart';
import 'feed_post.dart';
import 'user_profile.dart';

class AlumniModel extends ChangeNotifier {
  final AlumniDataSource dataSource;
  AlumniModel(this.dataSource);
  UserProfile? profile;
  final List<FeedPost> _posts = [];
  UnmodifiableListView<FeedPost> get posts => UnmodifiableListView(_posts);
  bool signingIn = false;
  bool loadingFeed = false;
  bool savingProfile = false;
  String? signInError;
  String? feedError;
  String? profileError;
  int? nextPage;
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

  Future<void> signIn(String email, String password) async {
    if (signingIn) return;
    final session = ++_session;
    signingIn = true;
    signInError = null;
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
