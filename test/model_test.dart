import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:alumni_mobile/models/alumni_model.dart';
import 'package:alumni_mobile/models/feed_page.dart';
import 'package:alumni_mobile/models/user_profile.dart';
import 'package:alumni_mobile/services/demo_datasource.dart';

class DelayedSource extends DemoDataSource {
  Completer<FeedPage>? pending;
  @override
  Future<FeedPage> readFeed(int page) {
    if (pending != null) return pending!.future;
    return super.readFeed(page);
  }
}

void main() {
  test('validation boundaries and editable fields', () {
    expect(UserProfile.validateName('  '), isNotNull);
    expect(UserProfile.validateName('x' * 255), isNull);
    expect(UserProfile.validateName('x' * 256), isNotNull);
    expect(UserProfile.validateBio('x' * 1000), isNull);
    expect(UserProfile.validateBio('x' * 1001), isNotNull);
    final user = UserProfile.fromMap({
      'id': 1,
      'name': 'Alex',
      'email': 'a@example.com',
    });
    expect(user.bio, '');
    expect(user.toMap(), {'name': 'Alex', 'bio': ''});
  });
  test(
    'pagination, refresh, profile persistence and account separation',
    () async {
      final model = AlumniModel(DemoDataSource());
      await model.signIn('admin', 'wrong');
      expect(model.profile, isNull);
      expect(model.signInError, isNotNull);
      await model.signIn('admin', 'Password1');
      expect(model.posts.length, 20);
      await model.loadMore();
      expect(model.posts.length, 30);
      expect(model.posts.map((p) => p.id).toSet().length, 30);
      expect(model.nextPage, isNull);
      await model.refreshFeed();
      expect(model.posts.length, 20);
      expect(await model.saveProfile('  New name  ', 'Summary'), isTrue);
      expect(model.profile!.name, 'New name');
      await model.signOut();
      expect(model.posts, isEmpty);
      await model.signIn('sam@example.com', 'Password1');
      expect(model.profile!.name, 'Sam Taylor');
      await model.signOut();
      await model.signIn('admin', 'Password1');
      expect(model.profile!.name, 'New name');
      model.dispose();
    },
  );
  test('late feed response cannot restore data after logout', () async {
    final source = DelayedSource();
    final model = AlumniModel(source);
    await model.signIn('admin', 'Password1');
    final oldPosts = model.posts.toList();
    source.pending = Completer<FeedPage>();
    final load = model.refreshFeed();
    await model.signOut();
    source.pending!.complete(FeedPage(posts: oldPosts));
    await load;
    expect(model.posts, isEmpty);
    expect(model.profile, isNull);
    model.dispose();
  });
}
