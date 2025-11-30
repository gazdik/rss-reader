import 'package:flutter/foundation.dart';

import '../models/rss_models.dart';
import '../services/db_service.dart';
import '../services/rss_service.dart';

class RssStore extends ChangeNotifier {
  final DbService dbService;
  final RssService rssService;

  List<RssFeed> feeds = [];
  List<RssArticle> articles = [];
  Map<String, int> unreadCounts = {};
  String? selectedFeedId;
  RssArticle? selectedArticle;
  bool isLoading = true;

  RssStore({
    required this.dbService,
    required this.rssService,
  });

  Future<void> init() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      feeds = await dbService.getAllFeeds();
      await _loadArticles();
      await _updateUnreadCounts();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadArticles() async {
    if (selectedFeedId != null) {
      articles = await dbService.getArticlesByFeed(selectedFeedId!);
    } else {
      articles = await dbService.getAllArticles();
    }
    notifyListeners();
  }

  Future<void> _updateUnreadCounts() async {
    final counts = <String, int>{};
    for (final feed in feeds) {
      counts[feed.id] = await dbService.getUnreadCountByFeed(feed.id);
    }
    unreadCounts = counts;
    notifyListeners();
  }

  Future<void> selectFeed(String? feedId) async {
    selectedFeedId = feedId;
    selectedArticle = null;
    notifyListeners();
    await _loadArticles();
  }

  Future<void> addFeed(String url) async {
    final parsedFeed = await rssService.fetchFeed(url);
    final title = parsedFeed.title.isNotEmpty ? parsedFeed.title : url;
    final newFeed = RssFeed.create(
      url: url,
      title: title,
      description: parsedFeed.description,
      link: parsedFeed.link,
    );
    await dbService.addFeed(newFeed);
    feeds = [...feeds, newFeed];
    notifyListeners();
    await rssService.refreshFeed(newFeed);
    await _loadArticles();
    await _updateUnreadCounts();
  }

  Future<void> deleteFeed(String feedId) async {
    await dbService.deleteFeed(feedId);
    feeds = feeds.where((f) => f.id != feedId).toList();
    if (selectedFeedId == feedId) {
      selectedFeedId = null;
    }
    selectedArticle = null;
    await _loadArticles();
    await _updateUnreadCounts();
  }

  Future<int> refreshFeedById(String feedId) async {
    final feed = feeds.firstWhere(
      (f) => f.id == feedId,
      orElse: () => throw Exception('Feed not found'),
    );
    final count = await rssService.refreshFeed(feed);
    await _loadArticles();
    await _updateUnreadCounts();
    return count;
  }

  Future<RefreshAllResult> refreshAllFeeds() async {
    final result = await rssService.refreshAllFeeds(feeds);
    await _loadArticles();
    await _updateUnreadCounts();
    return result;
  }

  Future<void> toggleRead(String articleId, bool read) async {
    await dbService.markArticleAsRead(articleId, read);
    articles = [
      for (final a in articles)
        if (a.id == articleId) a.copyWith(read: read) else a,
    ];
    if (selectedArticle != null && selectedArticle!.id == articleId) {
      selectedArticle = selectedArticle!.copyWith(read: read);
    }
    await _updateUnreadCounts();
  }

  Future<void> toggleStar(String articleId) async {
    await dbService.toggleArticleStar(articleId);
    articles = [
      for (final a in articles)
        if (a.id == articleId) a.copyWith(starred: !a.starred) else a,
    ];
    if (selectedArticle != null && selectedArticle!.id == articleId) {
      selectedArticle =
          selectedArticle!.copyWith(starred: !selectedArticle!.starred);
    }
    notifyListeners();
  }

  Future<void> selectArticle(RssArticle article) async {
    selectedArticle = article;
    notifyListeners();
    if (!article.read) {
      await toggleRead(article.id, true);
    }
  }

  int get totalUnread =>
      unreadCounts.values.fold(0, (sum, value) => sum + value);
}
