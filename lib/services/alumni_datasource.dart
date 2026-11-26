import '../models/feed_page.dart';
import '../models/feed_post.dart';
import '../models/user_profile.dart';

// Swap implementations in main.dart without changing screens.
// The common set of operations that API, Hive and in-memory sources must provide.
abstract class AlumniDataSource {
  Future<UserProfile> signIn(String email, String password);
  Future<void> signOut();
  Future<UserProfile> readProfile();
  Future<UserProfile> updateProfile(String name, String bio);
  Future<FeedPage> readFeed(int page);
  Future<FeedPost> readPost(int id);
  void dispose();
}

class DataSourceException implements Exception {
  final String message;
  final bool sessionExpired;
  DataSourceException(this.message, {this.sessionExpired = false});
  @override
  String toString() => message;
}
