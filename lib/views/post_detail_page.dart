import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alumni_model.dart';
import '../models/feed_post.dart';
import '../services/alumni_datasource.dart';
import 'widgets/status_message.dart';

// Load a single post by ID, keeping its loading/error state only on this screen.
class PostDetailPage extends StatefulWidget {
  final int postId;
  const PostDetailPage({super.key, required this.postId});
  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  FeedPost? _post;
  String? _error;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final model = Provider.of<AlumniModel>(context, listen: false);
    try {
      final post = await model.dataSource.readPost(widget.postId);
      // The user may have left this screen while the request was running.
      if (!mounted) return;
      setState(() => _post = post);
    } catch (error) {
      if (!mounted) return;
      if (error is DataSourceException && error.sessionExpired) {
        await model.signOut();
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      setState(
        () => _error = error is DataSourceException
            ? error.message
            : 'Unable to load this post.',
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: StatusMessage(message: _error!, onRetry: _load),
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    _post!.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_post!.authorName} · ${MaterialLocalizations.of(context).formatMediumDate(_post!.createdAt.toLocal())}',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _post!.body,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
      ),
    );
  }
}
