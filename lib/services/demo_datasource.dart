import '../models/feed_page.dart';
import '../models/feed_post.dart';
import '../models/user_profile.dart';
import 'alumni_datasource.dart';

class DemoDataSource implements AlumniDataSource {
  final Map<String, UserProfile> _users = seedProfiles();
  static Map<String, UserProfile> seedProfiles() => {
    'admin@example.com': UserProfile(
      id: 1,
      name: 'admin',
      email: 'admin@example.com',
      bio: 'IT graduate interested in mobile apps and community projects.',
    ),
    'sam@example.com': UserProfile(
      id: 2,
      name: 'Sam Taylor',
      email: 'sam@example.com',
    ),
  };
  String? _email;
  final List<FeedPost> _posts = seedPosts();
  static List<FeedPost> seedPosts() => List.generate(30, (index) {
    const titles = [
      'Welcome to the alumni network',
      'Stay connected with your community',
      'Learning beyond graduation',
      'A place to share our progress',
      'Your next chapter',
    ];
    const bodies = [
      'Welcome to our alumni community. Read the latest updates and keep your profile current. We look forward to staying connected as you take your next steps.',
      'Our graduates bring a wide range of skills and experiences. This feed is a simple place to keep up with news from the alumni community.',
      'Learning continues after graduation. Keep practising your skills, exploring new ideas and supporting other graduates as they learn.',
      'Every small step counts. Take time to reflect on what you have learned and the skills you would like to develop next.',
      'Your professional summary helps describe your interests. You can update your name and summary from Settings at any time.',
    ];
    return FeedPost(
      id: 30 - index,
      title: titles[index % 5],
      body: bodies[index % 5],
      authorName: 'Alumni team',
      createdAt: DateTime.utc(2026, 10, 30).subtract(Duration(days: index)),
    );
  });
  void _checkSession() {
    if (_email == null) {
      throw DataSourceException('Please sign in again.', sessionExpired: true);
    }
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    final login = email.trim().toLowerCase();
    final user = _users[login == 'admin' ? 'admin@example.com' : login];
    if (user == null || password != 'Password1') {
      throw DataSourceException('Check your email and password.');
    }
    _email = user.email;
    return user;
  }

  @override
  Future<void> signOut() async {
    _email = null;
  }

  @override
  Future<UserProfile> readProfile() async {
    _checkSession();
    return _users[_email]!;
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
    _users[current.email] = updated;
    return updated;
  }

  @override
  Future<FeedPage> readFeed(int page) async {
    _checkSession();
    final start = (page - 1) * 20;
    return FeedPage(
      posts: _posts.skip(start).take(20).toList(),
      nextPage: start + 20 < _posts.length ? page + 1 : null,
    );
  }

  @override
  Future<FeedPost> readPost(int id) async {
    _checkSession();
    for (final post in _posts) {
      if (post.id == id) return post;
    }
    throw DataSourceException('This post is no longer available.');
  }

  @override
  void dispose() {
    _email = null;
  }
}
