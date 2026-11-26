import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alumni_model.dart';
import 'post_detail_page.dart';
import 'widgets/feed_card.dart';
import 'widgets/status_message.dart';

// Display shared feed state; refresh and load-more actions are handled by AlumniModel.
class FeedPageView extends StatelessWidget {
  const FeedPageView({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<AlumniModel>(
      builder: (context, model, child) {
        return RefreshIndicator(
          onRefresh: model.refreshFeed,
          child: ListView.builder(
            key: const PageStorageKey('feed'),
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            // The extra two rows are the heading/status area and the loading/load-more footer.
            itemCount: model.posts.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Latest public posts',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton.icon(
                          onPressed: model.loadingFeed
                              ? null
                              : model.refreshFeed,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    if (model.feedError != null)
                      StatusMessage(
                        message: model.feedError!,
                        onRetry: model.refreshFeed,
                      ),
                    if (model.posts.isEmpty &&
                        !model.loadingFeed &&
                        model.feedError == null)
                      const StatusMessage(
                        message: 'No posts yet. Check back later.',
                      ),
                  ],
                );
              }
              if (index == model.posts.length + 1) {
                if (model.loadingFeed) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (model.nextPage != null) {
                  return OutlinedButton(
                    onPressed: model.loadMore,
                    child: const Text('Load more'),
                  );
                }
                return const SizedBox(height: 16);
              }
              final post = model.posts[index - 1];
              return FeedCard(
                post: post,
                onOpen: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => PostDetailPage(postId: post.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
