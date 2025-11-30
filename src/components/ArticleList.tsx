import { RSSArticle } from '@/types';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/Card';
import { Button } from './ui/Button';
import { Star, CheckCircle, Circle } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

interface ArticleListProps {
  articles: RSSArticle[];
  onToggleRead: (articleId: string, read: boolean) => void;
  onToggleStar: (articleId: string) => void;
  selectedArticle: RSSArticle | null;
  onSelectArticle: (article: RSSArticle) => void;
}

export function ArticleList({
  articles,
  onToggleRead,
  onToggleStar,
  selectedArticle,
  onSelectArticle,
}: ArticleListProps) {
  if (articles.length === 0) {
    return (
      <div className="flex-1 flex items-center justify-center text-muted-foreground">
        <div className="text-center">
          <p className="text-lg mb-2">No articles to display</p>
          <p className="text-sm">Add some RSS feeds to get started!</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="p-4 space-y-3">
        {articles.map((article) => (
          <Card
            key={article.id}
            className={`cursor-pointer transition-all hover:shadow-md ${
              selectedArticle?.id === article.id ? 'ring-2 ring-primary' : ''
            } ${article.read ? 'opacity-60' : ''}`}
            onClick={() => onSelectArticle(article)}
          >
            {article.imageUrl && (
              <div className="w-full h-48 overflow-hidden rounded-t-lg">
                <img
                  src={article.imageUrl}
                  alt={article.title}
                  className="w-full h-full object-cover"
                  onError={(e) => {
                    (e.target as HTMLImageElement).style.display = 'none';
                  }}
                />
              </div>
            )}
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between gap-2">
                <CardTitle className="text-lg leading-tight">
                  {article.title}
                </CardTitle>
                <div className="flex gap-1 flex-shrink-0">
                  <Button
                    size="icon"
                    variant="ghost"
                    className="h-8 w-8"
                    onClick={(e) => {
                      e.stopPropagation();
                      onToggleRead(article.id, !article.read);
                    }}
                    title={article.read ? 'Mark as unread' : 'Mark as read'}
                  >
                    {article.read ? (
                      <CheckCircle className="w-4 h-4 text-green-600" />
                    ) : (
                      <Circle className="w-4 h-4" />
                    )}
                  </Button>
                  <Button
                    size="icon"
                    variant="ghost"
                    className="h-8 w-8"
                    onClick={(e) => {
                      e.stopPropagation();
                      onToggleStar(article.id);
                    }}
                    title={article.starred ? 'Unstar' : 'Star'}
                  >
                    <Star
                      className={`w-4 h-4 ${
                        article.starred ? 'fill-yellow-400 text-yellow-400' : ''
                      }`}
                    />
                  </Button>
                </div>
              </div>
              <CardDescription className="flex items-center gap-2 text-xs">
                {article.pubDate && (
                  <span>{formatDistanceToNow(article.pubDate, { addSuffix: true })}</span>
                )}
                {article.author && (
                  <>
                    <span>•</span>
                    <span>{article.author}</span>
                  </>
                )}
              </CardDescription>
            </CardHeader>
            {article.description && (
              <CardContent className="pt-0">
                <p className="text-sm text-muted-foreground line-clamp-2">
                  {article.description.replace(/<[^>]*>/g, '')}
                </p>
              </CardContent>
            )}
          </Card>
        ))}
      </div>
    </div>
  );
}
