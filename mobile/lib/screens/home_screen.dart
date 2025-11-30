import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/rss_models.dart';
import '../state/rss_store.dart';
import 'article_detail_screen.dart';

enum ArticleFilter { all, unread, starred }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Future<void> _refreshAll(BuildContext context, RssStore store) async {
    if (store.feeds.isEmpty) return;
    final result = await store.refreshAllFeeds();
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
  }

  Future<void> _showAddFeedSheet(BuildContext context, RssStore store) async {
    final controller = TextEditingController();
    bool isAdding = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> submit() async {
                final url = controller.text.trim();
                if (url.isEmpty || isAdding) return;
                setModalState(() => isAdding = true);
                try {
                  await store.addFeed(url);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add feed: $e')),
                  );
                } finally {
                  setModalState(() => isAdding = false);
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add RSS feed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Feed URL',
                      hintText: 'https://example.com/feed.xml',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isAdding ? null : submit,
                      icon: isAdding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: Text(isAdding ? 'Adding...' : 'Add feed'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RssStore>();

    if (store.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pages = [
      _ArticlesTab(store: store),
      _FeedsTab(store: store),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('RSS Reader'),
        actions: [
          IconButton(
            tooltip: 'Refresh all feeds',
            onPressed:
                store.feeds.isEmpty ? null : () => _refreshAll(context, store),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Articles',
          ),
          NavigationDestination(
            icon: Icon(Icons.rss_feed_outlined),
            selectedIcon: Icon(Icons.rss_feed),
            label: 'Feeds',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddFeedSheet(context, store),
              icon: const Icon(Icons.add),
              label: const Text('Add feed'),
            )
          : null,
    );
  }
}

class _FeedsTab extends StatelessWidget {
  final RssStore store;

  const _FeedsTab({required this.store});

  @override
  Widget build(BuildContext context) {
    final feeds = store.feeds;
    final unreadCounts = store.unreadCounts;

    if (feeds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rss_feed,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No feeds yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Add your favorite blogs, news sites, and podcasts to start reading.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: feeds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final feed = feeds[index];
        final unread = unreadCounts[feed.id] ?? 0;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              foregroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.rss_feed),
            ),
            title: Text(
              feed.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: feed.description != null && feed.description!.isNotEmpty
                ? Text(
                    feed.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(
                    feed.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unread > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      unread.toString(),
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh feed',
                  onPressed: () async {
                    final count = await store.refreshFeedById(feed.id);
                    if (!context.mounted) return;
                    if (count > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added $count new articles from ${feed.title}',
                          ),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete feed',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete feed'),
                        content: Text('Delete feed "${feed.title}"?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await store.deleteFeed(feed.id);
                    }
                  },
                ),
              ],
            ),
            onTap: () => store.selectFeed(feed.id),
          ),
        );
      },
    );
  }
}

class _ArticlesTab extends StatefulWidget {
  final RssStore store;

  const _ArticlesTab({required this.store});

  @override
  State<_ArticlesTab> createState() => _ArticlesTabState();
}

class _ArticlesTabState extends State<_ArticlesTab> {
  ArticleFilter _filter = ArticleFilter.all;

  String _stripHtml(String? input) {
    if (input == null) return '';
    return input.replaceAll(
      RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false),
      '',
    );
  }

  List<RssArticle> _applyFilter(List<RssArticle> source) {
    switch (_filter) {
      case ArticleFilter.unread:
        return source.where((a) => !a.read).toList();
      case ArticleFilter.starred:
        return source.where((a) => a.starred).toList();
      case ArticleFilter.all:
      default:
        return source;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final feeds = store.feeds;
    final articles = _applyFilter(store.articles);

    if (articles.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => store.refreshAllFeeds(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Text(
                  'No articles yet.\nAdd some feeds and refresh.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 72,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            scrollDirection: Axis.horizontal,
            children: [
              ChoiceChip(
                label: const Text('All feeds'),
                selected: store.selectedFeedId == null,
                onSelected: (_) => store.selectFeed(null),
              ),
              for (final feed in feeds)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(
                      feed.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: store.selectedFeedId == feed.id,
                    onSelected: (_) => store.selectFeed(feed.id),
                  ),
                ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('All'),
                selected: _filter == ArticleFilter.all,
                onSelected: (_) {
                  setState(() {
                    _filter = ArticleFilter.all;
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Unread'),
                selected: _filter == ArticleFilter.unread,
                onSelected: (_) {
                  setState(() {
                    _filter = ArticleFilter.unread;
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Starred'),
                selected: _filter == ArticleFilter.starred,
                onSelected: (_) {
                  setState(() {
                    _filter = ArticleFilter.starred;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => store.refreshAllFeeds(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final article = articles[index];
                final subtitleParts = <String>[];
                if (article.pubDate != null) {
                  subtitleParts.add(timeago.format(article.pubDate!));
                }
                if (article.author != null && article.author!.isNotEmpty) {
                  subtitleParts.add(article.author!);
                }

                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
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
                        if (article.imageUrl != null &&
                            article.imageUrl!.isNotEmpty)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              article.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (!article.read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin:
                                                const EdgeInsets.only(right: 6),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            article.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (subtitleParts.isNotEmpty)
                                      Text(
                                        subtitleParts.join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    const SizedBox(height: 8),
                                    if (article.description != null &&
                                        article.description!.isNotEmpty)
                                      Text(
                                        _stripHtml(article.description!),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
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
                                      store.toggleRead(
                                        article.id,
                                        !article.read,
                                      );
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
            ),
          ),
        ),
      ],
    );
  }
}
