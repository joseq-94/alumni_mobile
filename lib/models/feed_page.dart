import 'feed_post.dart';

// One batch of posts. A null nextPage means there are no more pages to request.
class FeedPage {
  final List<FeedPost> posts;
  final int? nextPage;
  FeedPage({required this.posts, this.nextPage});
}
