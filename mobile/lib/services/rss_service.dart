import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

import '../models/rss_models.dart';
import 'db_service.dart';

class ParsedFeed {
  final String title;
  final String? description;
  final String? link;
  final List<ParsedItem> items;

  ParsedFeed({
    required this.title,
    this.description,
    this.link,
    required this.items,
  });
}

class ParsedItem {
  final String title;
  final String link;
  final String? description;
  final String? content;
  final String? pubDate;
  final String? author;
  final String? guid;
  final String? imageUrl;

  ParsedItem({
    required this.title,
    required this.link,
    this.description,
    this.content,
    this.pubDate,
    this.author,
    this.guid,
    this.imageUrl,
  });
}

class RefreshAllResult {
  final int total;
  final List<String> errors;

  RefreshAllResult({
    required this.total,
    required this.errors,
  });
}

class RssService {
  final DbService dbService;

  RssService({required this.dbService});

  Future<ParsedFeed> fetchFeed(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('HTTP error ${response.statusCode}');
    }

    final document = xml.XmlDocument.parse(response.body);

    if (document.findAllElements('rss').isNotEmpty ||
        document.findAllElements('channel').isNotEmpty) {
      return _parseRss(document);
    } else if (document.findAllElements('feed').isNotEmpty) {
      return _parseAtom(document);
    } else {
      throw Exception('Unknown feed format');
    }
  }

  ParsedFeed _parseRss(xml.XmlDocument doc) {
    final channel = doc.findAllElements('channel').firstOrNull;
    if (channel == null) {
      throw Exception('Invalid RSS feed: no channel element found');
    }

    final title = _getText(channel.findElements('title').firstOrNull);
    final description =
        _getText(channel.findElements('description').firstOrNull);
    final link = _getText(channel.findElements('link').firstOrNull);

    final items = <ParsedItem>[];
    for (final item in channel.findElements('item')) {
      final parsedItem = ParsedItem(
        title: _getText(item.findElements('title').firstOrNull),
        link: _getText(item.findElements('link').firstOrNull),
        description: _getText(item.findElements('description').firstOrNull),
        content: _getText(_firstOf(item, ['content:encoded', 'content'])),
        pubDate: _getText(item.findElements('pubDate').firstOrNull),
        author:
            _getText(_firstOf(item, ['author', 'dc:creator'])),
        guid: _getText(item.findElements('guid').firstOrNull) ??
            _getText(item.findElements('link').firstOrNull),
        imageUrl: _extractImageUrl(item),
      );
      items.add(parsedItem);
    }

    return ParsedFeed(
      title: title,
      description: description,
      link: link,
      items: items,
    );
  }

  ParsedFeed _parseAtom(xml.XmlDocument doc) {
    final feed = doc.findAllElements('feed').firstOrNull;
    if (feed == null) {
      throw Exception('Invalid Atom feed: no feed element found');
    }

    final title = _getText(feed.findElements('title').firstOrNull);
    final subtitle = _getText(feed.findElements('subtitle').firstOrNull);
    final linkElements = feed.findElements('link');
    xml.XmlElement? linkElement;
    for (final el in linkElements) {
      if (el.getAttribute('rel') == 'alternate') {
        linkElement = el;
        break;
      }
    }
    linkElement ??= linkElements.firstOrNull;
    final link = linkElement?.getAttribute('href') ?? '';

    final items = <ParsedItem>[];
    for (final entry in feed.findElements('entry')) {
      final entryLinks = entry.findElements('link');
      xml.XmlElement? entryLink;
      for (final el in entryLinks) {
        if (el.getAttribute('rel') == 'alternate') {
          entryLink = el;
          break;
        }
      }
      entryLink ??= entryLinks.firstOrNull;

      final authorElement = entry
          .findAllElements('author')
          .expand((a) => a.findAllElements('name'))
          .firstOrNull;

      final parsedItem = ParsedItem(
        title: _getText(entry.findElements('title').firstOrNull),
        link: entryLink?.getAttribute('href') ?? '',
        description: _getText(entry.findElements('summary').firstOrNull),
        content: _getText(entry.findElements('content').firstOrNull),
        pubDate:
            _getText(_firstOf(entry, ['published', 'updated'])),
        author: _getText(authorElement),
        guid: _getText(entry.findElements('id').firstOrNull) ??
            (entryLink?.getAttribute('href') ?? ''),
        imageUrl: _extractImageUrl(entry),
      );
      items.add(parsedItem);
    }

    return ParsedFeed(
      title: title,
      description: subtitle,
      link: link,
      items: items,
    );
  }

  xml.XmlElement? _firstOf(xml.XmlElement parent, List<String> names) {
    for (final name in names) {
      final parts = name.split(':');
      final localName = parts.last;
      final elements = parent.findAllElements(localName);
      if (elements.isNotEmpty) {
        return elements.first;
      }
    }
    return null;
  }

  String _getText(xml.XmlElement? element) {
    if (element == null) return '';
    return element.text.trim();
  }

  xml.XmlElement? _findElementWithLocalName(
    xml.XmlElement parent,
    String name,
  ) {
    for (final element in parent.descendants.whereType<xml.XmlElement>()) {
      if (element.name.local == name) {
        return element;
      }
    }
    return null;
  }

  String? _extractImageUrl(xml.XmlElement item) {
    final mediaContent = _findElementWithLocalName(item, 'content');
    if (mediaContent != null) {
      final url = mediaContent.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }

    final mediaThumbnail = _findElementWithLocalName(item, 'thumbnail');
    if (mediaThumbnail != null) {
      final url = mediaThumbnail.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }

    final enclosure = item.findElements('enclosure').firstOrNull;
    if (enclosure != null) {
      final type = enclosure.getAttribute('type') ?? '';
      if (type.startsWith('image/')) {
        final url = enclosure.getAttribute('url');
        if (url != null && url.isNotEmpty) return url;
      }
    }

    final descriptionEl = item.findElements('description').firstOrNull;
    final contentEl =
        _firstOf(item, ['content:encoded', 'content']) ?? descriptionEl;
    final htmlContent = contentEl != null ? contentEl.text : '';
    if (htmlContent.isNotEmpty) {
      final match = RegExp(
        r'<img[^>]+src=["\']([^"\']+)["\']',
        caseSensitive: false,
      ).firstMatch(htmlContent);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }

    return null;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  Future<int> refreshFeed(RssFeed feed) async {
    final parsedFeed = await fetchFeed(feed.url);

    final updatedFeed = feed.copyWith(
      title: parsedFeed.title.isNotEmpty ? parsedFeed.title : feed.title,
      description: parsedFeed.description ?? feed.description,
      link: parsedFeed.link ?? feed.link,
      lastFetched: DateTime.now(),
    );
    await dbService.updateFeed(updatedFeed);

    final existingArticles = await dbService.getArticlesByFeed(feed.id);
    final existingGuids = existingArticles.map((a) => a.guid).toSet();

    final newArticles = <RssArticle>[];
    for (final item in parsedFeed.items) {
      final key = item.guid ?? item.link;
      if (key.isEmpty || existingGuids.contains(key)) {
        continue;
      }
      final article = RssArticle.create(
        feedId: feed.id,
        title: item.title,
        link: item.link,
        description: item.description,
        content: item.content,
        pubDate: _parseDate(item.pubDate),
        author: item.author,
        guid: key,
        imageUrl: item.imageUrl,
      );
      newArticles.add(article);
    }

    if (newArticles.isNotEmpty) {
      await dbService.addArticles(newArticles);
    }

    return newArticles.length;
  }

  Future<RefreshAllResult> refreshAllFeeds(List<RssFeed> feeds) async {
    var total = 0;
    final errors = <String>[];

    for (final feed in feeds) {
      try {
        final count = await refreshFeed(feed);
        total += count;
      } catch (e) {
        errors.add('${feed.title}: $e');
      }
    }

    return RefreshAllResult(total: total, errors: errors);
  }
}

extension _FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
