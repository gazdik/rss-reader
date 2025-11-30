import { RSSArticle } from '@/types';
import { Button } from './ui/Button';
import { ExternalLink, X } from 'lucide-react';
import { format } from 'date-fns';

interface ArticleDetailProps {
  article: RSSArticle | null;
  onClose: () => void;
}

export function ArticleDetail({ article, onClose }: ArticleDetailProps) {
  if (!article) {
    return (
      <div className="w-96 border-l bg-muted/20 flex items-center justify-center text-muted-foreground">
        <p>Select an article to read</p>
      </div>
    );
  }

  const content = article.content || article.description || '';
  const cleanContent = content.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');

  return (
    <div className="w-96 border-l bg-background flex flex-col h-screen">
      <div className="p-4 border-b flex items-start justify-between gap-2">
        <h2 className="text-lg font-semibold flex-1">{article.title}</h2>
        <Button size="icon" variant="ghost" onClick={onClose}>
          <X className="w-4 h-4" />
        </Button>
      </div>

      <div className="flex-1 overflow-y-auto p-4">
        <div className="space-y-4">
          {article.pubDate && (
            <div className="text-sm text-muted-foreground">
              {format(article.pubDate, 'PPP')}
            </div>
          )}

          {article.author && (
            <div className="text-sm text-muted-foreground">
              By {article.author}
            </div>
          )}

          <div
            className="prose prose-sm max-w-none dark:prose-invert"
            dangerouslySetInnerHTML={{ __html: cleanContent }}
          />
        </div>
      </div>

      <div className="p-4 border-t">
        <Button
          className="w-full"
          onClick={() => window.open(article.link, '_blank')}
        >
          <ExternalLink className="w-4 h-4 mr-2" />
          Open Original Article
        </Button>
      </div>
    </div>
  );
}
