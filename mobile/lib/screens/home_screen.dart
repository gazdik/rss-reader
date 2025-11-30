import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/rss_models.dart';
import '../state/rss_store.dart';
import 'article_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RssStore>(
      builder: (context, store, _) {
        if (store.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('RSS Reader'),
          ),
          body: Row(
            children: [
              SizedBox(
                width: 280,
                child: _FeedListPane(store: store),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _ArticleListPane(store: store),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeedListPane extends StatefulWidget {
  final RssStore store;

  const _FeedListPane({required this.store});

  @override
  State<_FeedListPane> createState() => _FeedListPaneState();
}

class _FeedListPaneState extends State<_FeedListPane> {
  final TextEditingController _controller = TextEditingController();
  bool _isAdding = false;
  bool _isRefreshingAll = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addFeed() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _isAdding = true;
    });
    try {
      await widget.store.addFeed(url);
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add feed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isAdding = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    setState(() {
      _isRefreshingAll = true;
    });
    try {
      final result = await widget.store.refreshAllFeeds();
      if (!mounted) return;
      final message = result.total > 0
          ? 'Added ${result.total} new articles'
          : 'No new articles';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      if (result.errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Some feeds failed to refresh: ${result.errors.join(', ')}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing feeds: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isRefreshingAll = false;
      });
    }
  }

  Future<void> _refreshFeed(RssFeed feed) async {
    try {
      final count = await widget.store.refreshFeedById(feed.id);
      if (!mounted) return;
      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $count new articles from ${feed.title}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing feed: $e')),
      );
    }
  }

  Future<void> _deleteFeed(RssFeed feed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete feed'),
          content: Text('Delete feed "${feed.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    await widget.store.deleteFeed(feed.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final feeds = store.feeds;
    final selectedFeedId = store.selectedFeedId;
    final unreadCounts = store.unreadCounts;
    final totalUnread = store.totalUnread;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.rss_feed),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'RSS Feeds',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: _isRefreshingAll
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed:
                    _isRefreshingAll || feeds.isEmpty ? null : _refreshAll,
                tooltip: 'Refresh all feeds',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Add RSS feed URL',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isAdding,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isAdding ? null : _addFeed,
                child: _isAdding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: feeds.isEmpty
                ? const Center(
                    child: Text('No feeds yet. Add your first RSS feed above!'),
                  )
                : ListView(
                    children: [
                      ListTile(
                        selected: selectedFeedId == null,
                        title: const Text('All Articles'),
                        trailing: Text(totalUnread.toString()),
                        onTap: () => store.selectFeed(null),
                      ),
                      const Divider(),
                      for (final feed in feeds)
                        ListTile(
                          selected: selectedFeedId == feed.id,
                          title: Text(
                            feed.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if ((unreadCounts[feed.id] ?? 0) > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (unreadCounts[feed.id] ?? 0).toString(),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 18),
                                tooltip: 'Refresh feed',
                                onPressed: () => _refreshFeed(feed),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                tooltip: 'Delete feed',
                                onPressed: () => _deleteFeed(feed),
                              ),
                            ],
                          ),
                          onTap: () => store.selectFeed(feed.id),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ArticleListPane extends StatelessWidget {
  final RssStore store;

  const _ArticleListPane({required this.store});

  String _stripHtml(String? input) {
    if (input == null) return '';
    return input.replaceAll(
      RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false),
      '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final articles = store.articles;
    final selectedArticle = store.selectedArticle;

    if (articles.isEmpty) {
      return const Center(
        child: Text('No articles to display. Add some RSS feeds to get started!'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        final isSelected = selectedArticle?.id == article.id;
        final subtitleParts = <String>[];
        if (article.pubDate != null) {
          subtitleParts.add(timeago.format(article.pubDate!));
        }
        if (article.author != null && article.author!.isNotEmpty) {
          subtitleParts.add(article.author!);
        }

        return Card(
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            side: isSelected
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : BorderSide.none,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () async {
              await store.selectArticle(article);
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ArticleDetailScreen(article: article),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: Image.network(
                      article.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            if (subtitleParts.isNotEmpty)
                              Text(
                                subtitleParts.join(' • '),
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            const SizedBox(height: 6),
                            if (article.description != null &&
                                article.description!.isNotEmpty)
                              Text(
                                _stripHtml(article.description!),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(
                              article.read
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: article.read
                                  ? Colors.green
                                  : Theme.of(context)
                                      .iconTheme
                                      .color,
                            ),
                            tooltip: article.read
                                ? 'Mark as unread'
                                : 'Mark as read',
                            onPressed: () {
                              store.toggleRead(article.id, !article.read);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              article.starred
                                  ? Icons.star
                                  : Icons.star_border,
                              color: article.starred
                                  ? Colors.amber
                                  : Theme.of(context)
                                      .iconTheme
                                      .color,
                            ),
                            tooltip:
                                article.starred ? 'Unstar' : 'Star',
                            onPressed: () {
                              store.toggleStar(article.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
