import 'package:flutter/material.dart';
import '../../models/feed_post.dart';

class FeedCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onOpen;
  const FeedCard({super.key, required this.post, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${post.authorName} · ${MaterialLocalizations.of(context).formatMediumDate(post.createdAt.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(post.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(post.body, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            TextButton(onPressed: onOpen, child: const Text('Read more')),
          ],
        ),
      ),
    );
  }
}
