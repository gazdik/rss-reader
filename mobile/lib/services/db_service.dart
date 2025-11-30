import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/rss_models.dart';

class DbService {
  DbService._internal();

  static final DbService instance = DbService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'rss_reader.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE feeds('
      'id TEXT PRIMARY KEY,'
      'url TEXT NOT NULL,'
      'title TEXT NOT NULL,'
      'description TEXT,'
      'link TEXT,'
      'lastFetched INTEGER,'
      'createdAt INTEGER NOT NULL'
      ')',
    );
    await db.execute(
      'CREATE TABLE articles('
      'id TEXT PRIMARY KEY,'
      'feedId TEXT NOT NULL,'
      'title TEXT NOT NULL,'
      'link TEXT NOT NULL,'
      'description TEXT,'
      'content TEXT,'
      'pubDate INTEGER,'
      'author TEXT,'
      'guid TEXT NOT NULL,'
      'imageUrl TEXT,'
      'read INTEGER NOT NULL,'
      'starred INTEGER NOT NULL,'
      'createdAt INTEGER NOT NULL,'
      'FOREIGN KEY(feedId) REFERENCES feeds(id)'
      ')',
    );
    await db.execute(
      'CREATE INDEX idx_articles_feed ON articles(feedId)',
    );
    await db.execute(
      'CREATE INDEX idx_articles_date ON articles(pubDate)',
    );
    await db.execute(
      'CREATE INDEX idx_articles_read ON articles(read)',
    );
    await db.execute(
      'CREATE INDEX idx_articles_starred ON articles(starred)',
    );
  }

  Future<void> addFeed(RssFeed feed) async {
    final db = await database;
    await db.insert(
      'feeds',
      feed.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateFeed(RssFeed feed) async {
    final db = await database;
    await db.update(
      'feeds',
      feed.toMap(),
      where: 'id = ?',
      whereArgs: [feed.id],
    );
  }

  Future<void> deleteFeed(String id) async {
    final db = await database;
    await db.delete(
      'articles',
      where: 'feedId = ?',
      whereArgs: [id],
    );
    await db.delete(
      'feeds',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<RssFeed?> getFeed(String id) async {
    final db = await database;
    final maps = await db.query(
      'feeds',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RssFeed.fromMap(maps.first);
  }

  Future<List<RssFeed>> getAllFeeds() async {
    final db = await database;
    final maps = await db.query(
      'feeds',
      orderBy: 'createdAt ASC',
    );
    return maps.map((m) => RssFeed.fromMap(m)).toList();
  }

  Future<void> addArticle(RssArticle article) async {
    final db = await database;
    await db.insert(
      'articles',
      article.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addArticles(List<RssArticle> articles) async {
    if (articles.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final article in articles) {
      batch.insert(
        'articles',
        article.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateArticle(RssArticle article) async {
    final db = await database;
    await db.update(
      'articles',
      article.toMap(),
      where: 'id = ?',
      whereArgs: [article.id],
    );
  }

  Future<void> deleteArticle(String id) async {
    final db = await database;
    await db.delete(
      'articles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<RssArticle?> getArticle(String id) async {
    final db = await database;
    final maps = await db.query(
      'articles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RssArticle.fromMap(maps.first);
  }

  Future<List<RssArticle>> getArticlesByFeed(String feedId) async {
    final db = await database;
    final maps = await db.query(
      'articles',
      where: 'feedId = ?',
      whereArgs: [feedId],
      orderBy: 'pubDate DESC',
    );
    return maps.map((m) => RssArticle.fromMap(m)).toList();
  }

  Future<List<RssArticle>> getAllArticles() async {
    final db = await database;
    final maps = await db.query(
      'articles',
      orderBy: 'pubDate DESC',
    );
    return maps.map((m) => RssArticle.fromMap(m)).toList();
  }

  Future<List<RssArticle>> getUnreadArticles() async {
    final db = await database;
    final maps = await db.query(
      'articles',
      where: 'read = ?',
      whereArgs: [0],
      orderBy: 'pubDate DESC',
    );
    return maps.map((m) => RssArticle.fromMap(m)).toList();
  }

  Future<List<RssArticle>> getStarredArticles() async {
    final db = await database;
    final maps = await db.query(
      'articles',
      where: 'starred = ?',
      whereArgs: [1],
      orderBy: 'pubDate DESC',
    );
    return maps.map((m) => RssArticle.fromMap(m)).toList();
  }

  Future<void> markArticleAsRead(String id, bool read) async {
    final db = await database;
    await db.update(
      'articles',
      {'read': read ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleArticleStar(String id) async {
    final article = await getArticle(id);
    if (article == null) return;
    final db = await database;
    await db.update(
      'articles',
      {'starred': article.starred ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getUnreadCountByFeed(String feedId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM articles WHERE feedId = ? AND read = 0',
      [feedId],
    );
    final value = result.first['count'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
