import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/rss_models.dart';

class ArticleDetailScreen extends StatelessWidget {
  final RssArticle article;

  const ArticleDetailScreen({super.key, required this.article});

  String _cleanContent(String? content, String? description) {
    final value = content ?? description ?? '';
    return value.replaceAll(
      RegExp(
        r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
        multiLine: true,
        caseSensitive: false,
      ),
      '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanContent = _cleanContent(article.content, article.description);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    article.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              if (article.pubDate != null || article.author != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (article.pubDate != null)
                      Text(
                        DateFormat.yMMMd().format(article.pubDate!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (article.pubDate != null && article.author != null)
                      const Text(' • '),
                    if (article.author != null)
                      Text(
                        article.author!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Html(data: cleanContent),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.tryParse(article.link);
              if (uri == null) return;
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Original Article'),
          ),
        ),
      ),
    );
  }
}
