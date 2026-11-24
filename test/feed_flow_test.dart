import 'dart:async';

import 'package:alumni_mobile/models/alumni_model.dart';
import 'package:alumni_mobile/models/feed_page.dart';
import 'package:alumni_mobile/models/feed_post.dart';
import 'package:alumni_mobile/services/alumni_datasource.dart';
import 'package:alumni_mobile/services/demo_datasource.dart';
import 'package:alumni_mobile/views/feed_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Small, controlled responses let us test failures without a running server.
class FeedTestSource extends DemoDataSource {
  Future<FeedPage> Function(int)? feedResponse;
  Future<FeedPost> Function(int)? postResponse;
  final requestedPages = <int>[];
  final requestedPosts = <int>[];

  @override
  Future<FeedPage> readFeed(int page) async {
    requestedPages.add(page);
    if (feedResponse != null) return feedResponse!(page);
    return FeedPage(posts: [samplePost(1)], nextPage: null);
  }

  @override
  Future<FeedPost> readPost(int id) async {
    requestedPosts.add(id);
    if (postResponse != null) return postResponse!(id);
    return samplePost(id);
  }
}

FeedPost samplePost(int id, {String? body}) => FeedPost(
  id: id,
  title: 'Post $id',
  body: body ?? 'Preview for post $id',
  authorName: 'Alumni team',
  createdAt: DateTime.utc(2026, 11, 1),
);

Future<AlumniModel> showFeed(WidgetTester tester, FeedTestSource source) async {
  final model = AlumniModel(source);
  addTearDown(model.dispose);
  await model.signIn('admin', 'Password1');
  await tester.pumpWidget(
    ChangeNotifierProvider<AlumniModel>.value(
      value: model,
      child: const MaterialApp(home: Scaffold(body: FeedPageView())),
    ),
  );
  await tester.pumpAndSettle();
  return model;
}

void main() {
  testWidgets('Empty feed shows a message and refresh shows loading', (
    tester,
  ) async {
    final source = FeedTestSource()
      ..feedResponse = (_) async => FeedPage(posts: [], nextPage: null);
    await showFeed(tester, source);
    expect(find.text('No posts yet. Check back later.'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);

    final response = Completer<FeedPage>();
    source.feedResponse = (_) => response.future;
    await tester.tap(find.text('Refresh'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No posts yet. Check back later.'), findsNothing);

    response.complete(FeedPage(posts: [samplePost(1)], nextPage: null));
    await tester.pumpAndSettle();
    expect(find.text('Post 1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(source.requestedPages, [1, 1]);
  });

  testWidgets('Failed feed displays an error and Retry loads posts', (
    tester,
  ) async {
    final source = FeedTestSource()
      ..feedResponse = (_) async =>
          throw DataSourceException('Feed unavailable');
    await showFeed(tester, source);
    expect(find.text('Feed unavailable'), findsOneWidget);
    expect(find.text('No posts yet. Check back later.'), findsNothing);

    source.feedResponse = (_) async =>
        FeedPage(posts: [samplePost(1)], nextPage: null);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Post 1'), findsOneWidget);
    expect(find.text('Feed unavailable'), findsNothing);
    expect(source.requestedPages, [1, 1]);
  });

  testWidgets(
    'Failed load more preserves posts and recovery removes duplicates',
    (tester) async {
      var failPageTwo = true;
      final source = FeedTestSource()
        ..feedResponse = (page) async {
          if (page == 1) return FeedPage(posts: [samplePost(1)], nextPage: 2);
          if (failPageTwo) throw DataSourceException('Next page unavailable');
          return FeedPage(
            posts: [samplePost(1), samplePost(2)],
            nextPage: null,
          );
        };
      final model = await showFeed(tester, source);
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(find.text('Next page unavailable'), findsOneWidget);
      expect(find.text('Post 1'), findsOneWidget);
      expect(model.nextPage, 2);

      failPageTwo = false;
      await tester.ensureVisible(find.text('Load more'));
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(model.posts.map((post) => post.id).toList(), [1, 2]);
      expect(find.text('Post 1'), findsOneWidget);
      expect(find.text('Post 2'), findsOneWidget);
      expect(find.text('Next page unavailable'), findsNothing);
      expect(find.text('Load more'), findsNothing);
      expect(source.requestedPages, [1, 2, 2]);
    },
  );

  testWidgets('Read more loads full details and Back returns to the feed', (
    tester,
  ) async {
    final response = Completer<FeedPost>();
    final source = FeedTestSource()..postResponse = (_) => response.future;
    await showFeed(tester, source);
    await tester.tap(find.text('Read more'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    const fullBody = 'Full article fetched separately from the feed preview.';
    response.complete(samplePost(1, body: fullBody));
    await tester.pumpAndSettle();
    expect(source.requestedPosts, [1]);
    expect(find.text(fullBody), findsOneWidget);
    expect(tester.widget<Text>(find.text(fullBody)).maxLines, isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Latest public posts'), findsOneWidget);
  });

  testWidgets('Post detail failure shows Retry and then the full post', (
    tester,
  ) async {
    final source = FeedTestSource()
      ..postResponse = (_) async =>
          throw DataSourceException('Post unavailable');
    await showFeed(tester, source);
    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();
    expect(find.text('Post unavailable'), findsOneWidget);

    source.postResponse = (id) async =>
        samplePost(id, body: 'Recovered article');
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Recovered article'), findsOneWidget);
    expect(find.text('Post unavailable'), findsNothing);
    expect(source.requestedPosts, [1, 1]);
  });

  testWidgets('Leaving a loading post safely ignores its late response', (
    tester,
  ) async {
    final response = Completer<FeedPost>();
    final source = FeedTestSource()..postResponse = (_) => response.future;
    await showFeed(tester, source);
    await tester.tap(find.text('Read more'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    response.complete(samplePost(1));
    await tester.pumpAndSettle();
    expect(find.text('Latest public posts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
