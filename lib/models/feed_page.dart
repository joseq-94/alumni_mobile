import 'feed_post.dart';

class FeedPage {
  final List<FeedPost> posts;
  final int? nextPage;
  FeedPage({required this.posts, this.nextPage});
}
