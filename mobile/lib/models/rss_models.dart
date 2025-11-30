import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class RssFeed {
  final String id;
  final String url;
  final String title;
  final String? description;
  final String? link;
  final DateTime? lastFetched;
  final DateTime createdAt;

  RssFeed({
    required this.id,
    required this.url,
    required this.title,
    this.description,
    this.link,
    this.lastFetched,
    required this.createdAt,
  });

  factory RssFeed.create({
    required String url,
    required String title,
    String? description,
    String? link,
  }) {
    final now = DateTime.now();
    return RssFeed(
      id: _uuid.v4(),
      url: url,
      title: title,
      description: description,
      link: link,
      createdAt: now,
      lastFetched: null,
    );
  }

  RssFeed copyWith({
    String? id,
    String? url,
    String? title,
    String? description,
    String? link,
    DateTime? lastFetched,
    DateTime? createdAt,
  }) {
    return RssFeed(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      link: link ?? this.link,
      lastFetched: lastFetched ?? this.lastFetched,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RssFeed.fromMap(Map<String, Object?> map) {
    return RssFeed(
      id: map['id'] as String,
      url: map['url'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      link: map['link'] as String?,
      lastFetched: map['lastFetched'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastFetched'] as int)
          : null,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'description': description,
      'link': link,
      'lastFetched':
          lastFetched != null ? lastFetched!.millisecondsSinceEpoch : null,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

class RssArticle {
  final String id;
  final String feedId;
  final String title;
  final String link;
  final String? description;
  final String? content;
  final DateTime? pubDate;
  final String? author;
  final String guid;
  final String? imageUrl;
  final bool read;
  final bool starred;
  final DateTime createdAt;

  RssArticle({
    required this.id,
    required this.feedId,
    required this.title,
    required this.link,
    this.description,
    this.content,
    this.pubDate,
    this.author,
    required this.guid,
    this.imageUrl,
    required this.read,
    required this.starred,
    required this.createdAt,
  });

  RssArticle copyWith({
    String? id,
    String? feedId,
    String? title,
    String? link,
    String? description,
    String? content,
    DateTime? pubDate,
    String? author,
    String? guid,
    String? imageUrl,
    bool? read,
    bool? starred,
    DateTime? createdAt,
  }) {
    return RssArticle(
      id: id ?? this.id,
      feedId: feedId ?? this.feedId,
      title: title ?? this.title,
      link: link ?? this.link,
      description: description ?? this.description,
      content: content ?? this.content,
      pubDate: pubDate ?? this.pubDate,
      author: author ?? this.author,
      guid: guid ?? this.guid,
      imageUrl: imageUrl ?? this.imageUrl,
      read: read ?? this.read,
      starred: starred ?? this.starred,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RssArticle.fromMap(Map<String, Object?> map) {
    return RssArticle(
      id: map['id'] as String,
      feedId: map['feedId'] as String,
      title: map['title'] as String,
      link: map['link'] as String,
      description: map['description'] as String?,
      content: map['content'] as String?,
      pubDate: map['pubDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['pubDate'] as int)
          : null,
      author: map['author'] as String?,
      guid: map['guid'] as String,
      imageUrl: map['imageUrl'] as String?,
      read: (map['read'] as int) == 1,
      starred: (map['starred'] as int) == 1,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'feedId': feedId,
      'title': title,
      'link': link,
      'description': description,
      'content': content,
      'pubDate': pubDate != null ? pubDate!.millisecondsSinceEpoch : null,
      'author': author,
      'guid': guid,
      'imageUrl': imageUrl,
      'read': read ? 1 : 0,
      'starred': starred ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory RssArticle.create({
    required String feedId,
    required String title,
    required String link,
    String? description,
    String? content,
    DateTime? pubDate,
    String? author,
    required String guid,
    String? imageUrl,
  }) {
    final now = DateTime.now();
    return RssArticle(
      id: _uuid.v4(),
      feedId: feedId,
      title: title,
      link: link,
      description: description,
      content: content,
      pubDate: pubDate,
      author: author,
      guid: guid,
      imageUrl: imageUrl,
      read: false,
      starred: false,
      createdAt: now,
    );
  }
}
