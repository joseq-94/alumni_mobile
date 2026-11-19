import 'package:hive/hive.dart';
import '../models/feed_page.dart';
import '../models/feed_post.dart';
import '../models/user_profile.dart';
import 'alumni_datasource.dart';
import 'demo_datasource.dart';

// Hive is initialised at startup by PreferencesService.
// Plain maps keep storage simple and avoid generated adapters.
class HiveDataSource implements AlumniDataSource {
  final Box<dynamic> _profiles;
  final Box<dynamic> _posts;
  String? _email;

  HiveDataSource._(this._profiles, this._posts);

  static Future<HiveDataSource> createAsync() async {
    final profiles = await Hive.openBox('alumni_profiles');
    final posts = await Hive.openBox('alumni_posts');
    final source = HiveDataSource._(profiles, posts);
    for (final user in DemoDataSource.seedProfiles().values) {
      if (!profiles.containsKey(user.email)) {
        await profiles.put(user.email, source._profileMap(user));
      }
    }
    if (posts.isEmpty) {
      for (final post in DemoDataSource.seedPosts()) {
        await posts.put(post.id, post.toMap());
      }
    }
    return source;
  }

  Map<String, dynamic> _profileMap(UserProfile user) => {
    'id': user.id,
    'name': user.name,
    'email': user.email,
    'bio': user.bio,
    'picture_url': user.pictureUrl,
  };

  void _checkSession() {
    if (_email == null) {
      throw DataSourceException('Please sign in again.', sessionExpired: true);
    }
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    final login = email.trim().toLowerCase();
    final key = login == 'admin' ? 'admin@example.com' : login;
    // Local demo authentication only. No passwords or tokens are stored in Hive.
    if (!_profiles.containsKey(key) || password != 'Password1') {
      throw DataSourceException('Check your username and password.');
    }
    _email = key;
    return readProfile();
  }

  @override
  Future<void> signOut() async {
    _email = null;
  }

  @override
  Future<UserProfile> readProfile() async {
    _checkSession();
    return UserProfile.fromMap(
      Map<String, dynamic>.from(_profiles.get(_email) as Map),
    );
  }

  @override
  Future<UserProfile> updateProfile(String name, String bio) async {
    final current = await readProfile();
    final error =
        UserProfile.validateName(name) ?? UserProfile.validateBio(bio);
    if (error != null) throw DataSourceException(error);
    final updated = UserProfile(
      id: current.id,
      name: name.trim(),
      email: current.email,
      bio: bio,
      pictureUrl: current.pictureUrl,
    );
    await _profiles.put(current.email, _profileMap(updated));
    return updated;
  }

  @override
  Future<FeedPage> readFeed(int page) async {
    _checkSession();
    if (page < 1) throw DataSourceException('Invalid feed page.');
    final posts = _posts.values
        .map((item) => FeedPost.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
    posts.sort((a, b) {
      final dateOrder = b.createdAt.compareTo(a.createdAt);
      return dateOrder == 0 ? b.id.compareTo(a.id) : dateOrder;
    });
    final start = (page - 1) * 20;
    return FeedPage(
      posts: posts.skip(start).take(20).toList(),
      nextPage: start + 20 < posts.length ? page + 1 : null,
    );
  }

  @override
  Future<FeedPost> readPost(int id) async {
    _checkSession();
    final item = _posts.get(id);
    if (item == null) {
      throw DataSourceException('This post is no longer available.');
    }
    return FeedPost.fromMap(Map<String, dynamic>.from(item as Map));
  }

  Future<void> close() async {
    _email = null;
    await _profiles.close();
    await _posts.close();
  }

  @override
  void dispose() {
    close();
  }
}
